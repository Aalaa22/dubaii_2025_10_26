import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/presentation/providers/restaurants_info_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RestaurantAdProvider with ChangeNotifier {
  final RestaurantsInfoProvider _restaurantsInfoProvider;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RestaurantAdProvider(this._restaurantsInfoProvider);

  // --- حالات التحميل والأخطاء ---
  bool _isLoadingAds = false;
  String? _loadAdsError;
  List<FavoriteItemInterface> _restaurantAds = [];
  List<dynamic> _rawRestaurantData = [];

  bool get isLoadingAds => _isLoadingAds;
  String? get loadAdsError => _loadAdsError;
  List<FavoriteItemInterface> get restaurantAds => _restaurantAds;

  // --- الفلاتر المحددة ---
  List<String> _selectedDistricts = [];
  List<String> _selectedCategories = [];
  String? _priceFrom, _priceTo;
  String? _keyword;
  RangeValues? priceRange;

  // Price filter properties
  String? get priceFrom => _priceFrom;
  String? get priceTo => _priceTo;

  List<String> get selectedDistricts => _selectedDistricts;
  List<String> get selectedCategories => _selectedCategories;
  String? get keyword => _keyword;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // --- دالة جلب البيانات من API ---
  Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
    _isLoadingAds = true;
    _loadAdsError = null;
    safeNotifyListeners();

    try {
      // Public data - no token required for browsing restaurant ads
      // جلب البيانات من API
      final restaurants = await _restaurantsInfoProvider.fetchRestaurants(
        emirate: 'All',
        district: _selectedDistricts.isEmpty ? 'All' : _selectedDistricts.first,
        category:
            _selectedCategories.isEmpty ? 'All' : _selectedCategories.first,
        priceFrom: _priceFrom,
        priceTo: _priceTo,
      );

      _rawRestaurantData = restaurants;

      // Debug: طباعة بيانات المطاعم الخام
      // // print('=== DEBUG: بيانات المطاعم الخام ===');
      // // print('عدد المطاعم المستلمة: ${restaurants.length}');
      for (int i = 0; i < restaurants.length && i < 3; i++) {
        final restaurant = restaurants[i];
        // // print('--- مطعم ${i + 1} ---');
        // // print('ID: ${restaurant['id']}');
        // // print('Title: ${restaurant['title']}');
        // // print('Main Image: ${restaurant['main_image']}');
        // // print('Emirate: ${restaurant['emirate']}');
        // // print('District: ${restaurant['district']}');
        // // print('Category: ${restaurant['category']}');
        // // print('Price Range: ${restaurant['price_range']}');
        // // print('Phone: ${restaurant['phone_number']}');
        // // print('Plan Type: ${restaurant['plan_type']}');
        // // print('Status: ${restaurant['add_status']}');
        // // print('Created At: ${restaurant['created_at']}');
        // // print('Raw Data: $restaurant');
        // // print('---');
      }
      // // print('=== نهاية DEBUG ===');

      // تحويل البيانات إلى FavoriteItemInterface
      _restaurantAds = _convertApiDataToFavoriteItems(restaurants);

      // Debug: طباعة البيانات المحولة
      // // print('=== DEBUG: البيانات المحولة ===');
      // // print('عدد المطاعم المحولة: ${_restaurantAds.length}');
      for (int i = 0; i < _restaurantAds.length && i < 3; i++) {
        final item = _restaurantAds[i];
        // // print('--- مطعم محول ${i + 1} ---');
        // // print('Title: ${item.title}');
        // // print('Images: ${item.images}');
        // // print('Location: ${item.location}');
        // // print('Price: ${item.price}');
        // // print('Details: ${item.details}');
        // // print('Contact: ${item.contact}');
        // // print('Is Premium: ${item.isPremium}');
        // // print('---');
      }
      // // print('=== نهاية DEBUG المحولة ===');
    } catch (e) {
      _loadAdsError = e.toString();
      _restaurantAds = [];
    } finally {
      _isLoadingAds = false;
      safeNotifyListeners();
    }
  }

  // --- تحويل البيانات من API إلى FavoriteItemInterface ---
  List<FavoriteItemInterface> _convertApiDataToFavoriteItems(
      List<dynamic> apiData) {
    const String baseUrl = 'https://dubaisale.app/storage/';

    return apiData.map((restaurant) {
      final planType = _nullToString(restaurant['plan_type']);

      // بناء رابط الصورة الرئيسية - إضافة timestamp لتجنب الكاش
      // لا نُدرج قيمة وهمية عندما لا توجد صورة
      String mainImageUrl = '';
      if (restaurant['main_image'] != null &&
          restaurant['main_image'].toString().isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        mainImageUrl =
            baseUrl + restaurant['main_image'].toString() + '?t=$timestamp';
      }

      // بناء قائمة الصور المصغرة - إضافة timestamp لتجنب الكاش
      // عند عدم توفر صور، نُبقي القائمة فارغة بدون صورة افتراضية
      List<String> thumbnailImages = [];
      if (restaurant['thumbnail_images'] != null &&
          restaurant['thumbnail_images'] is List) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        thumbnailImages = (restaurant['thumbnail_images'] as List)
            .where((img) => img != null && img.toString().isNotEmpty)
            .map((img) => baseUrl + img.toString() + '?t=$timestamp')
            .toList();
        // إذا كانت القائمة فارغة بعد المعالجة، نتركها فارغة
      }

      // بناء نص الموقع من emirate/district/area
      String locationText = '';
      final emirate = restaurant['emirate']?.toString() ?? '';
      final district = restaurant['district']?.toString() ?? '';
      final area = restaurant['area']?.toString() ?? '';

      List<String> locationParts = [];
      if (emirate.isNotEmpty && emirate != 'null') locationParts.add(emirate);
      if (district.isNotEmpty && district != 'null')
        locationParts.add(district);
      if (area.isNotEmpty && area != 'null') locationParts.add(area);

      locationText = locationParts.isNotEmpty
          ? locationParts.join('/')
          : 'Unknown Location';

      return RestaurantAdItem(
        id: _nullToString(restaurant['id']),
        title: _nullToString(restaurant['title']),
        description: _nullToString(restaurant['description']),
        price: _nullToString(restaurant['price_range']),
        imageUrl: mainImageUrl,
        location: locationText,
        phoneNumber: _nullToString(restaurant['phone_number']),
        // بعض الـ endpoints تُرجع الحقل باسم "whatsapp_number" بدلًا من "whatsapp"
        // نعتمد كلا الاسمين لضمان التوافق مع البيانات القادمة من الـ API
        whatsapp: _nullToString(
            restaurant['whatsapp_number'] ?? restaurant['whatsapp']),
        priority: _getPriorityFromPlanType(planType),
        createdAt: _nullToString(restaurant['created_at']),
        category: _nullToString(restaurant['category']),
        addCategory: _nullToString(restaurant['add_category'] ??
            'restaurant'), // Add category from API
        emirate: emirate.isNotEmpty ? emirate : 'Unknown',
        district: district.isNotEmpty ? district : 'Unknown',
        // الخصائص الإضافية المطلوبة
        contact: _nullToString(restaurant['advertiser_name']),
        date: _formatDateOnly(restaurant['created_at']),
        details: _nullToString(restaurant['category']),
        // لا نضيف صورًا وهمية؛ إذا لم توجد صور تبقى القائمة فارغة
        images: [
          ...(mainImageUrl.isNotEmpty ? [mainImageUrl] : []),
          ...thumbnailImages,
        ],
        isPremium: planType.toLowerCase().contains('premium'),
        line1: _nullToString(restaurant['title']),
      );
    }).toList();
  }

  // --- تحويل null إلى قيم افتراضية مناسبة ---
  String _nullToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // --- تنسيق التاريخ بدون الوقت ---
  String _formatDateOnly(dynamic dateValue) {
    if (dateValue == null) return 'Unknown Date';
    try {
      final dateTime = DateTime.parse(dateValue.toString());
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateValue
          .toString()
          .split(' ')
          .first; // fallback: أخذ الجزء الأول قبل المسافة
    }
  }

  // --- تحديد الأولوية من نوع الخطة ---
  AdPriority _getPriorityFromPlanType(String planType) {
    switch (planType.toLowerCase()) {
      case 'premium_star':
        return AdPriority.PremiumStar;
      case 'premium':
        return AdPriority.premium;
      case 'featured':
        return AdPriority.featured;
      default:
        return AdPriority.free;
    }
  }

  // --- تحديث الفلاتر ---
  void updateSelectedDistricts(List<String> districts) {
    _selectedDistricts = districts;
    safeNotifyListeners();
    // Apply filters immediately when districts change
    applyFilters(
      selectedDistricts: districts,
      selectedCategories: selectedCategories,
    );
  }

  void updateSelectedCategories(List<String> categories) {
    _selectedCategories = categories;
    safeNotifyListeners();
    // Apply filters immediately when categories change
    applyFilters(
      selectedDistricts: selectedDistricts,
      selectedCategories: categories,
    );
  }

  void updatePriceRange(String? from, String? to) {
    _priceFrom = from;
    _priceTo = to;
    _performLocalFilter(); // استخدام الفلترة المحلية بدلاً من استدعاء API
  }

  void updateKeyword(String? value) {
    _keyword = (value ?? '').trim().isEmpty ? null : value!.trim();
    _performLocalFilter();
  }

  // --- دالة الفلترة المحلية (مثل car_sales_ad_provider) ---
  void _performLocalFilter() {
    if (_rawRestaurantData.isEmpty) {
      // إذا لم تكن هناك بيانات محملة، قم بجلبها أولاً
      applyAndFetchAds();
      return;
    }

    // تحويل البيانات الخام إلى FavoriteItemInterface
    List<FavoriteItemInterface> allItems =
        _convertApiDataToFavoriteItems(_rawRestaurantData);
    List<FavoriteItemInterface> filteredItems = allItems;

    // فلتر السعر محلياً
    if (_priceFrom != null || _priceTo != null) {
      filteredItems = filteredItems.where((item) {
        if (item is RestaurantAdItem) {
          // استخراج السعر من النص (مثل "50-100 AED" أو "100 AED")
          final priceText = item.price.replaceAll(RegExp(r'[^0-9.-]'), '');
          final prices = priceText.split('-');

          if (prices.isNotEmpty) {
            final minPrice = double.tryParse(prices[0]) ?? 0;
            final maxPrice = prices.length > 1
                ? (double.tryParse(prices[1]) ?? minPrice)
                : minPrice;

            // تطبيق فلتر السعر الأدنى
            if (_priceFrom != null) {
              final fromPrice =
                  double.tryParse(_priceFrom!.replaceAll(',', '')) ?? 0;
              if (maxPrice < fromPrice) return false;
            }

            // تطبيق فلتر السعر الأعلى
            if (_priceTo != null) {
              final toPrice = double.tryParse(_priceTo!.replaceAll(',', '')) ??
                  double.infinity;
              if (minPrice > toPrice) return false;
            }
          }
        }
        return true;
      }).toList();
    }

    // فلتر الكلمة المفتاحية - مطابقة بالاحتواء (غير حساسة لحالة الأحرف)
    if (_keyword != null && _keyword!.isNotEmpty) {
      final kw = _keyword!.trim().toLowerCase();
      filteredItems = filteredItems.where((item) {
        final title = item.title.trim().toLowerCase();
        final details = item.details.trim().toLowerCase();
        final description = (item is RestaurantAdItem)
            ? item.description.trim().toLowerCase()
            : '';
        return title.contains(kw) || details.contains(kw) || description.contains(kw);
      }).toList();
    }

    // فلتر المناطق - إذا كان هناك مناطق مختارة وليست "All"
    if (_selectedDistricts.isNotEmpty && !_selectedDistricts.contains('All')) {
      filteredItems = filteredItems.where((item) {
        if (item is RestaurantAdItem) {
          return _selectedDistricts.any((district) =>
              item.district.toLowerCase().contains(district.toLowerCase()));
        }
        return false;
      }).toList();
    }

    // فلتر الفئات - إذا كان هناك فئات مختارة وليست "All"
    if (_selectedCategories.isNotEmpty &&
        !_selectedCategories.contains('All')) {
      filteredItems = filteredItems.where((item) {
        if (item is RestaurantAdItem) {
          return _selectedCategories.any((category) =>
              item.category.toLowerCase().contains(category.toLowerCase()));
        }
        return false;
      }).toList();
    }

    _restaurantAds = filteredItems;
    safeNotifyListeners();
  }

  // --- تطبيق الفلاتر ---
  Future<void> applyFilters({
    List<String>? selectedDistricts,
    List<String>? selectedCategories,
    String? district,
    String? category,
    String? emirate,
    String? keyword,
  }) async {
    _isLoadingAds = true;
    _loadAdsError = null;
    safeNotifyListeners();

    try {
      // تحديث الكلمة المفتاحية محلياً
      if (keyword != null) {
        _keyword = keyword.trim().isEmpty ? null : keyword.trim();
      }

      // Public data - no token required for browsing restaurant ads
      // جلب جميع البيانات أولاً بدون فلاتر محددة
      final restaurants = await _restaurantsInfoProvider.fetchRestaurants(
        emirate: emirate ?? 'All',
        district: district ?? 'All',
        category: category ?? 'All',
        priceFrom: _priceFrom,
        priceTo: _priceTo,
      );

      _rawRestaurantData = restaurants;

      // تحويل البيانات إلى FavoriteItemInterface
      List<FavoriteItemInterface> allItems =
          _convertApiDataToFavoriteItems(restaurants);

      // تطبيق الفلترة المحلية للفئات والمناطق المتعددة
      List<FavoriteItemInterface> filteredItems = allItems;

      // فلتر الكلمة المفتاحية - مطابقة بالاحتواء (غير حساسة لحالة الأحرف)
      if (_keyword != null && _keyword!.isNotEmpty) {
        final kw = _keyword!.trim().toLowerCase();
        filteredItems = filteredItems.where((item) {
          final title = item.title.trim().toLowerCase();
          final details = item.details.trim().toLowerCase();
          final description = (item is RestaurantAdItem)
              ? item.description.trim().toLowerCase()
              : '';
          return title.contains(kw) || details.contains(kw) || description.contains(kw);
        }).toList();
      }

      // فلتر المناطق - إذا كان هناك مناطق مختارة وليست "All"
      if (selectedDistricts != null &&
          selectedDistricts.isNotEmpty &&
          !selectedDistricts.contains('All')) {
        filteredItems = filteredItems.where((item) {
          if (item is RestaurantAdItem) {
            return selectedDistricts.any((district) =>
                item.district.toLowerCase().contains(district.toLowerCase()));
          }
          return false;
        }).toList();
      }

      // فلتر الفئات - إذا كان هناك فئات مختارة وليست "All"
      if (selectedCategories != null &&
          selectedCategories.isNotEmpty &&
          !selectedCategories.contains('All')) {
        filteredItems = filteredItems.where((item) {
          if (item is RestaurantAdItem) {
            return selectedCategories.any((category) =>
                item.category.toLowerCase().contains(category.toLowerCase()));
          }
          return false;
        }).toList();
      }

      _restaurantAds = filteredItems;
    } catch (e) {
      _loadAdsError = e.toString();
      _restaurantAds = [];
    } finally {
      _isLoadingAds = false;
      safeNotifyListeners();
    }
  }

  // --- مسح جميع الفلاتر ---
  void clearAllFilters() {
    _selectedDistricts.clear();
    _selectedCategories.clear();
    priceRange = null;
    _priceFrom = null;
    _priceTo = null;
    _keyword = null;
    safeNotifyListeners();
  }
}

// --- كلاس لتمثيل بيانات المطعم ---
class RestaurantAdItem implements FavoriteItemInterface {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String price;
  @override
  final String imageUrl;
  @override
  final String location;
  @override
  final String phoneNumber;
  @override
  final String whatsapp;
  @override
  final AdPriority priority;
  @override
  final String createdAt;

  // إضافة الخصائص المطلوبة من FavoriteItemInterface
  @override
  final String contact;
  @override
  final String date;
  @override
  final String details;
  @override
  final List<String> images;
  @override
  final bool isPremium;
  @override
  final String line1;

  final String _category; // Renamed to avoid conflict
  final String _addCategory; // Add category field from API
  final String emirate;
  final String district;

  // Getter for FavoriteItemInterface category property
  @override
  String get category => _category; // Return the category field

  @override
  String get addCategory => _addCategory; // Dynamic category for API

  RestaurantAdItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.location,
    required this.phoneNumber,
    required this.whatsapp,
    required this.priority,
    required this.createdAt,
    required String category, // Parameter name remains the same
    required String addCategory, // Add category parameter
    required this.emirate,
    required this.district,
    required this.contact,
    required this.date,
    required this.details,
    required this.images,
    required this.isPremium,
    required this.line1,
  })  : _category = category,
        _addCategory = addCategory; // Initialize both private fields
}
