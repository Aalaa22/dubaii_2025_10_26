import 'package:advertising_app/data/model/favorites_response_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/repository/favorites_repository.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/utils/category_mapper.dart';

mixin FavoritesHelper<T extends StatefulWidget> on State<T> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FavoritesRepository _favoritesRepository = FavoritesRepository(ApiService());
  
  bool _isAddingToFavorites = false;
  Set<int> _favoriteAdIds = <int>{};

  bool get isAddingToFavorites => _isAddingToFavorites;
  
  /// Check if an ad is in favorites
  bool isAdInFavorites(int adId) {
    return _favoriteAdIds.contains(adId);
  }

  /// Load user's favorite ad IDs from storage or API
  Future<void> loadFavoriteIds() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        // Here you could load from API or local storage
        // For now, we'll use a simple approach
        final favoriteIds = await _storage.read(key: 'favorite_ids_$userId');
        if (favoriteIds != null) {
          final ids = favoriteIds.split(',').map((id) => int.tryParse(id) ?? 0).where((id) => id > 0).toSet();
          setState(() {
            _favoriteAdIds = ids;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading favorite IDs: $e');
    }
  }

  /// Save favorite ad IDs to storage
  Future<void> _saveFavoriteIds() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        final idsString = _favoriteAdIds.join(',');
        await _storage.write(key: 'favorite_ids_$userId', value: idsString);
      }
    } catch (e) {
      debugPrint('Error saving favorite IDs: $e');
    }
  }

  /// Handle add to favorite with authentication check
  Future<void> handleAddToFavorite(FavoriteItemInterface item, {VoidCallback? onSuccess}) async {
    // Check if user is authenticated
    final userId = await _storage.read(key: 'user_id');
    
    if (userId == null) {
      // Show guest user warning dialog
      _showGuestWarningDialog();
      return;
    }

    // Show confirmation dialog for authenticated users
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).add_to_favorite, style: const TextStyle(color: KTextColor, fontSize: 16)),
        content: Text(S.of(context).confirm_add_to_favorite, style: const TextStyle(color: KTextColor, fontSize: 18)),
        actions: [
          TextButton(
            child: Text(S.of(context).cancel, style: const TextStyle(color: KTextColor, fontSize: 20)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: _isAddingToFavorites 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(S.of(context).yes, style: const TextStyle(color: KTextColor, fontSize: 20)),
            onPressed: _isAddingToFavorites ? null : () async {
              await _addToFavorites(item, onSuccess: onSuccess);
            },
          ),
        ],
      ),
    );
  }

  /// Add item to favorites
  Future<void> _addToFavorites(FavoriteItemInterface item, {VoidCallback? onSuccess}) async {
    setState(() {
      _isAddingToFavorites = true;
    });

    try {
      // Get ad_id and category from the item
      int adId;
      String categorySlug;

      // Check if the item is a FavoriteItem (from favorites screen)
      if (item is FavoriteItem) {
        final favoriteItem = item as FavoriteItem;
        adId = favoriteItem.ad.id;
        categorySlug = favoriteItem.ad.addCategory;
      } else {
        // For other item types, try to get id from the interface
        final itemId = item.id;
        if (itemId is int) {
          adId = itemId;
        } else if (itemId is String) {
          adId = int.tryParse(itemId) ?? 0;
        } else {
          adId = 0;
        }
        
        categorySlug = item.addCategory;
      }

      if (adId == 0) {
        throw Exception('Invalid ad ID');
      }

      // Get user ID from storage
      final userIdString = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdString ?? '0') ?? 0;
      
      if (userId == 0) {
        throw Exception('User ID not found');
      }

      // Call the API to add to favorites
      await _favoritesRepository.addToFavorites(
        adId: adId,
        categorySlug: categorySlug,
        userId: userId,
      );

      // Add to local favorites set
      setState(() {
        _favoriteAdIds.add(adId);
      });
      
      // Save to storage
      await _saveFavoriteIds();

      Navigator.pop(context); // Close dialog
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).added_to_favorite),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Call success callback
      onSuccess?.call();

    } catch (e) {
      Navigator.pop(context); // Close dialog
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to favorites: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isAddingToFavorites = false;
      });
    }
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(int adId) async {
    try {
      // حاول الحذف من السيرفر أولاً حتى لو لم تتوفر الفئة محليًا
      final userIdStr = await _storage.read(key: 'user_id');
      final token = await _storage.read(key: 'auth_token');
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      if (userId != 0) {
        try {
          // اجلب قائمة المفضلة لاستخراج favoriteId أو الفئة من السيرفر
          final favorites = await _favoritesRepository.getFavorites(userId: userId);
          FavoriteItem? matched;
          for (final categoryList in favorites.data.getAllItemsByCategory()) {
            for (final fav in categoryList) {
              if (fav.ad.id == adId) {
                matched = fav;
                break;
              }
            }
            if (matched != null) break;
          }

          if (matched != null) {
            // إذا توفر favoriteId من السيرفر، استخدم مسار الإزالة المباشر
            await _favoritesRepository.removeFromFavorites(
              favoriteId: matched.favoriteId,
              token: token,
            );
          } else {
            // إذا لم نجد العنصر في السيرفر، اترك الحذف محليًا مع تسجيل
            debugPrint('Favorite item for adId $adId not found on server list; performing local removal.');
          }
        } catch (e) {
          // في حال فشل الجلب أو الحذف من السيرفر، نكمل بالحذف المحلي
          debugPrint('Server deletion attempt failed for adId $adId: $e');
        }
      }

      // حدّث الحالة محليًا دومًا لضمان تزامن الواجهة
      setState(() {
        _favoriteAdIds.remove(adId);
      });
      await _saveFavoriteIds();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }

  /// Remove from favorites using the full item (preferred: performs server deletion then local update)
  Future<bool> removeFromFavoritesItem(FavoriteItemInterface item, {bool showFeedback = true}) async {
    final ok = await _removeFavoriteOnServer(item);
    if (!ok) {
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل حذف الإعلان من المفضلة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    final adId = _getAdId(item);
    setState(() {
      _favoriteAdIds.remove(adId);
    });
    await _saveFavoriteIds();

    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الإعلان من المفضلة'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return true;
  }

  /// Build robust candidate slugs for deletion similar to repository logic
  List<String> _buildDeleteSlugCandidates(String? category) {
    final original = (category ?? '').trim();
    final normalized = CategoryMapper.toApiFormat(original);

    final slug = normalized.trim().toLowerCase();
    final orig = original.trim().toLowerCase();

    final set = <String>{};
    if (slug.isNotEmpty) set.add(slug);
    if (orig.isNotEmpty) set.add(orig);

    final hyphen = slug.replaceAll('_', '-');
    if (hyphen.isNotEmpty) set.add(hyphen);

    final display = CategoryMapper.toDisplayFormat(slug);
    if (display.isNotEmpty) {
      set.add(display);
      set.add(display.toLowerCase());
    }
    final spacedLower = slug.replaceAll('_', ' ');
    if (spacedLower.isNotEmpty) set.add(spacedLower);

    switch (slug) {
      case 'car_sales':
      case 'carsales':
        set.addAll({'cars', 'car-sales', 'carsales', 'car_sales', 'Cars Sales', 'car sales'});
        break;
      case 'jobs':
      case 'jop':
        set.addAll({'job', 'jobs', 'Jobs', 'Jop'});
        break;
      case 'car_services':
        set.addAll({'car-services', 'car_services', 'Car Services', 'car services'});
        break;
      case 'real_estate':
        set.addAll({'real-estate', 'real_estate', 'Real State', 'real state'});
        break;
      case 'car_rent':
        set.addAll({'car-rent', 'car_rent', 'Car Rent', 'car rent'});
        break;
      case 'other_services':
        set.addAll({'other-services', 'other_services', 'Other Services', 'other services'});
        break;
      case 'restaurant':
        set.addAll({'restaurant', 'Restaurant'});
        break;
      default:
        set.add(orig.replaceAll('_', '-'));
        break;
    }

    final ordered = <String>[];
    void addOrdered(String s) {
      if (s.isEmpty) return;
      if (!ordered.contains(s)) ordered.add(s);
    }
    addOrdered(slug);
    addOrdered(orig);
    addOrdered(hyphen);
    for (final s in set) {
      addOrdered(s);
    }
    return ordered;
  }

  /// Remove the item from favorites on the server using DELETE /api/favorites/{userId}
  Future<bool> _removeFavoriteOnServer(FavoriteItemInterface item) async {
    try {
      // Resolve adId and category from item
      final adId = _getAdId(item);
      if (adId == 0) throw Exception('Invalid ad ID');

      String? rawCategory;
      if (item is FavoriteItem) {
        rawCategory = item.ad.addCategory;
      } else {
        rawCategory = item.addCategory ?? item.category;
      }

      // Load auth data
      final userIdStr = await _storage.read(key: 'user_id');
      final token = await _storage.read(key: 'auth_token');
      final userId = int.tryParse(userIdStr ?? '') ?? 0;
      if (userId == 0) throw Exception('User ID not found');

      // Try multiple slug candidates to maximize success
      final candidates = _buildDeleteSlugCandidates(rawCategory);

      dynamic lastError;
      for (final slug in candidates) {
        try {
          await _favoritesRepository.removeFromFavoritesByUser(
            userId: userId,
            adId: adId,
            categorySlug: slug,
            token: token,
          );
          return true;
        } catch (e) {
          lastError = e;
          continue;
        }
      }

      debugPrint('Failed to remove from server with all candidates. Last error: $lastError');
      return false;
    } catch (e) {
      debugPrint('Server removal error: $e');
      return false;
    }
  }

  /// Build the favorite icon based on current state
  Widget buildFavoriteIcon(FavoriteItemInterface item, {VoidCallback? onAddToFavorite, VoidCallback? onRemoveFromFavorite}) {
    final adId = _getAdId(item);
    final isFavorite = isAdInFavorites(adId);
    
    if (isFavorite) {
      // Show red filled heart for favorited items
      // If a removal callback is provided, show a confirmation dialog first
      if (onRemoveFromFavorite != null) {
        return IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text(
                    'Remove from Favorites',
                    style: TextStyle(color: KTextColor, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  content: const Text(
                    'Are you sure you want to remove this ad from favorites?',
                    style: TextStyle(color: KTextColor, fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                      style: TextButton.styleFrom(foregroundColor: KTextColor),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: KTextColor),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Remove'),
                    ),
                  ],
                );
              },
            );

            if (confirmed == true) {
              // حذف من الخادم أولًا
              final ok = await _removeFavoriteOnServer(item);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('فشل حذف الإعلان من المفضلة'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // ثم تحديث الحالة محليًا لتغيير لون القلب فورًا
              setState(() {
                _favoriteAdIds.remove(adId);
              });
              await _saveFavoriteIds();

              // إشعار نجاح بسيط
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف الإعلان من المفضلة'),
                  backgroundColor: Colors.green,
                ),
              );

              // استدعاء كولباك الشاشة (إن لزم) بدون تنفيذ حذف إضافي
              onRemoveFromFavorite();
            }
          },
        );
      }
      // No callback provided: perform local removal without dialog
      return IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () async {
          // نفّذ حذف السيرفر ثم حدث الحالة محليًا باستخدام الدالة المعتمدة على الكائن
          await removeFromFavoritesItem(item);
        },
      );
    } else if (onAddToFavorite != null) {
      // Show empty heart for non-favorited items that can be added
      return IconButton( 
        icon: const Icon(Icons.favorite_border, color: Color.fromRGBO(245, 247, 250, 1)),
        onPressed: () => handleAddToFavorite(item, onSuccess: onAddToFavorite),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Get ad ID from item
  int _getAdId(FavoriteItemInterface item) {
    if (item is FavoriteItem) {
      return (item as FavoriteItem).ad.id;
    } else {
      final itemId = item.id;
      if (itemId is int) {
        return itemId;
      } else if (itemId is String) {
        return int.tryParse(itemId) ?? 0;
      } else {
        return 0;
      }
    }
  }

  void _showGuestWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الدخول مطلوب', style: TextStyle(color: KTextColor, fontSize: 18)),
        content: const Text('يجب تسجيل الدخول أولاً لإضافة الإعلانات إلى المفضلة', style: TextStyle(color: KTextColor, fontSize: 16)),
        actions: [
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: KTextColor, fontSize: 16)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.blue, fontSize: 16)),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              // Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}