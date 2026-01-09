// lib/presentation/providers/car_rent_offers_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/car_rent_ad_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class CarRentOffersProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // حالات العروض
  List<CarRentAdModel> _offerAds = [];
  List<CarRentAdModel> _allFetchedOfferAds = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  // Getters
  List<CarRentAdModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;

  // فلاتر العروض
  String? offerYearFrom, offerYearTo;
  String? offerPriceFrom, offerPriceTo;
  List<String> _selectedMakes = [];
  List<String> _selectedModels = [];
  List<String> _selectedDistricts = [];

  List<String> get selectedMakes => _selectedMakes;
  List<String> get selectedModels => _selectedModels;
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

  // جلب عروض تأجير السيارات من API
  Future<void> fetchOfferAds() async {
    _isLoadingOffers = true;
    _offersError = null;
    safeNotifyListeners();
    
    try {
      // Public data - no token required for browsing car rental offer ads
      final response = await _apiService.get(
        '/api/offers-box/car_rent',
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
          .map((json) => CarRentAdModel.fromJson(json))
          .toList();
      
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
    List<CarRentAdModel> filteredList = List.from(_allFetchedOfferAds);
    
    // فلتر السنة
    final fromYear = int.tryParse(offerYearFrom ?? '');
    final toYear = int.tryParse(offerYearTo ?? '');
    if (fromYear != null) {
      filteredList.retainWhere((ad) => (int.tryParse(ad.year ?? '') ?? 0) >= fromYear);
    }
    if (toYear != null) {
      filteredList.retainWhere((ad) => (int.tryParse(ad.year ?? '') ?? 0) <= toYear);
    }
    
    // فلتر السعر
    final fromPrice = double.tryParse(offerPriceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(offerPriceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null) {
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) >= fromPrice);
    }
    if (toPrice != null) {
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) <= toPrice);
    }
    
    // فلتر الماركة
    if (_selectedMakes.isNotEmpty) {
      filteredList.retainWhere((ad) => 
          _selectedMakes.any((make) => 
              ad.make?.toLowerCase().contains(make.toLowerCase()) == true));
    }
    
    // فلتر الموديل
    if (_selectedModels.isNotEmpty) {
      filteredList.retainWhere((ad) => 
          _selectedModels.any((model) => 
              ad.model?.toLowerCase().contains(model.toLowerCase()) == true));
    }
    
    // فلتر المنطقة
    if (_selectedDistricts.isNotEmpty) {
      filteredList.retainWhere((ad) => 
          _selectedDistricts.any((district) => 
              ad.district?.toLowerCase().contains(district.toLowerCase()) == true));
    }
    
    _offerAds = filteredList;
    safeNotifyListeners();
  }

  // تحديث فلتر السنة
  void updateYearRangeForOffers(String? from, String? to) {
    offerYearFrom = from;
    offerYearTo = to;
    _performLocalOfferFilter();
  }

  // تحديث فلتر السعر
  void updatePriceRangeForOffers(String? from, String? to) {
    offerPriceFrom = from;
    offerPriceTo = to;
    _performLocalOfferFilter();
  }

  // تحديث فلتر الماركة
  void updateSelectedMakes(List<String> makes) {
    _selectedMakes = makes;
    _performLocalOfferFilter();
  }

  // تحديث فلتر الموديل
  void updateSelectedModels(List<String> models) {
    _selectedModels = models;
    _performLocalOfferFilter();
  }

  // تحديث فلتر المنطقة
  void updateSelectedDistricts(List<String> districts) {
    _selectedDistricts = districts;
    _performLocalOfferFilter();
  }

  // إعادة تعيين جميع الفلاتر
  void resetFilters() {
    offerYearFrom = null;
    offerYearTo = null;
    offerPriceFrom = null;
    offerPriceTo = null;
    _selectedMakes.clear();
    _selectedModels.clear();
    _selectedDistricts.clear();
    _performLocalOfferFilter();
  }
}