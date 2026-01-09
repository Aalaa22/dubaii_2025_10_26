// lib/presentation/providers/job_offer_ads_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/job_ad_model.dart';
import 'package:advertising_app/data/repository/jobs_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class JobOfferAdsProvider with ChangeNotifier {
  final JobsRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  JobOfferAdsProvider() : _repository = JobsRepository(ApiService());

  // حالات العروض
  List<JobAdModel> _offerAds = [];
  List<JobAdModel> _allFetchedOfferAds = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  // Getters
  List<JobAdModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;

  // فلاتر العروض
  List<String> _selectedCategories = [];
  List<String> _selectedSections = [];

  List<String> get selectedCategories => _selectedCategories;
  List<String> get selectedSections => _selectedSections;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // جلب إعلانات العروض
  Future<void> fetchOfferAds({Map<String, dynamic>? filters}) async {
    if (_isLoadingOffers) return;

    _isLoadingOffers = true;
    _offersError = null;
    _safeNotifyListeners();

    try {
      // Public data - no token required for browsing job offer ads
      print('🔍 Fetching job offer ads from: /api/jobs/offers-box/ads');
      
      final response = await _repository.getJobOfferAds(
        filters: filters?.map((key, value) => MapEntry(key, value.toString())),
      );

      _allFetchedOfferAds = response;
      _offerAds = List.from(_allFetchedOfferAds);
      
      print('📥 Loaded ${_offerAds.length} job offer ads');
      
      // تطبيق الفلاتر المحلية إذا كانت موجودة
      _performLocalOfferFilter();

    } catch (e) {
      _offersError = e.toString();
      print('❌ Error fetching job offer ads: $e');
    } finally {
      _isLoadingOffers = false;
      _safeNotifyListeners();
    }
  }

  // تطبيق الفلاتر المحلية
  void _performLocalOfferFilter() {
    List<JobAdModel> filteredAds = List.from(_allFetchedOfferAds);

    // فلتر حسب الفئات المختارة
    if (_selectedCategories.isNotEmpty) {
      filteredAds = filteredAds.where((ad) {
        return _selectedCategories.contains(ad.categoryType);
      }).toList();
    }

    // فلتر حسب الأقسام المختارة
    if (_selectedSections.isNotEmpty) {
      filteredAds = filteredAds.where((ad) {
        return _selectedSections.contains(ad.sectionType);
      }).toList();
    }

    _offerAds = filteredAds;
    _safeNotifyListeners();
  }

  // تحديث فلتر الفئات
  void updateSelectedCategories(List<String> categories) {
    _selectedCategories = categories;
    _performLocalOfferFilter();
  }

  // تحديث فلتر الأقسام
  void updateSelectedSections(List<String> sections) {
    _selectedSections = sections;
    _performLocalOfferFilter();
  }

  // مسح جميع الفلاتر
  void clearAllFilters() {
    _selectedCategories.clear();
    _selectedSections.clear();
    _performLocalOfferFilter();
  }

  // إعادة تحميل البيانات
  Future<void> refreshOfferAds() async {
    await fetchOfferAds();
  }
}