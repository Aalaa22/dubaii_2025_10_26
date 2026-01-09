// lib/presentation/providers/electronic_details_provider.dart

import 'package:advertising_app/data/model/electronics_ad_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/repository/electronics_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class ElectronicDetailsProvider extends ChangeNotifier {
  final ElectronicsRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ElectronicDetailsProvider() : _repository = ElectronicsRepository(ApiService());

  ElectronicAdModel? _adDetails;
  bool _isLoading = false;
  String? _error;

  ElectronicAdModel? get adDetails => _adDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAdDetails(int adId) async {
    _isLoading = true;
    _error = null;
    _adDetails = null;
    notifyListeners();

    try {
      // Public data - no token required for viewing electronic ad details
      _adDetails = await _repository.getElectronicAdDetails(adId: adId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}