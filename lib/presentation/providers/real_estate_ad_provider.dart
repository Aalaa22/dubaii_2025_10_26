// lib/presentation/providers/real_estate_ad_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/real_estate_ad_model.dart';
import 'package:advertising_app/data/repository/real_estate_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RealEstateAdProvider extends ChangeNotifier {
  final RealEstateRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RealEstateAdProvider() : _repository = RealEstateRepository(ApiService());

  List<RealEstateAdModel> _ads = [];
  List<RealEstateAdModel> _allFetchedAds = []; // Store original fetched ads for local filtering
  bool _isLoading = false;
  String? _error;
  int _totalAds = 0;
  bool _isSubmitting = false;

  // Price filter properties
  String? priceFrom;
  String? priceTo;
  // Keyword filter property
  String? _keyword;
  String? get keyword => _keyword;

  List<RealEstateAdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalAds => _ads.length; // Return actual filtered ads count
  bool get isSubmitting => _isSubmitting;

  Future<void> fetchAds({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Public data - no token required for browsing real estate ads
      // Separate API filters from local filters
      Map<String, dynamic>? apiFilters;
      Map<String, dynamic>? localFilters;
      
      if (filters != null && filters.isNotEmpty) {
        apiFilters = {};
        localFilters = {};
        
        filters.forEach((key, value) {
          if (key == 'price_from' || key == 'price_to' || key == 'keyword') {
            // Price and keyword filters are applied locally
            localFilters![key] = value;
          } else {
            // Other filters are sent to API
            apiFilters![key] = value;
          }
        });
      }

      final response = await _repository.getRealEstateAds(
        query: apiFilters?.isNotEmpty == true ? apiFilters : null
      );
      
      List<RealEstateAdModel> resultAds = response.ads;
      _allFetchedAds = List.from(resultAds); // Store original ads
      _totalAds = response.total;
      
      // Apply local filters (price + keyword)
      if (localFilters != null && localFilters.isNotEmpty) {
        if (localFilters.containsKey('price_from')) {
          priceFrom = localFilters['price_from'];
        }
        if (localFilters.containsKey('price_to')) {
          priceTo = localFilters['price_to'];
        }
        final incomingKeyword = localFilters['keyword']?.toString();
        _keyword = (incomingKeyword == null || incomingKeyword.trim().isEmpty)
            ? null
            : incomingKeyword.trim();
      }
      
      // Apply local filtering on stored data
      _performLocalFilter();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply price filter locally
  List<RealEstateAdModel> _applyPriceFilter(List<RealEstateAdModel> ads) {
    List<RealEstateAdModel> filteredAds = List.from(ads);
    
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

  /// Update price range and apply filter locally
  void updatePriceRange(String? from, String? to, {String? toPrice, String? fromPrice}) {
    priceFrom = (from == null || from.isEmpty) ? null : from.replaceAll(RegExp(r'[^0-9.]'), '');
    priceTo = (to == null || to.isEmpty) ? null : to.replaceAll(RegExp(r'[^0-9.]'), '');
    _performLocalFilter();
  }

  /// Clear price filters
  void clearPriceFilters() {
    priceFrom = null;
    priceTo = null;
    _performLocalFilter();
  }

  /// Apply all local filters on stored data
  void _performLocalFilter() {
    List<RealEstateAdModel> filteredList = List.from(_allFetchedAds);
    
    // Apply price filter
    filteredList = _applyPriceFilter(filteredList);
    
    // Apply keyword filter (case-insensitive, contains in title/description)
    if (_keyword != null && _keyword!.isNotEmpty) {
      final kw = _keyword!.trim().toLowerCase();
      filteredList = filteredList.where((ad) {
        final title = ad.title.trim().toLowerCase();
        final desc = (ad.description ?? '').trim().toLowerCase();
        return title.contains(kw) || desc.contains(kw);
      }).toList();
    }
    
    _ads = filteredList;
    notifyListeners();
  }

  /// Update keyword and apply filter locally
  void updateKeyword(String? value) {
    _keyword = (value ?? '').trim().isEmpty ? null : value!.trim();
    _performLocalFilter();
  }

  Future<bool> submitRealEstateAd(Map<String, dynamic> adData) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token not found');

      final response = await _repository.createRealEstateAd(token: token, adData: adData);

      bool success = false;
      String? apiMessage;
      if (response is Map<String, dynamic>) {
        success = response['success'] == true || response.containsKey('id');
        apiMessage = response['message']?.toString();
      } else {
        // If backend returns non-Map but did not throw, assume success
        success = true;
      }

      _isSubmitting = false;
      notifyListeners();
      if (success) {
        return true;
      } else {
        _error = apiMessage ?? 'فشل إنشاء إعلان العقارات';
        return false;
      }
    } catch(e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }


}