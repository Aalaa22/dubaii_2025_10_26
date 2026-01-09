// lib/presentation/providers/other_services_info_provider.dart

import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/repository/other_services_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
// تم إزالة الاعتماد على FlutterSecureStorage لأن الشاشات لا يجب أن تعتمد على التوكن

class OtherServicesInfoProvider extends ChangeNotifier {
  final OtherServicesRepository _repository;
  final ApiService _apiService;
  // لا حاجة لتخزين آمن هنا، الجلب سيكون عامًا قدر الإمكان

  OtherServicesInfoProvider()
      : _repository = OtherServicesRepository(ApiService()),
        _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EmirateModel> _emirates = [];
  List<String> _sectionTypes = [];

  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];

  List<String> get emirateDisplayNames => _emirates.map((e) => e.name).toList();
  List<String> get sectionTypes => _sectionTypes;
  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get whatsappNumbers => _whatsappNumbers;

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
        _repository.getSectionTypes(),
        fetchContactInfo(token: token),
      ]).then((results) {
        _emirates = results[0] as List<EmirateModel>;
        _sectionTypes = results[1] as List<String>;
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
      // محاولة الجلب باستخدام التوكن إن وُجد، وإلا كبيانات عامة
      final response = await _apiService.get('/api/contact-info', token: token);
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

  // إضافة دالة لجلب أفضل المعلنين
  Future<List<Map<String, dynamic>>> getBestDealers() async {
    try {
      final response = await _apiService.get(
        '/api/best-advertisers/other_services',
      );
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print("Could not fetch best dealers: $e");
      return [];
    }
  }
}
