// lib/presentation/providers/other_services_ad_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/repository/other_services_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/model/other_service_ad_model.dart';

class OtherServicesAdProvider extends ChangeNotifier {
  final OtherServicesRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  OtherServicesAdProvider() : _repository = OtherServicesRepository(ApiService());
  
  List<String> _serviceNames = [];
  List<String> get serviceNames => _serviceNames;

  List<OtherServiceAdModel> _ads = [];
  List<OtherServiceAdModel> _allFetchedAds = []; // Store all fetched ads for local filtering
  bool _isLoading = false;
  String? _error;
  int _totalAds = 0;
  Map<String, String>? _initialFilters; // فلاتر أولية يتم تمريرها من الصفحة الرئيسية

  // Local price filters
  String? _priceFrom;
  String? _priceTo;

  List<OtherServiceAdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalAds => _totalAds;
  bool get sortByNearest => _sortByNearest;

  void setInitialFilters(Map<String, String> filters) {
    _initialFilters = filters;
  }

  // يمسح أي فلاتر أولية تم تمريرها سابقًا لضمان بحث نظيف
  void clearInitialFilters() {
    _initialFilters = null;
  }

  Future<void> fetchAds({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // دمج الفلاتر الأولية مع الفلاتر الحالية
      final Map<String, dynamic>? effectiveFilters = {
        ...?_initialFilters,
        ...?filters,
      };

      // تحديث فلاتر السعر المحلية من الفلاتر المُمرّرة
      final String? priceFromStr = effectiveFilters?['price_from']?.toString();
      final String? priceToStr = effectiveFilters?['price_to']?.toString();
      _priceFrom = (priceFromStr != null && priceFromStr.isNotEmpty)
          ? priceFromStr
          : null;
      _priceTo = (priceToStr != null && priceToStr.isNotEmpty)
          ? priceToStr
          : null;

      // Public data - no token required for browsing other service ads
      final response = await _repository.getOtherServiceAds(query: effectiveFilters);
      _allFetchedAds = response.ads; // Store all fetched ads
      _totalAds = response.total;

      // Apply local price filtering
      _performLocalPriceFilter();

      _recalculateServiceNamesFromVisibleAds();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _performLocalPriceFilter() {
    List<OtherServiceAdModel> filteredList = List.from(_allFetchedAds);

    // Filter by price
    final fromPrice = double.tryParse(_priceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(_priceTo?.replaceAll(',', '') ?? '');
    
    if (fromPrice != null) {
      filteredList.retainWhere((ad) {
        final adPrice = double.tryParse(ad.price.replaceAll(',', '').replaceAll('AED', '').trim());
        return adPrice != null && adPrice >= fromPrice;
      });
    }
    
    if (toPrice != null) {
      filteredList.retainWhere((ad) {
        final adPrice = double.tryParse(ad.price.replaceAll(',', '').replaceAll('AED', '').trim());
        return adPrice != null && adPrice <= toPrice;
      });
    }

    _ads = filteredList;
    _totalAds = filteredList.length; // Update total ads count based on filtered results

    // Recalculate service names based on currently visible ads
    _recalculateServiceNamesFromVisibleAds();
  }

  void setPriceFilters(String? priceFrom, String? priceTo) {
    _priceFrom = priceFrom;
    _priceTo = priceTo;
    _performLocalPriceFilter();
    notifyListeners();
  }

  void clearPriceFilters() {
    _priceFrom = null;
    _priceTo = null;
    _performLocalPriceFilter();
    notifyListeners();
  }

  void _recalculateServiceNamesFromVisibleAds() {
    if (_ads.isNotEmpty) {
      _serviceNames = _ads
          .map((ad) => ad.serviceName)
          .whereType<String>()
          .toSet()
          .toList();
    } else {
      _serviceNames = [];
    }
  }

  // +++ أضيفي متغيرات جديدة لـ Offers Box +++
  List<OtherServiceAdModel> _offerAds = [];
  List<OtherServiceAdModel> _allFetchedOfferAds = []; // Store all fetched offer ads
  bool _isLoadingOffers = false;
  String? _offersError;

  // Local price filters for offers
  String? _offerPriceFrom;
  String? _offerPriceTo;

  List<OtherServiceAdModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;

  // +++ أضيفي هذه الدالة الجديدة بالكامل +++
  Future<void> fetchOfferAds({Map<String, dynamic>? filters}) async {
    _isLoadingOffers = true;
    _offersError = null;
    notifyListeners();

    try {
      // Public data - no token required for browsing other service offer ads
      _allFetchedOfferAds = await _repository.getOffersBoxAds(query: filters);
      
      // Apply local price filtering for offers
      _performLocalOfferPriceFilter();
      
    } catch (e) {
      _offersError = e.toString();
    } finally {
      _isLoadingOffers = false;
      notifyListeners();
    }
  }

  void _performLocalOfferPriceFilter() {
    List<OtherServiceAdModel> filteredList = List.from(_allFetchedOfferAds);

    // Filter by price
    final fromPrice = double.tryParse(_offerPriceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(_offerPriceTo?.replaceAll(',', '') ?? '');
    
    if (fromPrice != null) {
      filteredList.retainWhere((ad) {
        final adPrice = double.tryParse(ad.price.replaceAll(',', '').replaceAll('AED', '').trim());
        return adPrice != null && adPrice >= fromPrice;
      });
    }
    
    if (toPrice != null) {
      filteredList.retainWhere((ad) {
        final adPrice = double.tryParse(ad.price.replaceAll(',', '').replaceAll('AED', '').trim());
        return adPrice != null && adPrice <= toPrice;
      });
    }

    _offerAds = filteredList;
  }

  void setOfferPriceFilters(String? priceFrom, String? priceTo) {
    _offerPriceFrom = priceFrom;
    _offerPriceTo = priceTo;
    _performLocalOfferPriceFilter();
    notifyListeners();
  }

  // Sort by nearest functionality
  bool _sortByNearest = false;
  bool _offerSortByNearest = false;

  void setSortByNearest(bool value) {
    _sortByNearest = value;
    // Re-apply local filters (e.g., could integrate distance sort in future)
    _performLocalPriceFilter();
    notifyListeners();
  }
 

  void clearOfferPriceFilters() {
    _offerPriceFrom = null;
    _offerPriceTo = null;
    _performLocalOfferPriceFilter();
    notifyListeners();
  }
}