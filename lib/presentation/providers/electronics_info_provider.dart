// lib/presentation/providers/electronics_info_provider.dart

import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/model/best_electronics_advertiser_model.dart';
import 'package:advertising_app/data/repository/electronics_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ElectronicsInfoProvider extends ChangeNotifier {
  final ElectronicsRepository _repository;
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ElectronicsInfoProvider()
      : _repository = ElectronicsRepository(ApiService()),
        _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EmirateModel> _emirates = [];
  List<String> _sectionTypes = [];
  List<BestElectronicsAdvertiser> _bestAdvertisers = [];

  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];

  List<String> get emirateDisplayNames => _emirates.map((e) => e.name).toList();
  List<String> get sectionTypes => _sectionTypes;
  List<BestElectronicsAdvertiser> get bestAdvertisers => _bestAdvertisers;
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

  Future<void> fetchAllData(
      {String? token, bool includeContactInfo = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // اجلب البيانات العامة أولاً (لا تتطلب token)
      await Future.wait([
        _repository.getEmirates(),
        _repository.getSectionTypes(),
        _repository.getBestAdvertisers(),
      ]).then((results) {
        _emirates = results[0] as List<EmirateModel>;
        _sectionTypes = results[1] as List<String>;
        _bestAdvertisers = results[2] as List<BestElectronicsAdvertiser>;
      });

      // بشكل اختياري، اجلب معلومات التواصل إذا طُلِب ذلك فقط
      if (includeContactInfo) {
        await fetchContactInfo(token: token);
      }
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
      // إذا لم يتوفر التوكن نتجاهل طلب معلومات التواصل لأنه خاص بالمستخدم
      if (authToken == null) return;
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
        await fetchContactInfo();
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
}
