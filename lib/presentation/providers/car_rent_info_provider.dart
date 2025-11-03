// lib/presentation/providers/car_rent_info_provider.dart

import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/repository/car_rent_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/model/car_specs_model.dart'; // ++ استيراد جديد
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// هذا الـ Provider مسؤول عن شاشة **إضافة** إعلان تأجير سيارة
class CarRentInfoProvider extends ChangeNotifier {
  final CarRentRepository _repository;
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CarRentInfoProvider()
      : _repository = CarRentRepository(ApiService()),
        _apiService = ApiService();

  // --- حالات التحميل والأخطاء ---
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // حالات تحميل مخصصة لقوائم الموديلات والتريم
  bool _isLoadingModels = false;
  bool _isLoadingTrims = false;
  bool get isLoadingModels => _isLoadingModels;
  bool get isLoadingTrims => _isLoadingTrims;
  
  // --- بيانات أفضل المعلنين ---
  List<BestAdvertiser> _topDealerAds = [];
  bool _isLoadingTopDealers = false;
  String? _topDealersError;

  List<BestAdvertiser> get topDealerAds => _topDealerAds;
  bool get isLoadingTopDealers => _isLoadingTopDealers;
  String? get topDealersError => _topDealersError;
  
  // --- خصائص إضافية لأفضل المعلنين (للتوافق مع car_rent_screen) ---
  List<BestAdvertiser> get bestAdvertiserAds => _topDealerAds;
  bool get isLoadingBestAdvertisers => _isLoadingTopDealers;
  String? get bestAdvertisersError => _topDealersError;
  
  // --- بيانات الفلاتر الديناميكية ---
  List<EmirateModel> _emirates = [];
  List<MakeModel> _makes = [];
  List<CarModel> _models = [];
  List<TrimModel> _trims = [];
  
  // --- بيانات المواصفات الديناميكية (بدلاً من الثابتة) ---
  List<String> _carTypes = [];
  List<String> _transmissionTypes = [];
  List<String> _fuelTypes = [];
  List<String> _colors = [];
  List<String> _interiorColors = [];
  List<String> _seatNumbers = [];
  final List<String> _years = List.generate(30, (index) => (DateTime.now().year - index).toString());
  
  // بيانات جهات الاتصال (مشتركة)
  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];
  List<String> _advertiserLocations = [];
  
  // --- Getters ---
  List<MakeModel> get makes => _makes;
  List<CarModel> get models => _models;
  List<TrimModel> get trims => _trims;
  
  List<String> get emirateDisplayNames => _emirates.map((e) => e.name).toList();
  List<String> get makeNames {
    List<String> names = ['All', ..._makes.map((e) => e.name).toList(), 'Other'];
    return names;
  }
  List<String> get modelNames {
    List<String> names = ['All', ..._models.map((e) => e.name).toList(), 'Other'];
    return names;
  }
  
  // Getters for ads screen without "All" option
  List<String> get makeNamesForAds {
    List<String> names = [..._makes.map((e) => e.name).toList(), 'Other'];
    return names;
  }
  List<String> get modelNamesForAds {
    List<String> names = [..._models.map((e) => e.name).toList(), 'Other'];
    return names;
  }
  List<String> get trimNames {
    List<String> names = [..._trims.map((e) => e.name).toList()];
    // إضافة خيار 'Other' إذا كان هناك موديل محدد
    if (_models.isNotEmpty) {
      names.add('Other');
    }
    return names;
  }
  List<String> get years => _years;
  List<String> get carTypes => _carTypes;
  List<String> get transmissionTypes => _transmissionTypes;
  List<String> get fuelTypes => _fuelTypes;
  List<String> get colors => _colors;
  List<String> get interiorColors => _interiorColors;
  List<String> get seatNumbers => _seatNumbers;
  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get whatsappNumbers => _whatsappNumbers;
  List<String> get advertiserLocations => _advertiserLocations;

  // --- دوال لجلب البيانات الديناميكية ---
  Future<void> fetchAllData({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // جلب البيانات بشكل متوازٍ لزيادة السرعة
      await Future.wait([
        _repository.getEmirates(),
        _repository.getMakes(),
        _repository.getCarAdSpecs(), // ++ جلب المواصفات الجديدة
        fetchContactInfo(),
      ]).then((results) {
        _emirates = results[0] as List<EmirateModel>;
        _makes = results[1] as List<MakeModel>;
        // تحليل المواصفات وتعبئة القوائم
        _parseSpecsFromApi(results[2] as List<CarSpecField>);
      });

    } catch(e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // دالة لتحليل بيانات المواصفات
  void _parseSpecsFromApi(List<CarSpecField> fields) {
    // تفريغ القوائم القديمة لضمان عدم تراكم البيانات
    _carTypes.clear();
    _transmissionTypes.clear();
    _fuelTypes.clear();
    _colors.clear();
    _interiorColors.clear();
    _seatNumbers.clear();

    for (final field in fields) {
      switch (field.fieldName) {
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
        case 'seatsNo':
          _seatNumbers = List<String>.from(field.options);
          break;
        // يمكن تجاهل الحقول الأخرى التي لا نحتاجها في قسم الإيجار
      }
    }
  }

  Future<void> fetchModelsForMake(MakeModel make, {String? token}) async {
    _isLoadingModels = true;
    _models.clear();
    _trims.clear();
    notifyListeners();
    try {
      _models = await _repository.getModels(makeId: make.id, );
    } catch(e) {
      // print("Error fetching models for ${make.name}: $e");
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  // دالة جديدة لجلب جميع الموديلات عند اختيار "All" للـ make
  Future<void> fetchAllModels({String? token}) async {
    _isLoadingModels = true;
    _models.clear();
    _trims.clear();
    notifyListeners();
    try {
      _models = await _repository.getAllModels();
    } catch(e) {
      // print("Error fetching all models: $e");
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrimsForModel(CarModel model, {String? token}) async {
    _isLoadingTrims = true;
    _trims.clear();
    notifyListeners();
    try {
      _trims = await _repository.getTrims(modelId: model.id, );
    } catch (e) {
      // print("Error fetching trims for ${model.name}: $e");
    } finally {
      _isLoadingTrims = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchContactInfo({String? token}) async {
    try {
      final authToken = token ?? await _storage.read(key: 'auth_token');
      final response = await _apiService.get('/api/contact-info', token: authToken);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        _advertiserNames = data['advertiser_names'] != null ? List<String>.from(data['advertiser_names']) : [];
        _phoneNumbers = data['phone_numbers'] != null ? List<String>.from(data['phone_numbers']) : [];
        _whatsappNumbers = data['whatsapp_numbers'] != null ? List<String>.from(data['whatsapp_numbers']) : [];
        _advertiserLocations = data['advertiser_locations'] != null ? List<String>.from(data['advertiser_locations']) : [];
      }
    } catch (e) {
      // print("Could not fetch contact info: $e");
    }
  }

  Future<bool> addContactItem(String field, String value, {required String token}) async {
    try {
      final response = await _apiService.post('/api/contact-info/add-item', data: {'field': field, 'value': value}, token: token);
      if (response['success'] == true) {
        await fetchContactInfo();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
       _error = e.toString();
       notifyListeners();
       return false;
    }
  }
  
  String? getEmirateNameFromDisplayName(String? displayName) {
    if (displayName == null) return null;
    try { return _emirates.firstWhere((e) => e.name == displayName).name; }
    catch(e) { return null; }
  }

  void clearModelsAndTrims() {
    _models.clear();
    _trims.clear();
    notifyListeners();
  }

  // دالة لجلب أفضل المعلنين لفئة تأجير السيارات
  Future<void> fetchTopDealerAds({bool forceRefresh = false}) async {
    if (!forceRefresh && _topDealerAds.isNotEmpty) return;
    
    _isLoadingTopDealers = true;
    _topDealersError = null;
    notifyListeners();
    
    try {
      // Public data - no token required
      _topDealerAds = await _repository.getBestAdvertiserAds(category: 'car_rent');
    } catch (e) {
      // print("Error fetching top dealer ads: $e");
      _topDealersError = e.toString();
    } finally {
      _isLoadingTopDealers = false;
      notifyListeners();
    }
  }
  
  // دالة إضافية للتوافق مع car_rent_screen
  Future<void> fetchBestAdvertiserAds({bool forceRefresh = false}) async {
    await fetchTopDealerAds(forceRefresh: forceRefresh);
  }
}