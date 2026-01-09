import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/restaurant_ad_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RestaurantOffersProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // حالات العروض
  List<RestaurantAdModel> _offerAds = [];
  List<RestaurantAdModel> _allFetchedOfferAds = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  // Getters
  List<RestaurantAdModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;

  // فلاتر العروض
  String? offerPriceFrom, offerPriceTo;
  List<String> _selectedCategories = [];
  List<String> _selectedDistricts = [];

  List<String> get selectedCategories => _selectedCategories;
  List<String> get selectedDistricts => _selectedDistricts;

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

  // جلب عروض المطاعم من API
  Future<void> fetchOfferAds() async {
    _isLoadingOffers = true;
    _offersError = null;
    safeNotifyListeners();
    
    try {
      // بيانات عامة: لا يجب أن تعتمد على أي توكن
      final response = await _apiService.get(
        '/api/offers-box/restaurant',
      );
      
      // التعامل مع الاستجابة بناءً على نوعها
      List<dynamic> adsData;
      if (response is List) {
        // API يعيد List مباشرة
        adsData = response;
      } else if (response is Map<String, dynamic>) {
        // API يعيد Map مع مفتاح data

        if (response['success'] == true && response['data'] != null) {
          adsData = response['data'];
        } else {
          throw Exception(response['message'] ?? 'Failed to fetch offers');
        }
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
      
      
      _allFetchedOfferAds = adsData
          .map((json) => RestaurantAdModel.fromJson(json))
          .toList();
      
      for (int i = 0; i < _allFetchedOfferAds.length && i < 3; i++) {
        final ad = _allFetchedOfferAds[i];
      }
      
      _performLocalOfferFilter();
    } catch (e) {
      _offersError = e.toString();
    } finally {
      _isLoadingOffers = false;
      safeNotifyListeners();
    }
  }

  // تطبيق الفلاتر المحلية
  void _performLocalOfferFilter() {
    List<RestaurantAdModel> filteredList = List.from(_allFetchedOfferAds);
    
    // فلتر السعر
    final fromPrice = double.tryParse(offerPriceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(offerPriceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.priceRange.replaceAll(',', '')) ?? 0) >= fromPrice);
    }
    if (toPrice != null) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.priceRange.replaceAll(',', '')) ?? 0) <= toPrice);
    }
    
    // فلتر الفئات
    if (_selectedCategories.isNotEmpty) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          _selectedCategories.contains(ad.category));
    }
    
    // فلتر المناطق
    if (_selectedDistricts.isNotEmpty) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          _selectedDistricts.contains(ad.district));
    }
    
    _offerAds = filteredList;
    safeNotifyListeners();
  }

  // تحديث فلتر السعر
  void updatePriceRangeForOffers(String? from, String? to) {
    offerPriceFrom = from;
    offerPriceTo = to;
    _performLocalOfferFilter();
  }

  // تحديث فلتر الفئات
  void updateCategoriesFilter(List<String> categories) {
    _selectedCategories = categories;
    _performLocalOfferFilter();
  }

  // تحديث فلتر المناطق
  void updateDistrictsFilter(List<String> districts) {
    _selectedDistricts = districts;
    _performLocalOfferFilter();
  }

  // إعادة تعيين الفلاتر
  void resetFilters() {
    offerPriceFrom = null;
    offerPriceTo = null;
    _selectedCategories.clear();
    _selectedDistricts.clear();
    _performLocalOfferFilter();
  }
}