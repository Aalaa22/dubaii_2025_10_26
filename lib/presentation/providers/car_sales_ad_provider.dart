import 'dart:async';
import 'dart:io';
import 'package:advertising_app/data/model/car_ad_model.dart';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/repository/car_sales_ad_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CarAdProvider with ChangeNotifier {
  final CarAdRepository _carAdRepository;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  CarAdProvider(this._carAdRepository);

  // --- SECTION 1: Ad List State (for Search & Manage Screens) ---
  bool _isLoadingAds = false;
  String? _loadAdsError;
  List<CarAdModel> _carAds = [];
  List<CarAdModel> _ads = [];
  int _totalAds = 0;

  // --- SECTION 2: Submit Ad State ---
  bool _isSubmittingAd = false;
  String? _submitAdError;

  bool get isLoadingAds => _isLoadingAds;
  String? get loadAdsError => _loadAdsError;
  List<CarAdModel> get carAds => _carAds;
  List<CarAdModel> get ads => _ads;
  int get totalAds => _totalAds;
  bool get isSubmittingAd => _isSubmittingAd;
  String? get submitAdError => _submitAdError;

  // --- SECTION 2: Ad Details & Editing State ---
  CarAdModel? _adDetails;
  bool _isLoadingDetails = false;
  String? _detailsError;
  bool _isUpdatingAd = false;
  String? _updateAdError;

  CarAdModel? get adDetails => _adDetails;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get detailsError => _detailsError;
  bool get isUpdatingAd => _isUpdatingAd;
  String? get updateAdError => _updateAdError;

  // --- SECTION 3: Create Ad State ---
  bool _isCreatingAd = false;
  String? _createAdError;
  bool get isCreatingAd => _isCreatingAd;
  String? get createAdError => _createAdError;

  // --- SECTION 4: Filter Options State ---
  List<MakeModel> _makes = [];
  List<CarModel> _models = [];
  List<TrimModel> _trims = [];
  bool _isLoadingMakes = false;
  bool _isLoadingModels = false;
  bool _isLoadingTrims = false;

  List<MakeModel> get makes {
    if (_makes.isEmpty) return [];
    return [
      MakeModel(id: -1, name: "All"),
      ..._makes,
      MakeModel(id: -2, name: "Other")
    ];
  }

  List<CarModel> get models => _models;
  List<TrimModel> get trims => _trims;
  bool get isLoadingMakes => _isLoadingMakes;
  bool get isLoadingModels => _isLoadingModels;
  bool get isLoadingTrims => _isLoadingTrims;

  // Download an image URL/path to a temporary file for multipart upload
  Future<File?> _downloadImageToTempFile(String url) async {
    try {
      final String fullUrl = ImageUrlHelper.getFullImageUrl(url);
      final dio = Dio();
      final response = await dio.get(fullUrl, options: Options(responseType: ResponseType.bytes));
      final List<int> bytes = (response.data as List<int>);
      final tempDir = await getTemporaryDirectory();
      final filename = p.basename(Uri.parse(fullUrl).path);
      final file = File(p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_$filename'));
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Failed to download image "$url" to temp file: $e');
      return null;
    }
  }

  // --- SECTION 5: Selected Filters State ---
  MakeModel? _selectedMake;
  CarModel? _selectedModel;
  List<TrimModel> _selectedTrims = [];
  List<MakeModel> _selectedMakes = [];
  List<CarModel> _selectedModels = [];
  List<String> _selectedYears = [];
  List<String> _years = [];
  String? yearFrom, yearTo, kmFrom, kmTo, priceFrom, priceTo;

  MakeModel? get selectedMake => _selectedMake;
  CarModel? get selectedModel => _selectedModel;
  List<TrimModel> get selectedTrims => _selectedTrims;
  List<MakeModel> get selectedMakes => _selectedMakes;
  List<CarModel> get selectedModels => _selectedModels;
  List<String> get selectedYears => _selectedYears;
  List<String> get years => _years.isEmpty
      ? [
          '2024',
          '2023',
          '2022',
          '2021',
          '2020',
          '2019',
          '2018',
          '2017',
          '2016',
          '2015'
        ]
      : _years;

  List<BestAdvertiser> _topDealerAds = [];
  bool _isLoadingTopDealers = false;
  String? _topDealersError;

  List<BestAdvertiser> get topDealerAds => _topDealerAds;
  bool get isLoadingTopDealers => _isLoadingTopDealers;
  String? get topDealersError => _topDealersError;

  bool _disposed = false;

  // Debouncing for search
  Timer? _searchDebounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  // Performance optimization
  bool _isInitialized = false;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _disposed = true;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // تحديث قائمة الإعلانات (للترتيب حسب الموقع)
  void updateCarAds(List<CarAdModel> sortedAds) {
    _carAds = sortedAds;
    safeNotifyListeners();
  }

  // Reset all states
  void resetAllStates() {
    _searchDebounceTimer?.cancel();
    _isLoadingAds = false;
    _loadAdsError = null;
    _carAds.clear();
    _allFetchedAds.clear();
    _totalAds = 0;
    _isInitialized = false;
    safeNotifyListeners();
  }

  // Check if provider is ready
  bool get isInitialized => _isInitialized;

  // Batch update for better performance
  void batchUpdate(Function() updates) {
    updates();
    safeNotifyListeners();
  }

  // --- All Functions ---

  /// The main function to fetch ads.
  // Debounced search function
  void debouncedFetchCarAds({Map<String, String>? filters}) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_debounceDelay, () {
      fetchCarAds(filters: filters);
    });
  }

  Future<void> fetchCarAds({Map<String, String>? filters}) async {
    // Prevent multiple simultaneous requests
    if (_isLoadingAds) return;

    _isLoadingAds = true;
    _loadAdsError = null;
    safeNotifyListeners();

    try {
      // Public data - no token required for browsing ads
      final queryParameters = filters ?? {};
      if (kDebugMode) print("==> FINAL QUERY TO API: $queryParameters");

      final response = await _carAdRepository.getCarAds(query: queryParameters);

      // Only update if not disposed
      if (!_disposed) {
        _allFetchedAds =
            response.ads; // Store all fetched ads for local filtering
        _totalAds = response.totalAds;

        // Apply local filters on the fetched data
        _performLocalFilter();
        _isInitialized = true;
      }
    } catch (e) {
      if (!_disposed) {
        _loadAdsError = e.toString();
        _carAds = [];
        _allFetchedAds = [];
        if (kDebugMode) print("Error fetching car ads: $e");
      }
    } finally {
      if (!_disposed) {
        _isLoadingAds = false;
        safeNotifyListeners();
      }
    }
  }

  // Store all fetched ads for local filtering
  List<CarAdModel> _allFetchedAds = [];

  /// Gathers all filters and triggers the fetch.
  Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
    Map<String, String> finalFilters = {};

    if (initialFilters != null) {
      finalFilters.addAll(initialFilters);

      final makeName = initialFilters['make'];
      if (makeName != null &&
          !_makes.any((m) => m.name == makeName) &&
          makes.any((m) => m.name == makeName)) {
        updateSelectedMake(makes.firstWhere((m) => m.name == makeName));
      }

      final modelName = initialFilters['model'];
      if (modelName != null &&
          !_models.any((m) => m.name == modelName) &&
          models.any((m) => m.name == modelName)) {
        updateSelectedModel(models.firstWhere((m) => m.name == modelName));
      }
    }

    // Only include API filters for make, model, and trim - year, km, price will be filtered locally
    if (_selectedMake != null) {
      if (_selectedMake!.id == -2) {
        // Other
        finalFilters['make'] = "Other";
      } else if (_selectedMake!.id > 0) {
        // Real Make
        finalFilters['make'] = _selectedMake!.name;
      }
      // If "All" is selected (id: -1), we don't add any 'make' filter
    }
    if (_selectedModel != null) {
      if (_selectedModel!.id == -2) {
        // Other
        finalFilters['model'] = "Other";
      } else if (_selectedModel!.id > 0) {
        // Real Model
        finalFilters['model'] = _selectedModel!.name;
      }
      // If "All" is selected (id: -1), we don't add any 'model' filter
    }
    if (_selectedTrims.isNotEmpty)
      finalFilters['trim'] = _selectedTrims.map((e) => e.name).join(',');

    await fetchCarAds(filters: finalFilters);
  }

  void _performLocalFilter() {
    List<CarAdModel> filteredList = List.from(_allFetchedAds);

    // Filter by Year
    final fromYear = int.tryParse(yearFrom ?? '');
    final toYear = int.tryParse(yearTo ?? '');
    if (fromYear != null)
      filteredList
          .retainWhere((ad) => (int.tryParse(ad.year) ?? 0) >= fromYear);
    if (toYear != null)
      filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) <= toYear);

    // Filter by Km
    final fromKm = int.tryParse(kmFrom?.replaceAll(',', '') ?? '');
    final toKm = int.tryParse(kmTo?.replaceAll(',', '') ?? '');
    if (fromKm != null)
      filteredList.retainWhere(
          (ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) >= fromKm);
    if (toKm != null)
      filteredList.retainWhere(
          (ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) <= toKm);

    // Filter by Price
    final fromPrice = double.tryParse(priceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(priceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null)
      filteredList.retainWhere((ad) =>
          (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) >= fromPrice);
    if (toPrice != null)
      filteredList.retainWhere((ad) =>
          (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) <= toPrice);

    // Filter by Trim - إضافة فلتر الـ trim للاختيارات المتعددة
    if (_selectedTrims.isNotEmpty) {
      final selectedTrimNames =
          _selectedTrims.map((trim) => trim.name.toLowerCase()).toSet();
      filteredList.retainWhere((ad) {
        if (ad.trim == null || ad.trim!.isEmpty) return false;
        return selectedTrimNames.contains(ad.trim!.toLowerCase());
      });
    }

    _carAds = filteredList;
    safeNotifyListeners();
  }

  // --- Functions to UPDATE filters & Trigger Local Filtering ---
  void updateYearRange(String? from, String? to) {
    yearFrom = from;
    yearTo = to;
    _performLocalFilter();
  }

  void updateKmRange(String? from, String? to) {
    kmFrom = from;
    kmTo = to;
    _performLocalFilter();
  }

  void updatePriceRange(String? from, String? to) {
    priceFrom = from;
    priceTo = to;
    _performLocalFilter();
  }

  void updateSelectedTrims(List<TrimModel> selection) {
    _selectedTrims = selection;
    _performLocalFilter(); // تطبيق الفلترة المحلية بدلاً من استدعاء API
  }

  void updateSelectedModel(CarModel? selection) {
    _selectedModel = selection;
    _selectedTrims.clear();
    _trims.clear();
    if (_selectedModel != null) {
      fetchTrimsForModel(_selectedModel!);
    }
    applyAndFetchAds();
    safeNotifyListeners();
  }

  void updateSelectedMake(MakeModel? selection) {
    _selectedMake = selection;
    _selectedModel = null;
    _selectedTrims.clear();
    _models.clear();
    _trims.clear();
    if (_selectedMake != null && _selectedMake!.id > 0) {
      fetchModelsForMake(_selectedMake!);
    } else if (_selectedMake != null && _selectedMake!.id == -1) {
      // When "All" is selected, fetch all models
      fetchAllModels();
    } else {
      applyAndFetchAds();
    }
    safeNotifyListeners();
  }

  void updateSelectedMakes(List<MakeModel> selection) {
    _selectedMakes = selection;
    _selectedModels.clear();
    _selectedTrims.clear();
    _models.clear();
    _trims.clear();
    if (_selectedMakes.length == 1) {
      fetchModelsForMake(_selectedMakes.first);
    } else {
      applyAndFetchAds();
    }
    safeNotifyListeners();
  }

  void updateSelectedModels(List<CarModel> selection) {
    _selectedModels = selection;
    _selectedTrims.clear();
    _trims.clear();
    if (_selectedModels.length == 1) {
      fetchTrimsForModel(_selectedModels.first);
    } else {
      applyAndFetchAds();
    }
    safeNotifyListeners();
  }

  void updateSelectedYears(List<String> selection) {
    _selectedYears = selection;
    applyAndFetchAds();
    safeNotifyListeners();
  }

  // دالة لمسح جميع الفلاتر
  void clearAllFilters() {
    _selectedMake = null;
    _selectedModel = null;
    _selectedTrims.clear();
    _selectedMakes.clear();
    _selectedModels.clear();
    _selectedYears.clear();
    _models.clear();
    _trims.clear();
    yearFrom = null;
    yearTo = null;
    kmFrom = null;
    kmTo = null;
    priceFrom = null;
    priceTo = null;
    safeNotifyListeners();
  }

  // --- Other Functions ---
  Future<void> fetchAdDetails(int adId) async {
    // Prevent multiple simultaneous requests for the same ad
    if (_isLoadingDetails) return;

    _isLoadingDetails = true;
    _detailsError = null;
    _adDetails = null;
    safeNotifyListeners();

    try {
      // Public data - no token required for viewing ad details
      final details = await _carAdRepository.getCarAdDetails(adId: adId);

      // Only update if not disposed
      if (!_disposed) {
        _adDetails = details;
      }
    } catch (e) {
      if (!_disposed) {
        _detailsError = e.toString();
        if (kDebugMode) print("Error fetching ad details: $e");
      }
    } finally {
      if (!_disposed) {
        _isLoadingDetails = false;
        safeNotifyListeners();
      }
    }
  }

  Future<void> fetchMakes() async {
    // Return early if already loaded or currently loading
    if (_makes.isNotEmpty || _isLoadingMakes) return;

    _isLoadingMakes = true;
    safeNotifyListeners();

    try {
      // Public data - no token required
      final makes = await _carAdRepository.getMakes();

      // Only update if not disposed
      if (!_disposed) {
        _makes = makes;
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching makes: $e");
    } finally {
      if (!_disposed) {
        _isLoadingMakes = false;
        safeNotifyListeners();
      }
    }
  }

  Future<void> fetchModelsForMake(MakeModel make) async {
    _isLoadingModels = true;
    _models.clear();
    safeNotifyListeners();
    try {
      // Public data - no token required
      _models = await _carAdRepository.getModels(makeId: make.id);
    } catch (e) {
      if (kDebugMode) print("Error fetching models: $e");
    } finally {
      _isLoadingModels = false;
      safeNotifyListeners();
    }
  }

  Future<void> fetchAllModels() async {
    _isLoadingModels = true;
    _models.clear();
    safeNotifyListeners();
    try {
      // Public data - no token required
      _models = await _carAdRepository.getAllModels();
    } catch (e) {
      if (kDebugMode) print("Error fetching all models: $e");
    } finally {
      _isLoadingModels = false;
      safeNotifyListeners();
    }
  }

  Future<void> fetchTrimsForModel(CarModel model) async {
    _isLoadingTrims = true;
    _trims.clear();
    safeNotifyListeners();
    try {
      // Public data - no token required
      _trims = await _carAdRepository.getTrims(modelId: model.id);
    } catch (e) {
      if (kDebugMode) print("Error fetching trims: $e");
    } finally {
      _isLoadingTrims = false;
      safeNotifyListeners();
    }
  }

  Future<bool> updateAd(String adId, Map<String, dynamic> adData) async {
    _isUpdatingAd = true;
    _updateAdError = null;
    safeNotifyListeners();

    try {
      final token = await FlutterSecureStorage().read(key: 'auth_token');
      final CarAdModel? before = _adDetails;

      // Handle main image - check both possible key names
      File? mainImageFile;
      if (adData['mainImage'] is File) {
        mainImageFile = adData['mainImage'] as File;
      } else if (adData['main_image'] is File) {
        mainImageFile = adData['main_image'] as File;
      } else if (adData['main_image'] is String && (adData['main_image'] as String).trim().isNotEmpty) {
        mainImageFile = await _downloadImageToTempFile(adData['main_image'] as String);
      }

      // Handle thumbnail images - check both possible key names
      List<File>? thumbnailImages;
      final thumbsData = adData['thumbnailImages'] ?? adData['thumbnail_images'];
      if (thumbsData is List) {
        final List<File> files = [];
        
        for (final thumb in thumbsData) {
          if (thumb is File) {
            files.add(thumb);
          }
        }
        
        if (files.isNotEmpty) {
          thumbnailImages = files;
        }
      }

      // Include existing thumbnail URLs by downloading them into files
      if (adData['existing_thumbnail_images'] is List) {
        final urls = (adData['existing_thumbnail_images'] as List)
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .toList();
        if (urls.isNotEmpty) {
          thumbnailImages ??= [];
          for (final url in urls) {
            final file = await _downloadImageToTempFile(url);
            if (file != null) {
              thumbnailImages.add(file);
            } else {
              debugPrint('Skipping existing thumbnail "$url" due to download failure');
            }
          }
        }
      }

      // Build form data payload with all fields
      final Map<String, dynamic> formData = {
        '_method': 'PUT', // Required for Laravel method spoofing
        
        // Basic fields
        if (adData['title'] != null) 'title': adData['title'].toString(),
        if (adData['description'] != null) 'description': adData['description'].toString(),
        if (adData['make'] != null) 'make': adData['make'].toString(),
        if (adData['model'] != null) 'model': adData['model'].toString(),
        if (adData['trim'] != null) 'trim': adData['trim'].toString(),
        if (adData['year'] != null) 'year': adData['year'].toString(),
        if (adData['km'] != null) 'km': adData['km'].toString(),
        if (adData['price'] != null) 'price': adData['price'].toString(),
        if (adData['specs'] != null) 'specs': adData['specs'].toString(),
        
        // Car details
        if (adData['car_type'] != null || adData['carType'] != null)
          'car_type': (adData['car_type'] ?? adData['carType']).toString(),
        if (adData['trans_type'] != null || adData['transType'] != null)
          'trans_type': (adData['trans_type'] ?? adData['transType']).toString(),
        if (adData['fuel_type'] != null || adData['fuelType'] != null)
          'fuel_type': (adData['fuel_type'] ?? adData['fuelType']).toString(),
        if (adData['color'] != null) 'color': adData['color'].toString(),
        if (adData['interior_color'] != null || adData['interiorColor'] != null)
          'interior_color': (adData['interior_color'] ?? adData['interiorColor']).toString(),
        if (adData['warranty'] != null) 'warranty': adData['warranty'].toString(),
        if (adData['engine_capacity'] != null || adData['engineCapacity'] != null)
          'engine_capacity': (adData['engine_capacity'] ?? adData['engineCapacity']).toString(),
        if (adData['cylinders'] != null) 'cylinders': adData['cylinders'].toString(),
        if (adData['horsepower'] != null) 'horsepower': adData['horsepower'].toString(),
        if (adData['doors_no'] != null || adData['doorsNo'] != null)
          'doors_no': (adData['doors_no'] ?? adData['doorsNo']).toString(),
        if (adData['seats_no'] != null || adData['seatsNo'] != null)
          'seats_no': (adData['seats_no'] ?? adData['seatsNo']).toString(),
        if (adData['steering_side'] != null || adData['steeringSide'] != null)
          'steering_side': (adData['steering_side'] ?? adData['steeringSide']).toString(),
        
        // Contact information
        if (adData['advertiser_name'] != null || adData['advertiserName'] != null)
          'advertiser_name': (adData['advertiser_name'] ?? adData['advertiserName']).toString(),
        if (adData['phone_number'] != null || adData['phoneNumber'] != null)
          'phone_number': (adData['phone_number'] ?? adData['phoneNumber']).toString(),
        if (adData['whatsapp'] != null) 'whatsapp': adData['whatsapp'].toString(),
        
        // Location
        if (adData['emirate'] != null) 'emirate': adData['emirate'].toString(),
        if (adData['selectedarea'] != null || adData['area'] != null)
          'area': (adData['selectedarea'] ?? adData['area']).toString(),
        if (adData['location'] != null || adData['advertiser_location'] != null || adData['advertiserLocation'] != null)
          'location': (adData['location'] ?? adData['advertiser_location'] ?? adData['advertiserLocation']).toString(),
        
        // Plan details
        if (adData['plan_type'] != null || adData['planType'] != null)
          'plan_type': (adData['plan_type'] ?? adData['planType']).toString(),
        if (adData['plan_days'] != null || adData['planDays'] != null)
          'plan_days': (adData['plan_days'] ?? adData['planDays']).toString(),
        if (adData['plan_expires_at'] != null || adData['planExpiresAt'] != null)
          'plan_expires_at': (adData['plan_expires_at'] ?? adData['planExpiresAt']).toString(),

      };

      print('=== CarAdProvider.updateAd: POST with form-data ===');
      print('Endpoint: /api/car-sales-ads/$adId');
      print('Method: POST with _method=PUT');
      print('Input data keys: ${adData.keys.toList()}');
      print('Main image file: ${mainImageFile != null} (from key: ${adData['mainImage'] != null ? 'mainImage' : adData['main_image'] != null ? 'main_image' : 'none'})');
      print('Thumbnail files count: ${thumbnailImages?.length ?? 0} (from key: ${adData['thumbnailImages'] != null ? 'thumbnailImages' : adData['thumbnail_images'] != null ? 'thumbnail_images' : 'none'})');
      final existingThumbsCount = (adData['existing_thumbnail_images'] is List)
          ? (adData['existing_thumbnail_images'] as List).whereType<String>().length
          : 0;
      if (existingThumbsCount > 0) {
        print('Existing thumbnail URLs provided: $existingThumbsCount (downloaded into files)');
      }
      print('Form fields: ${formData.keys.toList()}');
      print('===============================================');

      // Always use POST with form-data and _method=PUT
      final response = await _apiService.postFormData(
        '/api/car-sales-ads/$adId',
        data: formData,
        mainImage: mainImageFile,
        thumbnailImages: thumbnailImages,
        token: token,
      );

      // Consider success if API returns success flag or id
      final bool updated = (response is Map && (response['success'] == true || response.containsKey('id')));

      // Fetch latest details and verify expected changes applied
      await fetchAdDetails(int.tryParse(adId) ?? 0);
      final CarAdModel? after = _adDetails;

      List<String> unchangedFields = [];
      String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');
      bool equalsNormalized(String? a, String? b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        return a.trim() == b.trim();
      }

      if (after != null) {
        // Check price
        if (formData.containsKey('price')) {
          final beforePrice = before?.price;
          final afterPrice = after.price;
          if (digitsOnly(beforePrice ?? '') == digitsOnly(afterPrice)) {
            unchangedFields.add('price');
          }
        }
        
        // Check description
        if (formData.containsKey('description')) {
          final beforeDesc = before?.description;
          final afterDesc = after.description;
          if (!equalsNormalized(formData['description']?.toString(), afterDesc)) {
            unchangedFields.add('description');
          }
        }
        
        // Check phone number
        if (formData.containsKey('phone_number')) {
          final afterPhone = after.phoneNumber;
          if (!equalsNormalized(formData['phone_number']?.toString(), afterPhone)) {
            unchangedFields.add('phone_number');
          }
        }
        
        // Check WhatsApp
        if (formData.containsKey('whatsapp')) {
          final afterWa = after.whatsapp;
          if (!equalsNormalized(formData['whatsapp']?.toString(), afterWa)) {
            unchangedFields.add('whatsapp');
          }
        }
        
        // Check main image (if file was uploaded)
        if (mainImageFile != null) {
          if (before != null && before.mainImage.isNotEmpty && after.mainImage == before.mainImage) {
            unchangedFields.add('main_image');
          }
        }
        
        // Check thumbnail images (if files were uploaded)
        if (thumbnailImages != null && thumbnailImages.isNotEmpty) {
          final beforeThumbs = before?.thumbnailImages ?? [];
          final afterThumbs = after.thumbnailImages ?? [];
          if (beforeThumbs.length == afterThumbs.length && 
              beforeThumbs.every((thumb) => afterThumbs.contains(thumb))) {
            unchangedFields.add('thumbnail_images');
          }
        }
      }

      if (updated && unchangedFields.isEmpty) {
        await fetchCarAds();
        return true;
      }

      // Build error message
      final List<String> hints = [];
      hints.add('تأكد من أن جميع الحقول مرسلة بصيغة form-data مع _method=PUT');
      hints.add('تحقق من صحة أرقام الهاتف والواتساب');
      hints.add('تأكد من أن الصور بالصيغة المطلوبة');

      _updateAdError = 'الطلب ${updated ? 'مقبول' : 'مرفوض'} لكن لم تُحدّث الحقول: ${unchangedFields.join(', ')}. الأسباب المحتملة: ${hints.join(' | ')}';
      return false;
    } catch (e) {
      _updateAdError = e.toString();
      return false;
    } finally {
      _isUpdatingAd = false;
      safeNotifyListeners();
    }
  }

  Future<bool> submitCarAd(Map<String, dynamic> adData) async {
    _isSubmittingAd = true;
    _submitAdError = null;
    safeNotifyListeners();

    try {
      final token = await FlutterSecureStorage().read(key: 'auth_token');

      // Normalize and validate payload (camelCase -> snake_case, clean numeric fields)
      String? cleanEngineCapacity(dynamic v) {
        if (v == null) return null;
        final s = v.toString().replaceAll('L', '').trim();
        return s.isEmpty ? null : s;
      }
      String? digitsOnly(dynamic v) {
        if (v == null) return null;
        final m = RegExp(r'\d+').firstMatch(v.toString());
        return m?.group(0);
      }
      String? firstNumber(dynamic v) {
        if (v == null) return null;
        final s = v.toString();
        if (s.contains('-')) {
          final m = RegExp(r'\d+').firstMatch(s.split('-').first);
          return m?.group(0);
        }
        return RegExp(r'\d+').firstMatch(s)?.group(0);
      }
      String warrantyToApi(dynamic v) {
        return (v == true || (v is String && (v == 'true' || v == '1'))) ? '1' : '0';
      }

      final Map<String, String> camelToSnake = {
        'carType': 'car_type',
        'transType': 'trans_type',
        'fuelType': 'fuel_type',
        'interiorColor': 'interior_color',
        'engineCapacity': 'engine_capacity',
        'cylinders': 'cylinders',
        'horsepower': 'horsepower',
        'doorsNo': 'doors_no',
        'seatsNo': 'seats_no',
        'steeringSide': 'steering_side',
        'phoneNumber': 'phone_number',
        'advertiserName': 'advertiser_name',
        'advertiserType': 'advertiser_type',
        'planType': 'plan_type',
        'planDays': 'plan_days',
        'planExpiresAt': 'plan_expires_at',
        'advertiserLocation': 'location',
      };

      final Map<String, dynamic> textData = {
        'title': adData['title'],
        'description': adData['description'],
        'make': adData['make'],
        'model': adData['model'],
        'trim': adData['trim'],
        'year': adData['year'],
        'km': adData['km'],
        'price': adData['price'],
        'specs': adData['specs'],
        'car_type': adData['car_type'] ?? adData['carType'],
        'trans_type': adData['trans_type'] ?? adData['transType'],
        'fuel_type': adData['fuel_type'] ?? adData['fuelType'],
        'color': adData['color'],
        'interior_color': adData['interior_color'] ?? adData['interiorColor'],
        'warranty': warrantyToApi(adData['warranty']),
        'engine_capacity': cleanEngineCapacity(adData['engineCapacity']),
        'cylinders': digitsOnly(adData['cylinders']),
        'horsepower': firstNumber(adData['horsepower']),
        'doors_no': digitsOnly(adData['doorsNo']),
        'seats_no': digitsOnly(adData['seatsNo']),
        'steering_side': adData['steering_side'] ?? adData['steeringSide'],
        'advertiser_name': adData['advertiser_name'] ?? adData['advertiserName'],
        'phone_number': adData['phone_number'] ?? adData['phoneNumber'],
        'whatsapp': adData['whatsapp'],
        'emirate': adData['emirate'],
        'area': adData['area'],
        'advertiser_type': adData['advertiser_type'] ?? adData['advertiserType'],
        'location': adData['location'] ?? adData['advertiser_location'] ?? adData['advertiserLocation'],
        'plan_type': adData['plan_type'] ?? adData['planType'],
        'plan_days': adData['plan_days'] ?? adData['planDays'],
        'plan_expires_at': adData['plan_expires_at'] ?? adData['planExpiresAt'],
      };

      // Include payment only if explicitly set by payment step
      if (adData['payment'] != null) {
        textData['payment'] = adData['payment'].toString();
      }

      final File? mainImage = adData['mainImage'] as File?;
      final List<File>? thumbnailImages = adData['thumbnailImages'] as List<File>?;

      // Diagnostics: compare client vs server payload
      final List<String> mismatches = [];
      camelToSnake.forEach((camel, snake) {
        final camelPresent = adData.containsKey(camel);
        final snakePresent = adData.containsKey(snake);
        if (camelPresent && !snakePresent) {
          mismatches.add('$camel -> should be $snake');
        }
      });
      if (mainImage == null) {
        mismatches.add('mainImage is missing (required for car ad)');
      }
      if (adData['thumbnailImages'] != null && thumbnailImages == null) {
        mismatches.add('thumbnailImages must be List<File>');
      }

      print('=== Client vs Server payload comparison ===');
      print('Endpoint client: /api/car-sales-ads');
      print('Files: mainImage: ${mainImage != null ? 'File' : 'null'}, thumbnails: ${thumbnailImages?.length ?? 0}');
      print('Client keys (sample): ${adData.keys.take(8).toList()} ...');
      print('Server expected keys (sample): ${textData.keys.take(8).toList()} ...');
      if (mismatches.isNotEmpty) {
        print('Mismatched/missing keys: ${mismatches.join(', ')}');
      } else {
        print('No key mismatches detected');
      }
      print('=================================================');

      final response = await _apiService.postFormData(
        '/api/car-sales-ads',
        data: textData,
        mainImage: mainImage,
        thumbnailImages: thumbnailImages,
        token: token,
      );

      if (response is Map) {
        final bool isSuccessFlag = response['success'] == true;
        final bool hasId = response.containsKey('id');
        final bool created = isSuccessFlag || hasId;
        if (created) {
          await fetchCarAds();
          return true;
        }
      }
      final message = (response is Map) ? (response['message'] ?? 'Failed to submit ad') : 'Failed to submit ad';
      throw Exception(message);
    } catch (e) {
      _submitAdError = e.toString();
      // Extra diagnostics for JSON-vs-File issues
      print('=== Submit Car Ad Error ===');
      print('Error: $e');
      print('Hint: Ensure files are sent with multipart/form-data and no File objects are included in JSON payload.');
      print('================================');
      return false;
    } finally {
      _isSubmittingAd = false;
      safeNotifyListeners();
    }
  }

  Future<void> fetchTopDealerAds({bool forceRefresh = false}) async {
    if (!forceRefresh && _topDealerAds.isNotEmpty) return;
    _isLoadingTopDealers = true;
    _topDealersError = null;
    safeNotifyListeners();
    try {
      // Public data - no token required
      _topDealerAds = await _carAdRepository.getBestAdvertiserAds(
          category: 'car_sales');
    } catch (e) {
      if (kDebugMode) print("Error fetching top dealer ads: $e");
      _topDealersError = e.toString();
    } finally {
      _isLoadingTopDealers = false;
      safeNotifyListeners();
    }
  }

  bool get isSearchEnabled {
    if (_selectedMake == null) return false;
    if (_selectedMake!.id == -1 || _selectedMake!.id == -2) return true;
    if (_isLoadingModels) return false;
    if (_models.isNotEmpty && _selectedModel == null) return false;
    return true;
  }

  String getSearchValidationMessage(S s) {
    if (_selectedMake == null) return s.please_select_make;
    if (_selectedMake!.id > 0 && _models.isNotEmpty && _selectedModel == null)
      return s.please_select_model;
    return ""; // No error
  }

  List<CarAdModel> _offerAds = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  List<CarAdModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;

  // ... (كل الدوال القديمة)

  List<CarAdModel> _allFetchedOfferAds = []; // القائمة الكاملة للعروض

  // فلاتر خاصة بالعروض
  String? offerYearFrom,
      offerYearTo,
      offerKmFrom,
      offerKmTo,
      offerPriceFrom,
      offerPriceTo;

  

  Future<void> fetchOfferAds() async {
    _isLoadingOffers = true;
    _offersError = null;
    safeNotifyListeners();
    try {
      // Public data - no token required for browsing car offer ads
      final ads = await _carAdRepository.getOfferAds();
      _allFetchedOfferAds = ads;

      _performLocalOfferFilter(); // Apply current filters (if any) right away
    } catch (e) {
      _offersError = e.toString();
    } finally {
      _isLoadingOffers = false;
      safeNotifyListeners();
    }
  }

  void _performLocalOfferFilter() {
    List<CarAdModel> filteredList = List.from(_allFetchedOfferAds);
    // Filter by Year
    final fromYear = int.tryParse(offerYearFrom ?? '');
    final toYear = int.tryParse(offerYearTo ?? '');
    if (fromYear != null)
      filteredList
          .retainWhere((ad) => (int.tryParse(ad.year) ?? 0) >= fromYear);
    if (toYear != null)
      filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) <= toYear);
    // Filter by Km
    final fromKm = int.tryParse(offerKmFrom?.replaceAll(',', '') ?? '');
    final toKm = int.tryParse(offerKmTo?.replaceAll(',', '') ?? '');
    if (fromKm != null)
      filteredList.retainWhere(
          (ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) >= fromKm);
    if (toKm != null)
      filteredList.retainWhere(
          (ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) <= toKm);
    // Filter by Price
    final fromPrice =
        double.tryParse(offerPriceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(offerPriceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null)
      filteredList.retainWhere((ad) =>
          (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) >= fromPrice);
    if (toPrice != null)
      filteredList.retainWhere((ad) =>
          (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) <= toPrice);

    _offerAds = filteredList;
    safeNotifyListeners();
  }

  void updateYearRangeForOffers(String? from, String? to) {
    offerYearFrom = from;
    offerYearTo = to;
    _performLocalOfferFilter();
  }

  void updateKmRangeForOffers(String? from, String? to) {
    offerKmFrom = from;
    offerKmTo = to;
    _performLocalOfferFilter();
  }

  void updatePriceRangeForOffers(String? from, String? to) {
    offerPriceFrom = from;
    offerPriceTo = to;
    _performLocalOfferFilter();
  }
}




