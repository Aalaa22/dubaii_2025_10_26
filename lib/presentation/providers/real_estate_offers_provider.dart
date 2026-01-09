import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/offer_box_model.dart';
import 'package:advertising_app/data/repository/real_estate_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RealEstateOffersProvider with ChangeNotifier {
  final RealEstateRepository _repository = RealEstateRepository(ApiService());
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // حالات العروض
  List<OfferBoxModel> _offerAds = [];
  List<OfferBoxModel> _allFetchedOfferAds = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  // Getters
  List<OfferBoxModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;

  // فلاتر العروض
  String? offerPriceFrom, offerPriceTo;
  List<String> _selectedTypes = [];
  List<String> _selectedDistricts = [];
  List<String> _selectedContracts = [];

  List<String> get selectedTypes => _selectedTypes;
  List<String> get selectedDistricts => _selectedDistricts;
  List<String> get selectedContracts => _selectedContracts;

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

  // جلب عروض العقارات من API
  Future<void> fetchOfferAds({Map<String, dynamic>? filters}) async {
    _isLoadingOffers = true;
    _offersError = null;
    safeNotifyListeners();
    
    try {
      print('=== RealEstateOffersProvider: بدء جلب البيانات ===');
      
      // Public data - no token required for browsing real estate offer ads
      print('Public data access - no authentication required');
      
      // Build query parameters from current filters
      Map<String, dynamic>? query;
      if (filters != null || _hasActiveFilters()) {
        query = {};
        
        // Add filters from parameter or current state
        if (filters != null) {
          query.addAll(filters);
        } else {
          // Build query from current filter state
          if (_selectedDistricts.isNotEmpty) {
            query['district'] = _selectedDistricts.join(',');
          }
          if (_selectedTypes.isNotEmpty) {
            query['property_type'] = _selectedTypes.join(',');
          }
          if (_selectedContracts.isNotEmpty) {
            query['contract_type'] = _selectedContracts.join(',');
          }
          if (offerPriceFrom != null && offerPriceFrom!.isNotEmpty) {
            query['price_from'] = offerPriceFrom;
          }
          if (offerPriceTo != null && offerPriceTo!.isNotEmpty) {
            query['price_to'] = offerPriceTo;
          }
        }
      }
      
      print('استدعاء API: /api/offers-box/real-estate');
      print('Query parameters: $query');
      _allFetchedOfferAds = await _repository.getRealEstateOffers(query: query);
      print('تم جلب ${_allFetchedOfferAds.length} عنصر من API');
      
      // If using server-side filtering, use results directly
      if (query != null) {
        _offerAds = _allFetchedOfferAds;
      } else {
        // Apply local filtering for backward compatibility
        _performLocalOfferFilter();
      }
      print('تم تطبيق الفلاتر بنجاح');
      
    } catch (e) {
      print('خطأ في fetchOfferAds: $e');
      _offersError = 'خطأ في تحميل البيانات: ${e.toString()}';
    } finally {
      _isLoadingOffers = false;
      safeNotifyListeners();
    }
  }

  // Check if there are active filters
  bool _hasActiveFilters() {
    return _selectedDistricts.isNotEmpty ||
           _selectedTypes.isNotEmpty ||
           _selectedContracts.isNotEmpty ||
           (offerPriceFrom != null && offerPriceFrom!.isNotEmpty) ||
           (offerPriceTo != null && offerPriceTo!.isNotEmpty);
  }

  // تطبيق الفلاتر المحلية
  void _performLocalOfferFilter() {
    List<OfferBoxModel> filteredList = List.from(_allFetchedOfferAds);
    
    // فلتر السعر
    final fromPrice = double.tryParse(offerPriceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(offerPriceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null) {
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.price?.replaceAll(',', '') ?? '0') ?? 0) >= fromPrice);
    }
    if (toPrice != null) {
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.price?.replaceAll(',', '') ?? '0') ?? 0) <= toPrice);
    }
    
    // فلتر النوع
    if (_selectedTypes.isNotEmpty) {
      filteredList.retainWhere((ad) => 
          _selectedTypes.any((type) => 
              ad.title?.toLowerCase().contains(type.toLowerCase()) == true));
    }
    
    // فلتر المنطقة
    if (_selectedDistricts.isNotEmpty) {
      filteredList.retainWhere((ad) => 
          _selectedDistricts.any((district) => 
              ad.location?.toLowerCase().contains(district.toLowerCase()) == true));
    }
    
    // فلتر العقد
    if (_selectedContracts.isNotEmpty) {
      filteredList.retainWhere((ad) => 
          _selectedContracts.any((contract) => 
              ad.title?.toLowerCase().contains(contract.toLowerCase()) == true));
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

  // تحديث فلتر النوع
  void updateSelectedTypes(List<String> types) {
    _selectedTypes = types;
    _performLocalOfferFilter();
  }

  // تحديث فلتر المنطقة
  void updateSelectedDistricts(List<String> districts) {
    _selectedDistricts = districts;
    _performLocalOfferFilter();
  }

  // تحديث فلتر العقد
  void updateSelectedContracts(List<String> contracts) {
    _selectedContracts = contracts;
    _performLocalOfferFilter();
  }

  // إعادة تعيين جميع الفلاتر
  void resetFilters() {
    offerPriceFrom = null;
    offerPriceTo = null;
    _selectedTypes.clear();
    _selectedDistricts.clear();
    _selectedContracts.clear();
    _performLocalOfferFilter();
  }


}