import 'package:flutter/material.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/model/car_specs_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CarSalesInfoProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CarSalesInfoProvider();

  // Loading states
  bool _isLoadingMakesAndModels = false;
  bool _isLoadingSpecs = false;
  bool _isLoadingContactInfo = false;
  bool _isAddingContactItem = false;

  // Error states
  String? _makesAndModelsError;
  String? _specsError;
  String? _contactInfoError;
  String? _addContactItemError;

  // Data lists
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
  final List<String> _defaultFuelTypes = [
    'Petrol',
    'Diesel',
    'Hybrid',
    'Electric'
  ];
  final List<String> _defaultColors = [
    'White',
    'Black',
    'Silver',
    'Red',
    'Blue'
  ];
  final List<String> _defaultInteriorColors = [
    'Black',
    'Beige',
    'Brown',
    'Gray'
  ];
  final List<String> _defaultWarrantyOptions = [
    '1 Year',
    '2 Years',
    '3 Years',
    'No Warranty'
  ];
  final List<String> _defaultEngineCapacities = [
    '1.0L',
    '1.5L',
    '2.0L',
    '2.5L',
    '3.0L'
  ];
  final List<String> _defaultCylinders = ['3', '4', '6', '8'];
  final List<String> _defaultHorsePowers = [
    '100-150',
    '150-200',
    '200-250',
    '250+'
  ];
  final List<String> _defaultDoorsNumbers = ['2', '4', '5'];
  final List<String> _defaultSeatsNumbers = ['2', '4', '5', '7', '8'];
  final List<String> _defaultSteeringSides = ['Left', 'Right'];
  final List<String> _defaultAdvertiserTypes = [
    'Individual',
    'Dealer',
    'Company'
  ];
  final List<String> _defaultAdvertiserNames = [''];
  final List<String> _defaultPhoneNumbers = [
    '+971501234567',
    '+971509876543',
    '+971507654321'
  ];
  final List<String> _defaultWhatsappNumbers = [
    '+971501234567',
    '+971509876543',
    '+971507654321'
  ];
  final List<String> _defaultEmirates = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Ras Al Khaimah',
    'Fujairah',
    'Umm Al Quwain'
  ];

  // Getters
  bool get isLoadingMakesAndModels => _isLoadingMakesAndModels;
  bool get isLoadingSpecs => _isLoadingSpecs;
  bool get isLoadingContactInfo => _isLoadingContactInfo;
  bool get isAddingContactItem => _isAddingContactItem;
  bool get loading =>
      _isLoadingMakesAndModels ||
      _isLoadingSpecs ||
      _isLoadingContactInfo ||
      _isAddingContactItem;
  String? get makesAndModelsError => _makesAndModelsError;
  String? get specsError => _specsError;
  String? get contactInfoError => _contactInfoError;
  String? get addContactItemError => _addContactItemError;
  String? get error =>
      _makesAndModelsError ??
      _specsError ??
      _contactInfoError ??
      _addContactItemError;
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

  String getFieldLabel(String fieldName) {
    return _fieldLabels[fieldName] ?? _getDefaultLabel(fieldName);
  }

  String _getDefaultLabel(String fieldName) {
    // Fallback to default labels if API doesn't provide them
    switch (fieldName) {
      case 'make':
        return 'Make';
      case 'model':
        return 'Model';
      case 'trim':
        return 'Trim';
      case 'year':
        return 'Year';
      case 'specs':
        return 'Specs';
      case 'carType':
        return 'Car Type';
      case 'transType':
        return 'Transmission Type';
      case 'fuelType':
        return 'Fuel Type';
      case 'color':
        return 'Color';
      case 'interiorColor':
        return 'Interior Color';
      case 'warranty':
        return 'Warranty';
      case 'engineCapacity':
        return 'Engine Capacity';
      case 'cylinders':
        return 'Cylinders';
      case 'horsePower':
        return 'Horse Power';
      case 'doorsNo':
        return 'Doors Number';
      case 'seatsNo':
        return 'Seats Number';
      case 'steeringSide':
        return 'Steering Side';
      case 'advertiserType':
        return 'Advertiser Type';
      default:
        return fieldName;
    }
  }

  /// Get display name for a field
  // String getFieldLabel(String fieldName) {
  //   return _fieldLabels[fieldName] ?? fieldName;
  // }

  // Map to store models for each make
  final Map<String, List<String>> _makeToModelsMap = {};
  // Map to store trims for each model
  final Map<String, List<String>> _modelToTrimsMap = {};

  Map<String, List<String>> get makeToModelsMap => _makeToModelsMap;
  Map<String, List<String>> get modelToTrimsMap => _modelToTrimsMap;

  /// Get models for a specific make
  List<String> getModelsForMake(String make) {
    return _makeToModelsMap[make] ?? [];
  }

  /// Get trims for a specific model
  List<String> getTrimsForModel(String model) {
    return _modelToTrimsMap[model] ?? [];
  }

  /// Fetch car makes and models from API
  Future<void> fetchCarMakesAndModels() async {
    _isLoadingMakesAndModels = true;
    _makesAndModelsError = null;
    safeNotifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Use default values instead of API call
      _useDefaultValues();
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
  Future<void> fetchCarSpecs() async {
    _isLoadingSpecs = true;
    _specsError = null;
    safeNotifyListeners();

    try {
      // بيانات عامة - لا حاجة لتوكن
      final response = await _apiService.get('/api/car-sales-ad-specs');
      final carSpecsResponse = CarSpecsResponse.fromJson(response);

      if (carSpecsResponse.success) {
        _parseSpecsFromApi(carSpecsResponse.data);
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
  Future<void> fetchContactInfo() async {
    _isLoadingContactInfo = true;
    _contactInfoError = null;
    safeNotifyListeners();

    try {
      // قراءة الـ token من الـ storage
      final token = await _storage.read(key: 'auth_token');

      // بيانات عامة - لا حاجة لتوكن
      final response = await _apiService.get('/api/contact-info', token: token);

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
  Future<bool> addContactItem(String field, String value,
      {String? token}) async {
    _isAddingContactItem = true;
    _addContactItemError = null;
    safeNotifyListeners();

    try {
      // استخدام التوكن الجديد من التحقق
      final authToken = token ??
          await _storage.read(key: 'auth_token') ??
          await _storage.read(key: 'auth_token');

      final response = await _apiService.post(
        '/api/contact-info/add-item',
        data: {
          'field': field,
          'value': value,
        },
        token: authToken,
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
      rethrow;
    } finally {
      _isAddingContactItem = false;
      safeNotifyListeners();
    }
  }

  /// Clear all data
  void clearData() {
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
  void _parseSpecsFromApi(List<CarSpecField> fields) {
    // Clear existing data
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

    // Parse each field from API response
    for (final field in fields) {
      _fieldLabels[field.fieldName] = field.fieldName;

      switch (field.fieldName) {
        case 'make':
          _makes = List<String>.from(field.options);
          break;
        case 'model':
          _models = List<String>.from(field.options);
          break;
        case 'trim':
          _trims = List<String>.from(field.options);
          break;
        case 'year':
          _years = List<String>.from(field.options);
          break;
        case 'specs':
          _specs = List<String>.from(field.options);
          break;
        case 'carType':
          _carTypes = List<String>.from(field.options);
          break;
        case 'transType':
          _transmissionTypes = List<String>.from(field.options);
          break;
        case 'fuelType':
          _fuelTypes = List<String>.from(field.options);
          break;
        case 'color':
          _colors = List<String>.from(field.options);
          break;
        case 'interiorColor':
          _interiorColors = List<String>.from(field.options);
          break;
        case 'warranty':
          _warrantyOptions = List<String>.from(field.options);
          break;
        case 'engineCapacity':
          _engineCapacities = List<String>.from(field.options);
          break;
        case 'cylinders':
          _cylinders = List<String>.from(field.options);
          break;
        case 'horsePower':
          _horsePowers = List<String>.from(field.options);
          break;
        case 'doorsNo':
          _doorsNumbers = List<String>.from(field.options);
          break;
        case 'seatsNo':
          _seatsNumbers = List<String>.from(field.options);
          break;
        case 'steeringSide':
          _steeringSides = List<String>.from(field.options);
          break;
        case 'advertiserType':
          _advertiserTypes = List<String>.from(field.options);
          break;
        default:
          // Handle unknown fields if needed
          break;
      }
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

  // Map to store models for each make
  // Map to store trims for each model

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
}
