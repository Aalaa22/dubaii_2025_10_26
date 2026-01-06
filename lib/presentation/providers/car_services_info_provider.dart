// lib/presentation/providers/car_services_info_provider.dart

import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/repository/car_services_ad_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CarServicesInfoProvider extends ChangeNotifier {
  final CarServicesAdRepository _repository;
  final ApiService _apiService; // لجلب بيانات الاتصال المشتركة
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CarServicesInfoProvider()
      : _repository = CarServicesAdRepository(ApiService()),
        _apiService = ApiService();

  // --- حالات التحميل والأخطاء ---
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- قوائم البيانات ---
  List<ServiceTypeModel> _serviceTypes = [];
  List<EmirateModel> _emirates = [];
  final Map<String, List<String>> _emirateToDistrictsMap = {};

  // بيانات الاتصال المشتركة
  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];
  List<String> _locations = [];

  // --- Getters لتوفير البيانات للـ UI ---

  // يرجع قائمة بأسماء الخدمات للعرض
  List<String> get serviceTypeNames =>
      _serviceTypes.map((e) => e.name).toList();

  // يرجع قائمة بأسماء الإمارات للعرض
  List<String> get emirateNames => _emirates.map((e) => e.name).toList();

  // يرجع قائمة بالمناطق لإمارة محددة
  List<String> getDistrictsForEmirate(String? emirateDisplayName) {
    if (emirateDisplayName == null) return [];

    // البحث عن الإمارة باستخدام displayName للعثور على الاسم الحقيقي
    final emirate = _emirates.firstWhere(
      (e) => e.name == emirateDisplayName,
      orElse: () => EmirateModel(name: '', displayName: '', districts: []),
    );

    return _emirateToDistrictsMap[emirate.name] ?? [];
  }

  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get whatsappNumbers => _whatsappNumbers;
  List<String> get locations => _locations;

  // --- دوال جلب البيانات من الـ API ---

  // دالة مجمعة لجلب كل البيانات اللازمة للشاشة
  Future<void> fetchAllData({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // جلب الفلاتر الخاصة بخدمات السيارات
      final fetchedServiceTypes = await _repository.getServiceTypes();
      final fetchedEmirates = await _repository.getEmirates();

      _serviceTypes = fetchedServiceTypes;
      _emirates = fetchedEmirates;
      _buildEmirateDistrictsMap();

      // جلب بيانات الاتصال المشتركة
      await fetchContactInfo();
    } catch (e) {
      _error = "Failed to load data: ${e.toString()}";
      // يمكنك هنا استدعاء دالة لتحميل قيم افتراضية إذا أردت
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // هذه الدالة تم نسخها كما هي من CarSalesInfoProvider لأنها مشتركة
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
        _locations = data['locations'] != null
            ? List<String>.from(data['locations'])
            : [];
      } else {
        throw Exception('API returned success: false or data is null');
      }
    } catch (e) {
      // لا نغير حالة الخطأ العامة هنا، لأنه خطأ ثانوي
      // print("Could not fetch contact info: $e");
    }
    // لا حاجة لـ notifyListeners هنا لأن fetchAllData ستقوم بذلك
  }

  // هذه الدالة أيضًا مشتركة ومنسوخة
  Future<bool> addContactItem(String field, String value,
      {required String token}) async {
    // لا داعي لتغيير حالة التحميل هنا لجعل التجربة أفضل
    try {
      final response = await _apiService.post(
        '/api/contact-info/add-item',
        data: {'field': field, 'value': value},
        token: token,
      );

      if (response['success'] == true) {
        // أضف العنصر محليًا وجدد البيانات من الـ API لضمان التوافق
        await fetchContactInfo();
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'API returned success: false');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- دوال مساعدة ---

  void _buildEmirateDistrictsMap() {
    _emirateToDistrictsMap.clear();
    for (final emirate in _emirates) {
      _emirateToDistrictsMap[emirate.name] = emirate.districts;
    }
  }

  // دالة لتحويل displayName (مثل "دبي") إلى name (مثل "Dubai") لإرساله للـ API
  String? getServiceNameFromDisplayName(String? displayName) {
    if (displayName == null) return null;
    return _serviceTypes
        .firstWhere((e) => e.name == displayName,
            orElse: () => ServiceTypeModel(name: '', displayName: ''))
        .name;
  }

  String? getEmirateNameFromDisplayName(String? displayName) {
    if (displayName == null) return null;
    return _emirates
        .firstWhere((e) => e.name == displayName,
            orElse: () =>
                EmirateModel(name: '', displayName: '', districts: []))
        .name;
  }

  bool _isLoadingFilters = false;
  String? _filtersError;
  bool _isLoadingTopGarages = false;
  String? _topGaragesError;

  bool get isLoadingFilters => _isLoadingFilters;
  String? get filtersError => _filtersError;
  bool get isLoadingTopGarages => _isLoadingTopGarages;
  String? get topGaragesError => _topGaragesError;
  bool get isPageLoading => _isLoadingFilters || _isLoadingTopGarages;

  // --- قوائم البيانات ---
  List<BestAdvertiser> _topGarages = [];

  // +++ متغيرات لحفظ الفلاتر المختارة (اختيار واحد فقط) +++
  String? _selectedEmirate;
  String? _selectedServiceType;

  // --- Getters لتوفير البيانات للـ UI ---
  List<String> get serviceTypeDisplayNames {
    final List<String> names = [
      'All',
      ..._serviceTypes.map((e) => e.name).toList(),
      'Other'
    ];
    return names;
  }

  List<String> get emirateDisplayNames {
    final List<String> names = [
      'All',
      ..._emirates.map((e) => e.name).toList(),
      'Other'
    ];
    return names;
  }

  List<BestAdvertiser> get topGarages => _topGarages;

  String? get selectedEmirate => _selectedEmirate;
  String? get selectedServiceType => _selectedServiceType;

  // --- دوال تحديث الفلاتر ---
  void updateSelectedEmirate(String? selectedName) {
    _selectedEmirate = selectedName;
    notifyListeners();
  }

  void updateSelectedServiceType(String? selectedName) {
    _selectedServiceType = selectedName;
    notifyListeners();
  }

  // +++ دالة لتجهيز الفلاتر للـ API +++
  Map<String, String> getFormattedFilters() {
    final Map<String, String> filters = {};

    // التعامل مع الإمارة
    if (_selectedEmirate != null && _selectedEmirate!.isNotEmpty) {
      if (_selectedEmirate != 'All' && _selectedEmirate != 'Other') {
        filters['emirate'] = _selectedEmirate!;
      } else if (_selectedEmirate == 'All') {
        // عند اختيار All، لا نضيف فلتر للإمارة (يعرض الكل)
      } else if (_selectedEmirate == 'Other') {
        filters['emirate'] = 'Other';
      }
    }

    // التعامل مع نوع الخدمة
    if (_selectedServiceType != null && _selectedServiceType!.isNotEmpty) {
      if (_selectedServiceType != 'All' && _selectedServiceType != 'Other') {
        filters['service_type'] = _selectedServiceType!;
      } else if (_selectedServiceType == 'All') {
        // عند اختيار All، لا نضيف فلتر لنوع الخدمة (يعرض الكل)
      } else if (_selectedServiceType == 'Other') {
        filters['service_type'] = 'Other';
      }
    }

    return filters;
  }

  void clearFilters() {
    _selectedEmirate = null;
    _selectedServiceType = null;
    notifyListeners();
  }

  // --- دوال جلب البيانات ---
  Future<void> fetchLandingPageData({String? token}) async {
    _isLoadingFilters = true;
    _isLoadingTopGarages = true;
    notifyListeners();

    try {
      // جلب الفلاتر
      final fetchedServiceTypes = await _repository.getServiceTypes();
      final fetchedEmirates = await _repository.getEmirates();
      _serviceTypes = fetchedServiceTypes;
      _emirates = fetchedEmirates;
      _buildEmirateDistrictsMap(); // بناء خريطة الإمارات والمناطق
      _filtersError = null;
    } catch (e) {
      _filtersError = e.toString();
    } finally {
      _isLoadingFilters = false;
      notifyListeners();
    }

    try {
      // جلب أفضل الكراجات مع فلترة حسب الـ category
      _topGarages = await _repository.getTopGarages(category: 'car_services');
      _topGaragesError = null;
    } catch (e) {
      _topGaragesError = e.toString();
    } finally {
      _isLoadingTopGarages = false;
      notifyListeners();
    }
  }
}
