// lib/presentation/providers/real_estate_info_provider.dart
import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/repository/real_estate_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/real_estate_options_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';

class RealEstateInfoProvider extends ChangeNotifier {
  final RealEstateRepository _repository;
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RealEstateInfoProvider()
      : _repository = RealEstateRepository(ApiService()),
        _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EmirateModel> _emirates = [];
  List<String> _propertyTypes = [];
  List<String> _contractTypes = [];

  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];

  // Best advertisers properties
  List<BestAdvertiser> _bestAdvertisers = [];
  bool _isLoadingBestAdvertisers = false;
  String? _bestAdvertisersError;
  bool _hasAttemptedBestAdvertisers =
      false; // Track if we've already tried to fetch

  List<String> get emirateDisplayNames => _emirates.map((e) => e.name).toList();

  // إرجاع البيانات الحقيقية من الـ API فقط
  List<String> get propertyTypes => _propertyTypes;
  List<String> get contractTypes => _contractTypes;
  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get whatsappNumbers => _whatsappNumbers;

  // Best advertisers getters
  List<BestAdvertiser> get bestAdvertisers => _bestAdvertisers;
  bool get isLoadingBestAdvertisers => _isLoadingBestAdvertisers;
  String? get bestAdvertisersError => _bestAdvertisersError;

  List<String> getDistrictsForEmirate(String? emirateDisplayName) {
    if (emirateDisplayName == null) return [];
    try {
      return _emirates
          .firstWhere((e) => e.name == emirateDisplayName)
          .districts;
    } catch (e) {
      return [];
    }
  }

  Future<void> fetchAllData({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        _repository.getEmirates(),
        _repository.getRealEstateOptions(),
        fetchContactInfo(),
        fetchBestAdvertisers(),
      ]).then((results) {
        _emirates = results[0] as List<EmirateModel>;
        final options = results[1] as RealEstateOptions;
        _propertyTypes = options.propertyTypes;
        _contractTypes = options.contractTypes;
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchContactInfo({String? token}) async {
    try {
      final authToken = token ?? await _storage.read(key: 'auth_token');
      final response =
          await _apiService.get('/api/contact-info', token: authToken);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        _advertiserNames = data['advertiser_names'] != null
            ? List<String>.from(data['advertiser_names'])
            : [];
        _phoneNumbers = data['phone_numbers'] != null
            ? List<String>.from(data['phone_numbers'])
            : [];
        _whatsappNumbers = data['whatsapp_numbers'] != null
            ? List<String>.from(data['whatsapp_numbers'])
            : [];
      }
    } catch (e) {
      print("Could not fetch contact info: $e");
    }
  }

  Future<bool> addContactItem(String field, String value,
      {required String token}) async {
    try {
      final response = await _apiService.post('/api/contact-info/add-item',
          data: {'field': field, 'value': value}, token: token);
      if (response['success'] == true) {
        await fetchContactInfo(token: token);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  String? getEmirateNameFromDisplayName(String? displayName) {
    if (displayName == null) return null;
    try {
      return _emirates.firstWhere((e) => e.name == displayName).name;
    } catch (e) {
      return null;
    }
  }

  // Fetch best advertisers for real estate category
  Future<void> fetchBestAdvertisers(
      {String? token, bool forceRefresh = false}) async {
    // Prevent repeated calls unless forced refresh
    if (_hasAttemptedBestAdvertisers && !forceRefresh) {
      return;
    }

    _isLoadingBestAdvertisers = true;
    _bestAdvertisersError = null;
    _hasAttemptedBestAdvertisers = true;
    notifyListeners();

    try {
      print(
          '🔍 Fetching best advertisers from: /api/best-advertisers/real-estate');
      final response =
          await _apiService.get('/api/best-advertisers/real-estate');

      print('📥 API Response type: ${response.runtimeType}');
      print('📥 API Response: $response');

      if (response is List) {
        print('📋 Response is List with ${response.length} items');

        _bestAdvertisers = response
            .map((json) {
              print(
                  '🏢 Processing advertiser: ${json['advertiser_name']} (ID: ${json['id']})');
              print(
                  '📊 Latest ads count: ${(json['latest_ads'] as List?)?.length ?? 0}');
              print('🏷️ Advertiser category: ${json['category']}');

              return BestAdvertiser(
                id: json['id'] ?? 0,
                name: json['advertiser_name'] ?? 'Unknown Advertiser',
                ads: (json['latest_ads'] as List? ?? []).map((adJson) {
                  print(
                      '🏠 Processing ad: ${adJson['title']} - ${adJson['price']}');

                  // إضافة category من المستوى الأعلى إذا لم تكن موجودة في الإعلان
                  Map<String, dynamic> adWithCategory =
                      Map<String, dynamic>.from(adJson);
                  if (adWithCategory['category'] == null &&
                      json['category'] != null) {
                    adWithCategory['category'] = json['category'];
                    print('🏷️ Added category to ad: ${json['category']}');
                  }

                  return BestAdvertiserAd.fromJson(
                    adWithCategory,
                    advertiserId: json['id'] ?? 0,
                    advertiserName:
                        json['advertiser_name'] ?? 'Unknown Advertiser',
                  );
                }).toList(),
              );
            })
            .where((advertiser) => advertiser.ads.isNotEmpty)
            .toList();

        print('✅ Successfully parsed ${_bestAdvertisers.length} advertisers');
        for (var advertiser in _bestAdvertisers) {
          print('   - ${advertiser.name}: ${advertiser.ads.length} ads');
        }
      } else {
        print('❌ Unexpected response format: ${response.runtimeType}');
        _bestAdvertisersError = 'Unexpected response format';
      }
    } catch (e) {
      print('❌ Error fetching best advertisers: $e');
      _bestAdvertisersError = e.toString();

      // Fallback: Create dummy data when API fails
      _bestAdvertisers = [
        BestAdvertiser(
          id: 1,
          name: 'Premium Real Estate',
          ads: [
            BestAdvertiserAd(
              'Villa',
              'Sale',
              null,
              null,
              id: 1,
              make: 'Villa',
              model: 'Luxury',
              year: '2024',
              km: 'N/A',
              price: 'AED 2,500,000',
              mainImage: 'assets/images/house.png',
              advertiserName: 'Premium Real Estate',
              title: 'Luxury Villa in Dubai Marina',
              emirate: 'Dubai',
              area: 'Dubai Marina',
              category: 'real-estate',
            ),
            BestAdvertiserAd(
              'Apartment',
              'Sale',
              null,
              null,
              id: 2,
              make: 'Apartment',
              model: 'Modern',
              year: '2023',
              km: 'N/A',
              price: 'AED 1,200,000',
              mainImage: 'assets/images/house.png',
              advertiserName: 'Premium Real Estate',
              title: 'Modern Apartment in JBR',
              emirate: 'Dubai',
              area: 'JBR',
              category: 'real-estate',
            ),
          ],
        ),
        BestAdvertiser(
          id: 2,
          name: 'Elite Properties',
          ads: [
            BestAdvertiserAd(
              'Penthouse',
              'Sale',
              null,
              null,
              id: 3,
              make: 'Penthouse',
              model: 'Exclusive',
              year: '2024',
              km: 'N/A',
              price: 'AED 5,000,000',
              mainImage: 'assets/images/vila.png',
              advertiserName: 'Elite Properties',
              title: 'Exclusive Penthouse in Downtown',
              emirate: 'Dubai',
              area: 'Downtown Dubai',
              category: 'real-estate',
            ),
          ],
        ),
      ];
    } finally {
      _isLoadingBestAdvertisers = false;
      notifyListeners();
    }
  }
}
