// lib/presentation/providers/car_rent_ad_provider.dart
import 'package:advertising_app/data/model/car_rent_ad_model.dart';
import 'package:advertising_app/data/repository/car_rent_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CarRentAdProvider extends ChangeNotifier {
  final CarRentRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  CarRentAdProvider() : _repository = CarRentRepository(ApiService());

  List<CarRentAdModel> _ads = [];
  bool _isLoading = false;
  String? _error;
  int _totalAds = 0;

  // Single ad details
  CarRentAdModel? _currentAd;
  bool _isLoadingAdDetails = false;
  String? _adDetailsError;

  // Loading states for different operations
  bool _isLoadingMakesAndModels = false;
  bool _isLoadingSpecs = false;
  bool _isLoadingContactInfo = false;
  bool _isAddingContactItem = false;
  bool _isSubmittingAd = false;

  // Error states
  String? _makesAndModelsError;
  String? _specsError;
  String? _contactInfoError;
  String? _addContactItemError;
  String? _createAdError;

  // Data lists for car specifications
  List<String> _makes = [];
  List<String> _models = [];
  List<String> _trims = [];
  List<String> _years = [];
  List<String> _specs = [];
  List<String> _carTypes = [];
  List<String> _transmissionTypes = [];
  List<String> _fuelTypes = [];
  List<String> _colors = [];
  List<String> _interiorColors = [];
  List<String> _warrantyOptions = [];
  List<String> _engineCapacities = [];
  List<String> _cylinders = [];
  List<String> _horsePowers = [];
  List<String> _doorsNumbers = [];
  List<String> _seatsNumbers = [];
  List<String> _steeringSides = [];
  List<String> _advertiserTypes = [];
  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];
  List<String> _emirates = [];
  
  // Dynamic field labels from API
  Map<String, String> _fieldLabels = {};

  // Default values for offline mode
  final List<String> _defaultMakes = ['BMW', 'Honda', 'Toyota'];
  final List<String> _defaultModels = ['Corolla', 'Accord', 'X5'];
  final List<String> _defaultTrims = ['Base', 'Sport', 'Luxury'];
  final List<String> _defaultYears = ['2020', '2021', '2022', '2023', '2024'];
  final List<String> _defaultSpecs = ['Automatic', 'Manual', 'CVT'];
  final List<String> _defaultCarTypes = ['Sedan', 'SUV', 'Hatchback', 'Coupe'];
  final List<String> _defaultTransmissionTypes = ['Automatic', 'Manual', 'CVT'];
  final List<String> _defaultFuelTypes = ['Petrol', 'Diesel', 'Hybrid', 'Electric'];
  final List<String> _defaultColors = ['White', 'Black', 'Silver', 'Red', 'Blue'];
  final List<String> _defaultInteriorColors = ['Black', 'Beige', 'Brown', 'Gray'];
  final List<String> _defaultWarrantyOptions = ['1 Year', '2 Years', '3 Years', 'No Warranty'];
  final List<String> _defaultEngineCapacities = ['1.0L', '1.5L', '2.0L', '2.5L', '3.0L'];
  final List<String> _defaultCylinders = ['3', '4', '6', '8'];
  final List<String> _defaultHorsePowers = ['100-150', '150-200', '200-250', '250+'];
  final List<String> _defaultDoorsNumbers = ['2', '4', '5'];
  final List<String> _defaultSeatsNumbers = ['2', '4', '5', '7', '8'];
  final List<String> _defaultSteeringSides = ['Left', 'Right'];
  final List<String> _defaultAdvertiserTypes = ['Individual', 'Dealer', 'Company'];
  final List<String> _defaultAdvertiserNames = ['Ahmed Ali', 'Sara Mohamed', 'Dubai Motors'];
  final List<String> _defaultPhoneNumbers = ['+971501234567', '+971509876543', '+971507654321'];
  final List<String> _defaultWhatsappNumbers = ['+971501234567', '+971509876543', '+971507654321'];
  final List<String> _defaultEmirates = ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah', 'Fujairah', 'Umm Al Quwain'];

  // Map to store models for each make
  final Map<String, List<String>> _makeToModelsMap = {};
  // Map to store trims for each model
  final Map<String, List<String>> _modelToTrimsMap = {};

  List<CarRentAdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalAds => _totalAds;

  // Getters for single ad details
  CarRentAdModel? get currentAd => _currentAd;
  bool get isLoadingAdDetails => _isLoadingAdDetails;
  String? get adDetailsError => _adDetailsError;

  // Getters for specifications
  bool get isLoadingMakesAndModels => _isLoadingMakesAndModels;
  bool get isLoadingSpecs => _isLoadingSpecs;
  bool get isLoadingContactInfo => _isLoadingContactInfo;
  bool get isAddingContactItem => _isAddingContactItem;
  bool get isSubmittingAd => _isSubmittingAd;
  bool get isSubmitting => _isSubmittingAd; // Alias for compatibility
  bool get loading => _isLoading || _isLoadingMakesAndModels || _isLoadingSpecs || _isLoadingContactInfo || _isAddingContactItem || _isSubmittingAd || _isLoadingAdDetails;
  String? get makesAndModelsError => _makesAndModelsError;
  String? get specsError => _specsError;
  String? get contactInfoError => _contactInfoError;
  String? get addContactItemError => _addContactItemError;
  String? get createAdError => _createAdError;
  String? get submissionError => _createAdError; // Alias for submission error
  String? get allErrors => _error ?? _makesAndModelsError ?? _specsError ?? _contactInfoError ?? _addContactItemError ?? _createAdError ?? _adDetailsError;
  
  // Additional getters for compatibility
  CarRentAdModel? get editAd => _currentAd; // Alias for currentAd
  List<String> get interiorColor => _interiorColors; // Alias for interiorColors
  List<String> get seatsNo => _seatsNumbers; // Alias for seatsNumbers
  
  List<String> get makes => _makes;
  List<String> get models => _models;
  List<String> get trims => _trims;
  List<String> get years => _years;
  List<String> get specs => _specs;
  List<String> get carTypes => _carTypes;
  List<String> get transmissionTypes => _transmissionTypes;
  List<String> get fuelTypes => _fuelTypes;
  List<String> get colors => _colors;
  List<String> get interiorColors => _interiorColors;
  List<String> get warrantyOptions => _warrantyOptions;
  List<String> get engineCapacities => _engineCapacities;
  List<String> get cylinders => _cylinders;
  List<String> get horsePowers => _horsePowers;
  List<String> get doorsNumbers => _doorsNumbers;
  List<String> get seatsNumbers => _seatsNumbers;
  List<String> get steeringSides => _steeringSides;
  List<String> get advertiserTypes => _advertiserTypes;
  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get whatsappNumbers => _whatsappNumbers;
  List<String> get emirates => _emirates;
  Map<String, String> get fieldLabels => _fieldLabels;
  Map<String, List<String>> get makeToModelsMap => _makeToModelsMap;
  Map<String, List<String>> get modelToTrimsMap => _modelToTrimsMap;

  String getFieldLabel(String fieldName) {
    return _fieldLabels[fieldName] ?? _getDefaultLabel(fieldName);
  }

  String _getDefaultLabel(String fieldName) {
    // Fallback to default labels if API doesn't provide them
    switch (fieldName) {
      case 'make': return 'Make';
      case 'model': return 'Model';
      case 'trim': return 'Trim';
      case 'year': return 'Year';
      case 'specs': return 'Specs';
      case 'carType': return 'Car Type';
      case 'transType': return 'Transmission Type';
      case 'fuelType': return 'Fuel Type';
      case 'color': return 'Color';
      case 'interiorColor': return 'Interior Color';
      case 'warranty': return 'Warranty';
      case 'engineCapacity': return 'Engine Capacity';
      case 'cylinders': return 'Cylinders';
      case 'horsePower': return 'Horse Power';
      case 'doorsNo': return 'Doors Number';
      case 'seatsNo': return 'Seats Number';
      case 'steeringSide': return 'Steering Side';
      case 'advertiserType': return 'Advertiser Type';
      default: return fieldName;
    }
  }

  /// Fetch single car rent ad details by ID
  Future<void> fetchAdDetails(String adId, {String? token}) async {
    // print('=== CarRentAdProvider.fetchAdDetails ===');
    // print('Ad ID: $adId');
    
    _isLoadingAdDetails = true;
    _adDetailsError = null;
    _currentAd = null;
    notifyListeners();

    try {
      final authToken = token ?? await _storage.read(key: 'auth_token');
      // print('Calling repository.getCarRentAdDetails with ID: $adId');
      final ad = await _repository.getCarRentAdDetails(adId: adId, token: authToken);
      // print('Ad details fetched successfully: ${ad.title}');
      
      _currentAd = ad;
    } catch (e) {
      // print('Error in fetchAdDetails: $e');
      _adDetailsError = e.toString();
    } finally {
      _isLoadingAdDetails = false;
      notifyListeners();
    }
  }

  /// Update car rent ad
  Future<bool> updateCarRentAd(String adId, Map<String, dynamic> adData, {String? token}) async {
    // print('=== CarRentAdProvider.updateCarRentAd ===');
    // print('Ad ID: $adId');
    
    _isSubmittingAd = true;
    _createAdError = null;
    safeNotifyListeners();

    try {
      final authToken = token ?? await _storage.read(key: 'auth_token');
      if (authToken == null) {
        _createAdError = 'Authentication token not found';
        // print('❌ No auth token found');
        return false;
      }

      // print('✅ Auth token found: ${authToken.substring(0, 20)}...');

      // Use repository to update the ad
      await _repository.updateCarRentAd(
        adId: int.parse(adId),
        token: authToken,
        adData: adData,
      );

      // print('✅ Car rent ad updated successfully');
      
      // Refresh the current ad details after update
      await fetchAdDetails(adId, token: authToken);
      
      return true;
    } catch (e) {
      _createAdError = e.toString();
      // print('❌ Exception updating car rent ad: $e');
      return false;
    } finally {
      _isSubmittingAd = false;
      safeNotifyListeners();
    }
  }

  /// Get models for a specific make
  List<String> getModelsForMake(String make) {
    return _makeToModelsMap[make] ?? [];
  }

  /// Get trims for a specific model
  List<String> getTrimsForModel(String model) {
    return _modelToTrimsMap[model] ?? [];
  }

  Future<void> fetchAds({Map<String, dynamic>? filters}) async {
   // // print('=== CarRentAdProvider.fetchAds ===');
   // // print('Filters received: $filters');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Public data - no token required for browsing car rental ads
     // // print('Calling repository.getCarRentAds with filters: $filters');
      final response = await _repository.getCarRentAds(query: filters);
     // // print('API Response - Total ads: ${response.total}');
     // // print('API Response - Ads count: ${response.ads.length}');
      
      _ads = response.ads;
      _allFetchedAds = List.from(response.ads); // Store all fetched ads for local filtering
      _totalAds = response.total;

    } catch (e) {
     // // print('Error in fetchAds: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch car makes and models from API
  Future<void> fetchCarMakesAndModels({String? token}) async {
    _isLoadingMakesAndModels = true;
    _makesAndModelsError = null;
    safeNotifyListeners();

    try {
      // Fetch makes
      final makesResponse = await _apiService.get('/api/filters/car-sale/makes', );
      if (makesResponse['success'] == true && makesResponse['data'] != null) {
        _makes = List<String>.from(makesResponse['data'].map((item) => item['name'] ?? item.toString()));
        
        // Clear previous mappings
        _makeToModelsMap.clear();
        
        // Fetch models for each make
        for (final makeData in makesResponse['data']) {
          final makeId = makeData['id'];
          final makeName = makeData['name'];
          
          if (makeId != null && makeName != null) {
            try {
              final modelsResponse = await _apiService.get('/api/filters/car-sale/makes/$makeId/models', );
              if (modelsResponse['success'] == true && modelsResponse['data'] != null) {
                final models = List<String>.from(modelsResponse['data'].map((item) => item['name'] ?? item.toString()));
                _makeToModelsMap[makeName] = models;
                
                // Fetch trims for each model
                for (final modelData in modelsResponse['data']) {
                  final modelId = modelData['id'];
                  final modelName = modelData['name'];
                  
                  if (modelId != null && modelName != null) {
                    try {
                      final trimsResponse = await _apiService.get('/api/filters/car-sale/models/$modelId/trims', );
                      if (trimsResponse['success'] == true && trimsResponse['data'] != null) {
                        final trims = List<String>.from(trimsResponse['data'].map((item) => item['name'] ?? item.toString()));
                        _modelToTrimsMap[modelName] = trims;
                      }
                    } catch (e) {
                      // Continue with other models if one fails
                     // // print('Error fetching trims for model $modelName: $e');
                    }
                  }
                }
              }
            } catch (e) {
              // Continue with other makes if one fails
             // // print('Error fetching models for make $makeName: $e');
            }
          }
        }
        
        // Update models and trims lists
        _models = _makeToModelsMap.values.expand((models) => models).toSet().toList();
        _trims = _modelToTrimsMap.values.expand((trims) => trims).toSet().toList();
        
        // Initialize car makes data with proper structure
        _carMakes = List<Map<String, dynamic>>.from(makesResponse['data']);
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      _makesAndModelsError = e.toString();
      // Use default values when exception occurs
      _useDefaultValues();
    } finally {
      _isLoadingMakesAndModels = false;
      safeNotifyListeners();
    }
  }

  /// Fetch car specifications from API
  Future<void> fetchCarSpecs({String? token}) async {
    _isLoadingSpecs = true;
    _specsError = null;
    safeNotifyListeners();

    try {
      final response = await _apiService.get('/api/car-rent-ad-specs', );
      
      if (response['success'] == true && response['data'] != null) {
        _parseSpecsFromApi(response['data']);
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      _specsError = e.toString();
      // Use default values when exception occurs
      _useDefaultSpecsValues();
    } finally {
      _isLoadingSpecs = false;
      safeNotifyListeners();
    }
  }

  /// Fetch contact information from API
  Future<void> fetchContactInfo({String? token}) async {
    _isLoadingContactInfo = true;
    _contactInfoError = null;
    safeNotifyListeners();

    try {
      final authToken = token ?? await _storage.read(key: 'auth_token');
      final response = await _apiService.get('/api/contact-info', token: authToken);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        if (data['advertiser_names'] != null) {
          _advertiserNames = List<String>.from(data['advertiser_names']);
        }
        
        if (data['phone_numbers'] != null) {
          _phoneNumbers = List<String>.from(data['phone_numbers']);
        }
        
        if (data['whatsapp_numbers'] != null) {
          _whatsappNumbers = List<String>.from(data['whatsapp_numbers']);
        }
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      _contactInfoError = e.toString();
      // Use default values when exception occurs
      _useDefaultContactValues();
    } finally {
      _isLoadingContactInfo = false;
      safeNotifyListeners();
    }
  }

  /// Add new contact item via API
  Future<bool> addContactItem(String field, String value, {String? token}) async {
    _isAddingContactItem = true;
    _addContactItemError = null;
    safeNotifyListeners();

    try {
      final response = await _apiService.post(
        '/api/contact-info/add-item',
        data: {
          'field': field,
          'value': value,
        },
        token: token,
      );
      
      if (response['success'] == true) {
        // Add the new item to the appropriate list
        switch (field) {
          case 'advertiser_names':
            if (!_advertiserNames.contains(value)) {
              _advertiserNames.add(value);
            }
            break;
          case 'phone_numbers':
            if (!_phoneNumbers.contains(value)) {
              _phoneNumbers.add(value);
            }
            break;
          case 'whatsapp_numbers':
            if (!_whatsappNumbers.contains(value)) {
              _whatsappNumbers.add(value);
            }
            break;
        }
        safeNotifyListeners();
        return true;
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      _addContactItemError = e.toString();
      return false;
    } finally {
      _isAddingContactItem = false;
      safeNotifyListeners();
    }
  }

  /// Clear all data
  void clearData() {
    _ads.clear();
    _currentAd = null;
    _makes.clear();
    _models.clear();
    _trims.clear();
    _years.clear();
    _specs.clear();
    _carTypes.clear();
    _transmissionTypes.clear();
    _fuelTypes.clear();
    _colors.clear();
    _interiorColors.clear();
    _warrantyOptions.clear();
    _engineCapacities.clear();
    _cylinders.clear();
    _horsePowers.clear();
    _doorsNumbers.clear();
    _seatsNumbers.clear();
    _steeringSides.clear();
    _advertiserTypes.clear();
    _advertiserNames.clear();
    _phoneNumbers.clear();
    _whatsappNumbers.clear();
    _emirates.clear();
    _makeToModelsMap.clear();
    _modelToTrimsMap.clear();
    _fieldLabels.clear();
    
    _error = null;
    _adDetailsError = null;
    _makesAndModelsError = null;
    _specsError = null;
    _contactInfoError = null;
    _addContactItemError = null;
    
    safeNotifyListeners();
  }

  /// Safe notify listeners to avoid disposed provider issues
  void safeNotifyListeners() {
    if (!mounted) return;
    notifyListeners();
  }

  /// Check if provider is still mounted
  bool get mounted {
    try {
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parse specifications from API response
  void _parseSpecsFromApi(Map<String, dynamic> specs) {
    // Clear existing data
    _years.clear();
    _specs.clear();
    _carTypes.clear();
    _transmissionTypes.clear();
    _fuelTypes.clear();
    _colors.clear();
    _interiorColors.clear();
    _warrantyOptions.clear();
    _engineCapacities.clear();
    _cylinders.clear();
    _horsePowers.clear();
    _doorsNumbers.clear();
    _seatsNumbers.clear();
    _steeringSides.clear();
    _advertiserTypes.clear();
    _fieldLabels.clear();

    // Parse years
    if (specs['years'] != null && specs['years'] is List) {
      _years.addAll(List<String>.from(specs['years']));
    }

    // Parse car types
    if (specs['carTypes'] != null && specs['carTypes'] is List) {
      _carTypes.addAll(List<String>.from(specs['carTypes']));
    }

    // Parse transmission types
    if (specs['transmissionTypes'] != null && specs['transmissionTypes'] is List) {
      _transmissionTypes.addAll(List<String>.from(specs['transmissionTypes']));
    }

    // Parse fuel types
    if (specs['fuelTypes'] != null && specs['fuelTypes'] is List) {
      _fuelTypes.addAll(List<String>.from(specs['fuelTypes']));
    }

    // Parse colors
    if (specs['colors'] != null && specs['colors'] is List) {
      _colors.addAll(List<String>.from(specs['colors']));
    }

    // Parse interior colors
    if (specs['interiorColors'] != null && specs['interiorColors'] is List) {
      _interiorColors.addAll(List<String>.from(specs['interiorColors']));
    }

    // Parse warranty options
    if (specs['warrantyOptions'] != null && specs['warrantyOptions'] is List) {
      _warrantyOptions.addAll(List<String>.from(specs['warrantyOptions']));
    }

    // Parse engine capacities
    if (specs['engineCapacities'] != null && specs['engineCapacities'] is List) {
      _engineCapacities.addAll(List<String>.from(specs['engineCapacities']));
    }

    // Parse cylinders
    if (specs['cylinders'] != null && specs['cylinders'] is List) {
      _cylinders.addAll(List<String>.from(specs['cylinders']));
    }

    // Parse horse powers
    if (specs['horsePowers'] != null && specs['horsePowers'] is List) {
      _horsePowers.addAll(List<String>.from(specs['horsePowers']));
    }

    // Parse doors numbers
    if (specs['doorsNumbers'] != null && specs['doorsNumbers'] is List) {
      _doorsNumbers.addAll(List<String>.from(specs['doorsNumbers']));
    }

    // Parse seats numbers
    if (specs['seatsNumbers'] != null && specs['seatsNumbers'] is List) {
      _seatsNumbers.addAll(List<String>.from(specs['seatsNumbers']));
    }

    // Parse steering sides
    if (specs['steeringSides'] != null && specs['steeringSides'] is List) {
      _steeringSides.addAll(List<String>.from(specs['steeringSides']));
    }

    // Parse advertiser types
    if (specs['advertiserTypes'] != null && specs['advertiserTypes'] is List) {
      _advertiserTypes.addAll(List<String>.from(specs['advertiserTypes']));
    }

    // Parse field labels
    if (specs['fieldLabels'] != null && specs['fieldLabels'] is Map) {
      _fieldLabels.addAll(Map<String, String>.from(specs['fieldLabels']));
    }

    // Keep default values for fields not provided by API
    if (_advertiserNames.isEmpty) {
      _advertiserNames = List<String>.from(_defaultAdvertiserNames);
    }
    if (_phoneNumbers.isEmpty) {
      _phoneNumbers = List<String>.from(_defaultPhoneNumbers);
    }
    if (_whatsappNumbers.isEmpty) {
      _whatsappNumbers = List<String>.from(_defaultWhatsappNumbers);
    }
    if (_emirates.isEmpty) {
      _emirates = List<String>.from(_defaultEmirates);
    }
  }
  
  /// استخدام القيم الافتراضية للمواصفات
  void _useDefaultSpecsValues() {
    _specs = List<String>.from(_defaultSpecs);
    _carTypes = List<String>.from(_defaultCarTypes);
    _transmissionTypes = List<String>.from(_defaultTransmissionTypes);
    _fuelTypes = List<String>.from(_defaultFuelTypes);
    _colors = List<String>.from(_defaultColors);
    _interiorColors = List<String>.from(_defaultInteriorColors);
    _warrantyOptions = List<String>.from(_defaultWarrantyOptions);
    _engineCapacities = List<String>.from(_defaultEngineCapacities);
    _cylinders = List<String>.from(_defaultCylinders);
    _horsePowers = List<String>.from(_defaultHorsePowers);
    _doorsNumbers = List<String>.from(_defaultDoorsNumbers);
    _seatsNumbers = List<String>.from(_defaultSeatsNumbers);
    _steeringSides = List<String>.from(_defaultSteeringSides);
    _advertiserTypes = List<String>.from(_defaultAdvertiserTypes);
    _advertiserNames = List<String>.from(_defaultAdvertiserNames);
    _phoneNumbers = List<String>.from(_defaultPhoneNumbers);
    _whatsappNumbers = List<String>.from(_defaultWhatsappNumbers);
    _emirates = List<String>.from(_defaultEmirates);
  }

  /// استخدام القيم الافتراضية لبيانات جهات الاتصال
  void _useDefaultContactValues() {
    _advertiserNames = List<String>.from(_defaultAdvertiserNames);
    _phoneNumbers = List<String>.from(_defaultPhoneNumbers);
    _whatsappNumbers = List<String>.from(_defaultWhatsappNumbers);
  }

  /// استخدام القيم الافتراضية للماركات والموديلات والتريمات
  void _useDefaultValues() {
    _makes = List<String>.from(_defaultMakes);
    _models = List<String>.from(_defaultModels);
    _trims = List<String>.from(_defaultTrims);
    _years = List<String>.from(_defaultYears);
    _advertiserNames = List<String>.from(_defaultAdvertiserNames);
    _phoneNumbers = List<String>.from(_defaultPhoneNumbers);
    _whatsappNumbers = List<String>.from(_defaultWhatsappNumbers);
    _emirates = List<String>.from(_defaultEmirates);
    
    // Setup default make-to-models mapping
    _makeToModelsMap.clear();
    _makeToModelsMap['BMW'] = ['X5', 'X3', '3 Series'];
    _makeToModelsMap['Honda'] = ['Accord', 'Civic', 'CR-V'];
    _makeToModelsMap['Toyota'] = ['Corolla', 'Camry', 'RAV4'];
    
    // Setup default model-to-trims mapping
    _modelToTrimsMap.clear();
    _modelToTrimsMap['Corolla'] = ['Base', 'Sport', 'Luxury'];
    _modelToTrimsMap['Accord'] = ['Base', 'Sport', 'Touring'];
    _modelToTrimsMap['X5'] = ['Base', 'M Sport', 'xDrive'];
  }

  void clearError() {
    _error = null;
    _adDetailsError = null;
    _makesAndModelsError = null;
    _specsError = null;
    _contactInfoError = null;
    _addContactItemError = null;
    notifyListeners();
  }

  /// Fetch makes from API
  Future<void> fetchMakes() async {
    try {
      // Public data - no token required
      final response = await _apiService.get('/api/filters/car-rent/makes');
      
      if (response['success'] == true && response['data'] != null) {
        _makes = List<String>.from(response['data'].map((item) => item['name'] ?? item.toString()));
        notifyListeners();
      }
    } catch (e) {
     // // print('Error fetching makes: $e');
      // Use default makes if API fails
      _makes = List<String>.from(_defaultMakes);
      notifyListeners();
    }
  }

  // Filter functionality
  Map<String, dynamic> _currentFilters = {};
  List<CarRentAdModel> _allFetchedAds = [];
  String? yearFrom, yearTo, priceFrom, priceTo;
  
  Map<String, dynamic> get currentFilters => _currentFilters;

  /// Apply filters to the ads
  void applyFilters(Map<String, dynamic> filters) {
    _currentFilters = Map<String, dynamic>.from(filters);
    fetchAds(filters: _currentFilters);
  }

  /// Clear all filters
  void clearFilters() {
    _currentFilters.clear();
    yearFrom = null;
    yearTo = null;
    priceFrom = null;
    priceTo = null;
    fetchAds();
  }

  /// Perform local filtering for year and price ranges
  void _performLocalFilter() {
    List<CarRentAdModel> filteredList = List.from(_allFetchedAds);
    
    // Filter by Year
    final fromYear = int.tryParse(yearFrom ?? '');
    final toYear = int.tryParse(yearTo ?? '');
    if (fromYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year ?? '') ?? 0) >= fromYear);
    if (toYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year ?? '') ?? 0) <= toYear);
    
    // Filter by Price (using dayRent as the primary price)
    final fromPrice = double.tryParse(priceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(priceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.dayRent.replaceAll(',', '')) ?? 0) >= fromPrice);
    if (toPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.dayRent.replaceAll(',', '')) ?? 0) <= toPrice);
    
    _ads = filteredList;
    _totalAds = filteredList.length; // Update total count to reflect filtered results
    notifyListeners();
  }

  /// Update year range and apply local filtering
  void updateYearRange(String? from, String? to) { 
    yearFrom = from; 
    yearTo = to; 
    _performLocalFilter(); 
  }

  /// Update price range and apply local filtering
  void updatePriceRange(String? from, String? to) { 
    priceFrom = from; 
    priceTo = to; 
    _performLocalFilter(); 
  }

  /// Fetch models for a specific make ID
  Future<void> fetchModels(int makeId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _apiService.get('/api/filters/car-sale/makes/$makeId/models', );
      
      if (response['success'] == true && response['data'] != null) {
        _models = List<String>.from(response['data'].map((item) => item['name'] ?? item.toString()));
        notifyListeners();
      }
    } catch (e) {
     // // print('Error fetching models: $e');
      // Use default models if API fails
      _models = List<String>.from(_defaultModels);
      notifyListeners();
    }
  }

  // إضافة getters للبيانات الجديدة
  List<Map<String, dynamic>> _carMakes = [];
  List<Map<String, dynamic>> _carModels = [];
  List<Map<String, dynamic>> _carTrims = [];

  List<Map<String, dynamic>> get carMakes => _carMakes;
  List<Map<String, dynamic>> get carModels => _carModels;
  List<Map<String, dynamic>> get carTrims => _carTrims;

  /// Initialize car makes data from fetchCarMakesAndModels
  void _initializeCarMakes() {
    _carMakes = _makes.asMap().entries.map((entry) => {
      'id': entry.key + 1, // Simple ID assignment
      'name': entry.value,
    }).toList();
  }

  /// Fetch trims for a specific model ID
  Future<void> fetchTrims(int modelId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _apiService.get('/api/filters/car-sale/models/$modelId/trims', );
      
      if (response['success'] == true && response['data'] != null) {
        _trims = List<String>.from(response['data'].map((item) => item['name'] ?? item.toString()));
        notifyListeners();
      }
    } catch (e) {
     // // print('Error fetching trims: $e');
      // Use default trims if API fails
      _trims = List<String>.from(_defaultTrims);
      notifyListeners();
    }
  }

  /// Fetch car models for a specific make ID
  Future<void> fetchCarModels(int makeId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _apiService.get('/api/filters/car-sale/makes/$makeId/models', );
      
      if (response['success'] == true && response['data'] != null) {
        _carModels = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
     // // print('Error fetching car models: $e');
      _carModels = [];
      notifyListeners();
    }
  }

  /// Fetch car trims for a specific model ID
  Future<void> fetchCarTrims(int modelId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _apiService.get('/api/filters/car-sale/models/$modelId/trims', );
      
      if (response['success'] == true && response['data'] != null) {
        _carTrims = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
     // // print('Error fetching car trims: $e');
      _carTrims = [];
      notifyListeners();
    }
  }

  /// Submit car rent ad
  Future<bool> submitCarRentAd(Map<String, dynamic> adData) async {
   // // print('=== Car Rent Ad Submission Started ===');
    _isSubmittingAd = true;
    _createAdError = null;
    safeNotifyListeners();

    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) {
        _createAdError = 'Authentication token not found';
       // // print('❌ No auth token found');
        return false;
      }

     // // print('✅ Auth token found: ${token.substring(0, 20)}...');

      // Prepare submission data
      final submissionData = {
        'title': adData['title']?.toString() ?? '',
        'description': adData['description']?.toString() ?? '',
        'emirate': adData['emirate']?.toString() ?? '',
        'make': adData['make']?.toString() ?? '',
        'model': adData['model']?.toString() ?? '',
        'trim': adData['trim']?.toString() ?? '',
        'year': adData['year']?.toString() ?? '',
        'price': adData['price']?.toString() ?? '',
        'day_rent': adData['day_rent']?.toString() ?? '',
        'month_rent': adData['month_rent']?.toString() ?? '',
        'car_type': adData['car_type']?.toString() ?? '',
        'trans_type': adData['trans_type']?.toString() ?? '',
        'fuel_type': adData['fuel_type']?.toString() ?? '',
        'color': adData['color']?.toString() ?? '',
        'interior_color': adData['interior_color']?.toString() ?? '',
        'seats_no': _extractNumericValue(adData['seats_no']?.toString() ?? ''),
        'area': adData['area']?.toString() ?? '',
        'phone_number': adData['phone_number']?.toString() ?? '',
        'whatsapp': adData['whatsapp']?.toString() ?? '',
        'advertiser_name': adData['advertiser_name']?.toString() ?? '',
        'advertiser_location': adData['advertiser_location']?.toString() ?? '',
        'location': adData['location']?.toString() ?? '',
        // إضافة بيانات الخطة
        'plan_type': adData['planType']?.toString() ?? 'free',
        'plan_days': adData['planDays']?.toString() ?? '7',
        'plan_expires_at': adData['planExpiresAt']?.toString() ?? '',
      };

      // Include payment only when explicitly set by the payment step
      if (adData['payment'] != null) {
        submissionData['payment'] = adData['payment'].toString();
      }

     // // print('=== DETAILED SUBMISSION DATA DEBUG ===');
      submissionData.forEach((key, value) {
       // // print('$key: "$value" (${value.runtimeType}) - Length: ${value.toString().length}');
      });
      
      // Check for required fields
      List<String> missingFields = [];
      List<String> requiredFields = ['title', 'emirate', 'make', 'year', 'price', 'day_rent', 'month_rent', 'seats_no', 'area', 'phone_number'];
      
      for (String field in requiredFields) {
        if (submissionData[field] == null || submissionData[field]!.isEmpty) {
          missingFields.add(field);
        }
      }
      
      if (missingFields.isNotEmpty) {
        _createAdError = 'Missing required fields: ${missingFields.join(', ')}';
       // // print('❌ Missing required fields: $missingFields');
        return false;
      }
      
     // // print('✅ All required fields are present');
     // // print('Main Image: ${adData['mainImage'] != null ? 'File provided (${adData['mainImage'].path})' : 'No file'}');
     // // print('Thumbnail Images: ${(adData['thumbnailImages'] as List?)?.length ?? 0} images');
      
      if (adData['thumbnailImages'] != null) {
        for (int i = 0; i < (adData['thumbnailImages'] as List).length; i++) {
         // // print('  Thumbnail $i: ${(adData['thumbnailImages'] as List)[i].path}');
        }
      }

      // Use postFormData to handle images properly
     // // print('🚀 Sending request to /api/car-rent-ads...');
      final response = await _apiService.postFormData(
        '/api/car-rent-ads',
        data: submissionData,
        mainImage: adData['mainImage'],
        thumbnailImages: adData['thumbnailImages'],
        token: token,
      );

     // // print('=== API RESPONSE RECEIVED ===');
     // // print('Response Type: ${response.runtimeType}');
     // // print('Response Content: $response');

      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
         // // print('✅ Car rent ad submitted successfully');
          return true;
        } else {
          _createAdError = response['message'] ?? 'Failed to submit car rent ad';
         // // print('❌ Failed to submit car rent ad: $_createAdError');
         // // print('Full response: $response');
          return false;
        }
      } else {
        // Handle non-map responses
       // // print('✅ Car rent ad submitted successfully (non-map response)');
        return true;
      }
    } catch (e, stackTrace) {
      _createAdError = e.toString();
     // // print('❌ Exception submitting car rent ad: $e');
     // // print('Exception Type: ${e.runtimeType}');
     // // print('Stack trace: $stackTrace');
      
      // More detailed error analysis
      if (e.toString().contains('500')) {
       // // print('🔍 Server Error 500 - Internal Server Error');
       // // print('This usually means there\'s an issue on the server side');
      } else if (e.toString().contains('400')) {
       // // print('🔍 Client Error 400 - Bad Request');
       // // print('This usually means the data format is incorrect');
      } else if (e.toString().contains('401')) {
       // // print('🔍 Auth Error 401 - Unauthorized');
       // // print('This usually means the token is invalid or expired');
      } else if (e.toString().contains('422')) {
       // // print('🔍 Validation Error 422 - Unprocessable Entity');
       // // print('This usually means validation failed on the server');
      }
      
      return false;
    } finally {
      _isSubmittingAd = false;
      safeNotifyListeners();
     // // print('=== Car Rent Ad Submission Finished ===');
    }
  }

  /// Helper method to extract numeric value from string (e.g., "5 Seats" -> "5")
  String _extractNumericValue(String value) {
    if (value.isEmpty) return '';
    final match = RegExp(r'\d+').firstMatch(value);
    return match?.group(0) ?? '';
  }
}