// lib/presentation/providers/car_services_provider.dart

import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/data/repository/car_services_ad_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class CarServicesProvider extends ChangeNotifier {
  final CarServicesAdRepository _repository;

  CarServicesProvider() : _repository = CarServicesAdRepository(ApiService());

  List<CarServiceModel> _ads = [];
  List<CarServiceModel> _allFetchedAds = []; // القائمة الرئيسية من الـ API
  bool _isLoading = false;
  String? _error;

  // متغيرات فلتر السعر
  String? priceFrom;
  String? priceTo;

  List<CarServiceModel> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Single ad details
  CarServiceModel? _adDetails;
  bool _isLoadingAdDetails = false;
  String? _errorAdDetails;

  CarServiceModel? get adDetails => _adDetails;
  bool get isLoadingAdDetails => _isLoadingAdDetails;
  String? get errorAdDetails => _errorAdDetails;

  /// Gathers all filters and triggers the fetch.
  Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
    Map<String, String> finalFilters = {};

    if (initialFilters != null) {
      finalFilters.addAll(initialFilters);
      // print('=== APPLY AND FETCH DEBUG ===');
      // print('Initial filters received: $initialFilters');
      // print('Final filters to be sent: $finalFilters');
      // print('=============================');
    }

    await fetchAds(filters: finalFilters);
  }

  // Future<void> fetchAds({Map<String, String>? filters}) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     final token = await _storage.read(key: 'auth_token');
  //     if (token == null) {
  //       throw Exception('Authentication token not found');
  //     }

  //     final response = await _repository.getCarServiceAds(token: token);
  //     _ads = response.ads;

  //   } catch (e) {
  //     _error = e.toString();
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchAds({Map<String, String>? filters}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Public data - no token required for browsing car service ads
      // فصل فلاتر الـ API عن الفلاتر المحلية
      Map<String, dynamic>? apiFilters;
      Map<String, String>? localFilters;

      if (filters != null && filters.isNotEmpty) {
        apiFilters = {};
        localFilters = {};

        filters.forEach((key, value) {
          if (key == 'service_name' || key == 'district') {
            // فلتر service_name و district يتم تطبيقهما محلياً
            localFilters![key] = value;
          } else {
            // باقي الفلاتر ترسل للـ API
            apiFilters![key] = value;
          }
        });

        // print('=== SEARCH FILTERS DEBUG ===');
        // print('API Filters: $apiFilters');
        // print('Local Filters: $localFilters');
        // print('============================');
      }

      final response = await _repository.getCarServiceAds(
          query: apiFilters?.isNotEmpty == true ? apiFilters : null);

      List<CarServiceModel> resultAds = response.ads;
      _allFetchedAds = List.from(resultAds); // حفظ النسخة الأصلية

      // تطبيق الفلاتر المحلية
      if (localFilters != null && localFilters.isNotEmpty) {
        resultAds = _applyLocalFilters(resultAds, localFilters);
      }

      // تطبيق فلتر السعر المحلي
      resultAds = _applyPriceFilter(resultAds);

      _ads = resultAds;
    } catch (e) {
      _error = e.toString();
      // print('=== FETCH ADS ERROR ===');
      // print('Error: $e');
      // print('======================');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CarServiceModel> _applyLocalFilters(
      List<CarServiceModel> ads, Map<String, String> filters) {
    List<CarServiceModel> filteredAds = List.from(ads);

    // فلتر service_name
    if (filters.containsKey('service_name')) {
      final selectedServiceNames = filters['service_name']!.split(',');
      filteredAds = filteredAds.where((ad) {
        return selectedServiceNames.contains(ad.serviceName);
      }).toList();
    }

    // فلتر district
    if (filters.containsKey('district')) {
      final selectedDistricts = filters['district']!.split(',');
      filteredAds = filteredAds.where((ad) {
        return selectedDistricts.any((district) =>
            ad.district?.toLowerCase().contains(district.toLowerCase()) ==
            true);
      }).toList();
    }

    return filteredAds;
  }

  /// تطبيق فلتر السعر محلياً
  List<CarServiceModel> _applyPriceFilter(List<CarServiceModel> ads) {
    List<CarServiceModel> filteredAds = List.from(ads);

    // فلتر السعر
    final fromPrice = double.tryParse(priceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(priceTo?.replaceAll(',', '') ?? '');

    if (fromPrice != null) {
      filteredAds = filteredAds.where((ad) {
        final adPrice = double.tryParse(ad.price.replaceAll(',', '')) ?? 0;
        return adPrice >= fromPrice;
      }).toList();
    }

    if (toPrice != null) {
      filteredAds = filteredAds.where((ad) {
        final adPrice = double.tryParse(ad.price.replaceAll(',', '')) ?? 0;
        return adPrice <= toPrice;
      }).toList();
    }

    return filteredAds;
  }

  /// تحديث نطاق السعر وتطبيق الفلتر محلياً
  void updatePriceRange(String? from, String? to) {
    priceFrom = (from == null || from.isEmpty)
        ? null
        : from.replaceAll(RegExp(r'[^0-9.]'), '');
    priceTo = (to == null || to.isEmpty)
        ? null
        : to.replaceAll(RegExp(r'[^0-9.]'), '');
    _performLocalFilter();
  }

  /// مسح فلاتر السعر
  void clearPriceFilters() {
    priceFrom = null;
    priceTo = null;
    _performLocalFilter();
  }

  /// تطبيق جميع الفلاتر المحلية على البيانات المحفوظة
  void _performLocalFilter() {
    List<CarServiceModel> filteredList = List.from(_allFetchedAds);

    // تطبيق فلتر السعر
    filteredList = _applyPriceFilter(filteredList);

    _ads = filteredList;
    notifyListeners();
  }

  /// Fetch single car service ad details by ID
  Future<void> fetchCarServiceDetails(int adId) async {
    _isLoadingAdDetails = true;
    _errorAdDetails = null;
    _adDetails = null;
    notifyListeners();

    try {
      // Using getCarServiceById which is the standard public endpoint for details
      _adDetails = await _repository.getCarServiceById(adId: adId);
    } catch (e) {
      _errorAdDetails = e.toString();
    } finally {
      _isLoadingAdDetails = false;
      notifyListeners();
    }
  }
}
