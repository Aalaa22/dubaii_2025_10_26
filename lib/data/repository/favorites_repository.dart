import 'package:advertising_app/data/model/favorites_response_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/utils/category_mapper.dart';

class FavoritesRepository {
  final ApiService _apiService;

  FavoritesRepository(this._apiService);

  /// Fetch all favorites from the API using user ID
  Future<FavoritesResponse> getFavorites({required int userId}) async {
    try {
      print('🔵 Fetching favorites for user ID: $userId');
      print('🔵 Making API call to: /api/favorites/$userId');
      
      final response = await _apiService.get('/api/favorites/$userId');
      
      print('🔵 Raw API response type: ${response.runtimeType}');
      print('🔵 Raw API response content: $response');
      
      if (response == null) {
        print('🔴 API response is null - returning empty response');
        return FavoritesResponse(
          status: false,
          data: FavoritesData(),
        );
      }
      
      if (response is List) {
        print('🟡 API response is a List with ${response.length} items');
        print('🟡 Processing list response...');
        final result = _organizeFavoritesFromList(response);
        print('🟡 List processing completed');
        return result;
      }
      
      if (response is Map<String, dynamic>) {
        print('🟢 API response is a Map - parsing with fromJson');
        final result = FavoritesResponse.fromJson(response);
        print('🟢 Map parsing completed');
        return result;
      }
      
      print('🔴 Unexpected response type: ${response.runtimeType}');
      return FavoritesResponse(
        status: false,
        data: FavoritesData(),
      );
    } catch (e) {
      print('🔴 Error in getFavorites: $e');
      print('🔴 Error type: ${e.runtimeType}');
      return FavoritesResponse(
        status: false,
        data: FavoritesData(),
      );
    }
  }

  /// Create an empty favorites response
  FavoritesResponse _createEmptyFavoritesResponse() {
    return FavoritesResponse(
      status: true,
      data: FavoritesData(
        restaurant: [],
        carServices: [],
        carSales: [],
        realEstate: [],
        electronics: [],
        jobs: [],
        carRent: [],
        otherServices: [],
      ),
    );
  }

  /// Organize favorites list by category
  FavoritesResponse _organizeFavoritesFromList(List<dynamic> favoritesList) {
    // Create empty lists for each category
    List<FavoriteItem> restaurant = [];
    List<FavoriteItem> carServices = [];
    List<FavoriteItem> carSales = [];
    List<FavoriteItem> realEstate = [];
    List<FavoriteItem> electronics = [];
    List<FavoriteItem> jobs = [];
    List<FavoriteItem> carRent = [];
    List<FavoriteItem> otherServices = [];

    print('DEBUG: Total items to organize: ${favoritesList.length}');
    
    // Debug: Print the structure of the first item
    if (favoritesList.isNotEmpty) {
      print('First item type: ${favoritesList[0].runtimeType}');
      print('First item: ${favoritesList[0]}');
    }

    // Organize items by their add_category
    for (var item in favoritesList) {
      try {
        print('🔍 Processing item type: ${item.runtimeType}');
        
        if (item is Map<String, dynamic>) {
          final favoriteItem = FavoriteItem.fromJson(item);
          final originalCategory = favoriteItem.ad.addCategory;
          
          // Try to normalize the category using CategoryMapper, but also check original format
          final normalizedCategory = CategoryMapper.toApiFormat(originalCategory);
          
          print('🔍 Processing item - Original category: "$originalCategory", Normalized: "$normalizedCategory", ad_id: ${favoriteItem.ad.id}');

          // Check both normalized and original category formats
          String categoryToMatch = normalizedCategory;
          
          // If normalized category is the same as original (no mapping found), 
          // try to match with common variations
          if (normalizedCategory == originalCategory.toLowerCase().replaceAll(' ', '_')) {
            // Check if it matches any of our expected categories directly
            switch (originalCategory.toLowerCase()) {
              case 'car services':
                categoryToMatch = 'car_services';
                break;
              case 'jobs':
              case 'jop':
                categoryToMatch = 'Jop';
                break;
              case 'other services':
                categoryToMatch = 'other_services';
                break;
              default:
                categoryToMatch = normalizedCategory;
            }
          }

          switch (categoryToMatch) {
            case 'car_sales':
              carSales.add(favoriteItem);
              print('✅ Added to car sales category');
              break;
            case 'real_estate':
              realEstate.add(favoriteItem);
              print('✅ Added to real estate category');
              break;
            case 'electronics':
              electronics.add(favoriteItem);
              print('✅ Added to electronics category');
              break;
            case 'jobs':
              jobs.add(favoriteItem);
              print('✅ Added to jobs category');
              break;
            case 'car_rent':
              carRent.add(favoriteItem);
              print('✅ Added to car rent category');
              break;
            case 'car_services':
              carServices.add(favoriteItem);
              print('✅ Added to car services category');
              break;
            case 'restaurant':
              restaurant.add(favoriteItem);
              print('✅ Added to restaurant category');
              break;
            case 'other_services':
              otherServices.add(favoriteItem);
              print('✅ Added to other services category');
              break;
            default:
              print('❌ Unmatched category: "$categoryToMatch" (original: "$originalCategory") - adding to other services');
              otherServices.add(favoriteItem);
              break;
          }
        } else {
          print('Item is not a Map<String, dynamic>, it is: ${item.runtimeType}');
        }
      } catch (e) {
        // Skip invalid items and continue processing
        print('Error processing favorite item: $e');
        print('Item that caused error: $item');
        continue;
      }
    }

    // Create FavoritesData with organized lists
    final favoritesData = FavoritesData(
      restaurant: restaurant,
      carServices: carServices,
      carSales: carSales,
      realEstate: realEstate,
      electronics: electronics,
      jobs: jobs,
      carRent: carRent,
      otherServices: otherServices,
    );

    return FavoritesResponse(
      status: true,
      data: favoritesData,
    );
  }

  /// Add an item to favorites
  Future<Map<String, dynamic>> addToFavorites({
    required int adId,
    required String categorySlug,
    required int userId,
  }) async {
    try {
      // Normalize category slug to API format (underscored by default)
      final normalizedCategorySlug = CategoryMapper.toApiFormat(categorySlug);

      // Build a list of candidate slugs to maximize server compatibility
      final candidates = _buildFavoriteSlugCandidates(
        normalizedCategorySlug,
        original: categorySlug,
      );

      print('🔵 Original category slug: "$categorySlug"');
      print('🔵 Normalized category slug: "$normalizedCategorySlug"');
      print('🔵 Candidate slugs to try: $candidates');

      dynamic lastError;
      for (final candidate in candidates) {
        final data = {
          'ad_id': adId,
          'category_slug': candidate,
          'user_id': userId,
        };

        try {
          print('🔵 Attempting to add favorite with slug: "$candidate" and data: $data');
          final response = await _apiService.post(
            '/api/favorites',
            data: data,
          );
          print('🟢 Add to favorites succeeded with slug "$candidate": $response');
          return response as Map<String, dynamic>;
        } catch (e) {
          // Keep trying with next candidate on known slug errors
          print('🟠 Attempt with slug "$candidate" failed: $e');
          lastError = e;
          continue;
        }
      }

      // If all attempts failed, surface the last error
      print('🔴 All attempts to add favorite failed. Last error: $lastError');
      throw Exception('Failed to add to favorites: $lastError');
    } catch (e) {
      print('🔴 Error adding to favorites: $e');
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Build robust candidate slugs covering underscore, hyphen, and common synonyms
  List<String> _buildFavoriteSlugCandidates(String normalized, {required String original}) {
    final slug = (normalized).trim().toLowerCase();
    final orig = (original).trim().toLowerCase();

    final set = <String>{};
    // Start with normalized value first
    if (slug.isNotEmpty) set.add(slug);
    // Add original if different
    if (orig.isNotEmpty) set.add(orig);

    // Hyphenated variant
    final hyphen = slug.replaceAll('_', '-');
    if (hyphen.isNotEmpty) set.add(hyphen);

    // Display-format variant (API sometimes uses display names like "Cars Sales")
    final display = CategoryMapper.toDisplayFormat(slug);
    if (display.isNotEmpty) {
      set.add(display);
      set.add(display.toLowerCase());
    }
    // Space-separated lowercase as another variant (e.g., "car sales")
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
        // Also try original hyphen variant
        set.add(orig.replaceAll('_', '-'));
        break;
    }

    // Preserve order: normalized -> original -> hyphen -> extras
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

  /// Remove an item from favorites
  Future<Map<String, dynamic>> removeFromFavorites({
    required int favoriteId,
    String? token,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/favorites/$favoriteId/remove',
        data: {},
        token: token,
      );
      
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Remove a favorite using DELETE /api/favorites/{userId} with ad_id and category_slug in body
  Future<Map<String, dynamic>> removeFromFavoritesByUser({
    required int userId,
    required int adId,
    required String categorySlug,
    String? token,
  }) async {
    try {
      final payload = {
        'ad_id': adId,
        'category_slug': categorySlug,
      };
      final response = await _apiService.delete(
        '/api/favorites/$userId',
        data: payload,
        token: token,
      );
      return (response is Map<String, dynamic>)
          ? response
          : {'success': true, 'data': response};
    } catch (e) {
      throw Exception('Failed to remove favorite via user endpoint: $e');
    }
  }
}