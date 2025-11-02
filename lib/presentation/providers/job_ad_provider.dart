// lib/presentation/providers/job_ad_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/job_ad_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/repository/jobs_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class JobAdProvider extends ChangeNotifier {
  final JobsRepository _repository;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  JobAdProvider() : _repository = JobsRepository(ApiService());

  List<JobAdModel> _ads = [];
  List<JobAdModel> _allFetchedAds = []; // Store all fetched ads for local filtering
  bool _isLoading = false;
  String? _error;
  int _totalAds = 0;
  
  // Local filter state
  List<String> _selectedCategories = [];
  List<String> _selectedSections = [];

  // Best advertisers state
  List<BestAdvertiser> _bestAdvertisers = [];
  bool _isBestAdvertisersLoading = false;
  String? _bestAdvertisersError;

  // Category types and emirates state
  List<String> _categoryTypes = [];
  List<EmirateModel> _emirates = [];
  bool _isCategoryTypesLoading = false;
  bool _isEmiratesLoading = false;
  String? _categoryTypesError;
  String? _emiratesError;

  // Single-select filters for Job screen
  String? _selectedEmirateName;
  String? _selectedCategoryTypeName;

  List<JobAdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalAds => _totalAds;

  List<BestAdvertiser> get bestAdvertisers => _bestAdvertisers;
  bool get isBestAdvertisersLoading => _isBestAdvertisersLoading;
  String? get bestAdvertisersError => _bestAdvertisersError;

  // Getters for category types and emirates
  List<String> get categoryTypes => _categoryTypes;
  List<EmirateModel> get emirates => _emirates;
  List<String> get emirateNames => _emirates.map((e) => e.name).toList();
  bool get isCategoryTypesLoading => _isCategoryTypesLoading;
  bool get isEmiratesLoading => _isEmiratesLoading;
  String? get categoryTypesError => _categoryTypesError;
  String? get emiratesError => _emiratesError;
  String? get selectedEmirateName => _selectedEmirateName;
  String? get selectedCategoryTypeName => _selectedCategoryTypeName;

  Map<String, String> _categoryImages = {};

  Map<String, String> get categoryImages => _categoryImages;

  

  Future<void> fetchAds({Map<String, dynamic>? filters, String? emirate, String? categoryType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Public data - no token required for browsing job ads
      // بناء الفلاتر النهائية
      Map<String, dynamic> finalFilters = {};
      if (filters != null) {
        finalFilters.addAll(filters);
      }
      
      // إضافة فلاتر الإمارة ونوع الفئة
      // استخدم القيم المختارة مسبقًا إذا لم تُمرر في الاستدعاء
      final String? effectiveEmirate = emirate ?? _selectedEmirateName;
      final String? effectiveCategoryType = categoryType ?? _selectedCategoryTypeName;

      if (effectiveEmirate != null && effectiveEmirate.isNotEmpty && effectiveEmirate != 'All') {
        finalFilters['emirate'] = effectiveEmirate;
      }
      
      if (effectiveCategoryType != null && effectiveCategoryType.isNotEmpty && effectiveCategoryType != 'All') {
        finalFilters['category_type'] = effectiveCategoryType;
      }

      // ++ جلب صور الفئات بالتوازي مع الإعلانات ++
      final results = await Future.wait([
        _repository.getJobAds(query: finalFilters),
        _repository.getJobCategoryImages(),
      ]);

      final adResponse = results[0] as JobAdResponse;
      _allFetchedAds = adResponse.ads; // Store all ads
      _totalAds = adResponse.total;

      _categoryImages = results[1] as Map<String, String>;
      
      // Apply local filters
      _performLocalFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBestAdvertisers() async {
    _isBestAdvertisersLoading = true;
    _bestAdvertisersError = null;
    notifyListeners();

    try {
      // إزالة الاعتماد على التوكن في طلبات GET لأفضل المعلنين
      _bestAdvertisers = await _repository.getBestAdvertisers();
    } catch (e) {
      _bestAdvertisersError = e.toString();
    } finally {
      _isBestAdvertisersLoading = false;
      notifyListeners();
    }
  }

  // Fetch category types from API
  Future<void> fetchCategoryTypes() async {
    _isCategoryTypesLoading = true;
    _categoryTypesError = null;
    notifyListeners();

    try {
      print('🔍 Fetching category types from /api/jobs_ad_values');
      final responseData = await _apiService.get('/api/jobs_ad_values');

      print('📦 Response data: $responseData');

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success') &&
          responseData['success'] == true &&
          responseData.containsKey('data')) {
        final data = responseData['data'];
        print('📋 Data array: $data');

        if (data is List) {
          // Find the category_type field in the data array
          for (var item in data) {
            if (item is Map<String, dynamic> &&
                item['field_name'] == 'category_type' &&
                item.containsKey('options')) {
              final options = item['options'];
              if (options is List) {
                _categoryTypes =
                    options.map((option) => option.toString()).toList();
                print('✅ Category types loaded: $_categoryTypes');
                break;
              }
            }
          }

          if (_categoryTypes.isEmpty) {
            print('⚠️ No category_type field found in data array');
          }
        } else {
          throw Exception('Unexpected data format - expected array');
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('❌ Error fetching category types: $e');
      _categoryTypesError = e.toString();
    } finally {
      _isCategoryTypesLoading = false;
      notifyListeners();
    }
  }

  // Fetch emirates from API
  Future<void> fetchEmirates() async {
    _isEmiratesLoading = true;
    _emiratesError = null;
    notifyListeners();

    try {
      print('🔍 Fetching emirates from /api/locations/emirates');
      final responseData = await _apiService.get('/api/locations/emirates');

      print('📦 Emirates response data: $responseData');

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('emirates')) {
        final emiratesData = responseData['emirates'];
        print('🏙️ Emirates data: $emiratesData');

        if (emiratesData is List) {
          _emirates =
              emiratesData.map((item) => EmirateModel.fromJson(item)).toList();
          print('✅ Emirates loaded: ${_emirates.map((e) => e.name).toList()}');
        } else {
          throw Exception('Unexpected emirates data format - expected array');
        }
      } else {
        throw Exception('Emirates data not found in response');
      }
    } catch (e) {
      print('❌ Error fetching emirates: $e');
      _emiratesError = e.toString();
    } finally {
      _isEmiratesLoading = false;
      notifyListeners();
    }
  }

  // Fetch all data needed for job screen
  Future<void> fetchAllJobScreenData() async {
    await Future.wait([
      fetchCategoryTypes(),
      fetchEmirates(),
    ]);
  }

  // Submit job ad state
  bool _isSubmittingAd = false;
  String? _submitAdError;

  bool get isSubmittingAd => _isSubmittingAd;
  String? get submitAdError => _submitAdError;

  /// Submit job ad to API
  Future<bool> submitJobAd(Map<String, dynamic> adData) async {
    print('=== Job Ad Submission Started ===');
    _isSubmittingAd = true;
    _submitAdError = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _submitAdError = 'Authentication token not found';
        print('❌ No auth token found');
        return false;
      }

      print('✅ Auth token found');

      // Prepare submission data
      final submissionData = {
        'job_name': adData['jobName']?.toString() ?? '',
        'title': adData['title']?.toString() ?? '',
        'description': adData['description']?.toString() ?? '',
        'emirate': adData['emirate']?.toString() ?? '',
        'district': adData['district']?.toString() ?? '',
        'category_type': adData['categoryType']?.toString() ?? '',
        'section_type': adData['sectionType']?.toString() ?? '',
        'salary': adData['salary']?.toString() ?? '',
        'advertiser_name': adData['advertiserName']?.toString() ?? '',
        'phone_number': adData['contactDetails']?.toString() ?? '',
        'contact_info': adData['contactDetails']?.toString() ?? '',
        'address': adData['location']?.toString() ?? '',
        'whatsapp': adData['whatsapp']?.toString() ?? '',
        'location': adData['location']?.toString() ?? '',
        'latitude': adData['latitude']?.toString() ?? '',
        'longitude': adData['longitude']?.toString() ?? '',
        // Plan data
        'plan_type': adData['planType']?.toString() ?? 'free',
        'plan_days': adData['planDays']?.toString() ?? '7',
        'plan_expires_at': adData['planExpiresAt']?.toString() ?? '',
      };

      // Include payment only when set during payment step
      if (adData['payment'] != null) {
        submissionData['payment'] = adData['payment'].toString();
      }

      print('=== Job Ad Submission Data ===');
      submissionData.forEach((key, value) {
        print('$key: "$value"');
      });

      // Check for required fields
      List<String> missingFields = [];
      List<String> requiredFields = [
        'job_name',
        'description',
        'emirate',
        'category_type',
        'salary',
        'advertiser_name'
      ];

      for (String field in requiredFields) {
        if (submissionData[field] == null || submissionData[field]!.isEmpty) {
          missingFields.add(field);
        }
      }

      if (missingFields.isNotEmpty) {
        _submitAdError = 'Missing required fields: ${missingFields.join(', ')}';
        print('❌ Missing required fields: $missingFields');
        return false;
      }

      print('✅ All required fields are present');
      print('🚀 Sending request to /api/jobs...');

      final response = await _apiService.post(
        '/api/jobs',
        data: submissionData,
        token: token,
      );

      print('=== API RESPONSE RECEIVED ===');
      print('Response Type: ${response.runtimeType}');
      print('Response Content: $response');

      if (response is Map<String, dynamic>) {
        // Check if response contains an 'id' field (indicating successful creation)
        // or if it has a 'success' field set to true
        if (response.containsKey('id') || response['success'] == true) {
          print('✅ Job ad submitted successfully');
          return true;
        } else {
          _submitAdError = response['message'] ?? 'Failed to submit job ad';
          print('❌ Failed to submit job ad: $_submitAdError');
          return false;
        }
      } else {
        print('✅ Job ad submitted successfully (non-map response)');
        return true;
      }
    } catch (e, stackTrace) {
      _submitAdError = e.toString();
      print('❌ Exception submitting job ad: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isSubmittingAd = false;
      notifyListeners();
    }
  }

  // Local filtering methods
  void _performLocalFilter() {
    List<JobAdModel> filteredAds = List.from(_allFetchedAds);

    // Filter by selected categories
    if (_selectedCategories.isNotEmpty) {
      filteredAds = filteredAds.where((ad) {
        return _selectedCategories.contains(ad.categoryType);
      }).toList();
    }

    // Filter by selected sections
    if (_selectedSections.isNotEmpty) {
      filteredAds = filteredAds.where((ad) {
        return _selectedSections.contains(ad.sectionType);
      }).toList();
    }

    _ads = filteredAds;
    notifyListeners();
  }

  // Update selected categories filter
  void updateSelectedCategories(List<String> categories) {
    _selectedCategories = categories;
    _performLocalFilter();
  }

  // Update selected sections filter
  void updateSelectedSections(List<String> sections) {
    _selectedSections = sections;
    _performLocalFilter();
  }

  // --- تحديث الفلاتر الفردية لشاشة الوظائف ---
  void updateSelectedEmirate(String? selectedName) {
    _selectedEmirateName = selectedName;
    // لا نطبّق فلتر محلي هنا لأن الإمارة ونوع الفئة تُرسلان للـ API
    notifyListeners();
  }

  void updateSelectedCategoryType(String? selectedName) {
    _selectedCategoryTypeName = selectedName;
    notifyListeners();
  }

  // Clear all filters
  void clearAllFilters() {
    _selectedCategories.clear();
    _selectedSections.clear();
    _selectedEmirateName = null;
    _selectedCategoryTypeName = null;
    _performLocalFilter();
  }
}
