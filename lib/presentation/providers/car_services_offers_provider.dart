// lib/presentation/providers/car_services_offers_provider.dart

import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/data/repository/car_services_ad_repository.dart';
// import 'package:advertising_app/data/repository/car_services_offers_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class CarServicesOffersProvider extends ChangeNotifier {
  final CarServicesAdRepository _repository;
  // final CarServicesOffersRepository _offersRepository;

  CarServicesOffersProvider() : _repository = CarServicesAdRepository(ApiService());
                               // _offersRepository = CarServicesOffersRepository(ApiService());

  List<CarServiceModel> _offerAds = [];
  List<CarServiceModel> _allFetchedOfferAds = []; // القائمة الرئيسية من الـ API
  bool _isLoading = false;
  String? _error;
  
  // متغيرات فلتر السعر
  String? priceFrom;
  String? priceTo;
  
  // متغيرات الفلاتر المختارة
  List<String> _selectedServiceTypes = [];
  List<String> _selectedDistricts = [];

  List<CarServiceModel> get offerAds => _offerAds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get offersError => _error;

  // جلب بيانات العروض مع فلاتر اختيارية
  Future<void> fetchOfferAds({Map<String, String>? filters}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Public endpoint: browsing offers must NOT require authentication token
      final ads = await _repository.getOfferAds(filters: filters);
      _allFetchedOfferAds = ads;
      _offerAds = List.from(ads); // نسخ البيانات للفلترة
    } catch (e) {
      _error = e.toString();
      _allFetchedOfferAds = [];
      _offerAds = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تطبيق الفلاتر على البيانات المجلبة
  void applyFilters({
    List<String>? serviceNames,
    List<String>? districts,
    String? priceFromValue,
    String? priceToValue,
  }) {
    List<CarServiceModel> filteredAds = List.from(_allFetchedOfferAds);

    // فلتر أسماء الخدمات
    if (serviceNames != null && serviceNames.isNotEmpty) {
      filteredAds = filteredAds.where((ad) {
        final carAd = ad as CarServiceModel;
        return serviceNames.any((serviceName) => 
          carAd.serviceName?.toLowerCase().contains(serviceName.toLowerCase()) == true);
      }).toList();
    }

    // فلتر المناطق
    if (districts != null && districts.isNotEmpty) {
      filteredAds = filteredAds.where((ad) {
        final carAd = ad as CarServiceModel;
        return districts.any((district) => 
          carAd.district?.toLowerCase().contains(district.toLowerCase()) == true);
      }).toList();
    }

    // فلتر السعر
    if (priceFromValue != null && priceFromValue.isNotEmpty) {
      final fromPrice = double.tryParse(priceFromValue) ?? 0;
      filteredAds = filteredAds.where((ad) {
        final carAd = ad as CarServiceModel;
        final adPrice = double.tryParse(carAd.price.toString()) ?? 0;
        return adPrice >= fromPrice;
      }).toList();
    }

    if (priceToValue != null && priceToValue.isNotEmpty) {
      final toPrice = double.tryParse(priceToValue) ?? double.infinity;
      filteredAds = filteredAds.where((ad) {
        final carAd = ad as CarServiceModel;
        final adPrice = double.tryParse(carAd.price.toString()) ?? 0;
        return adPrice <= toPrice;
      }).toList();
    }

    // تحديث متغيرات السعر
    priceFrom = priceFromValue;
    priceTo = priceToValue;
    
    _offerAds = filteredAds;
    notifyListeners();
  }

  // إعادة تعيين الفلاتر
  void resetFilters() {
    priceFrom = null;
    priceTo = null;
    _offerAds = List.from(_allFetchedOfferAds);
    notifyListeners();
  }

  // تحديث البيانات
  Future<void> refreshOfferAds() async {
    await fetchOfferAds();
  }

  // جمع أسماء الخدمات الفريدة من الإعلانات المتاحة
  List<String> getUniqueServiceNames() {
    return _allFetchedOfferAds
        .map((ad) => (ad as CarServiceModel).serviceName)
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  // قائمة المناطق المجلبة من API
  List<String> _districts = [];
  List<String> get districts => _districts;

  // جلب المناطق من API
  Future<void> fetchDistricts() async {
    try {
      final response = await _repository.getEmirates();
      final allDistricts = <String>{};
      
      for (final emirate in response) {
        allDistricts.addAll(emirate.districts);
      }
      
      _districts = allDistricts.toList();
      _districts.sort();
      notifyListeners();
    } catch (e) {
      // print('Error fetching districts: $e');
    }
  }

  // جمع المناطق الفريدة من الإعلانات المتاحة
  List<String> getUniqueDistricts() {
    return _allFetchedOfferAds
        .map((ad) => (ad as CarServiceModel).district)
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }
}