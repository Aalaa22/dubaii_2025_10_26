// lib/presentation/providers/other_services_details_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/other_service_ad_model.dart';
import 'package:advertising_app/data/repository/other_services_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class OtherServicesDetailsProvider extends ChangeNotifier {
  final OtherServicesRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  OtherServicesDetailsProvider() : _repository = OtherServicesRepository(ApiService());

  OtherServiceAdModel? _adDetails;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;

  OtherServiceAdModel? get adDetails => _adDetails;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  Future<void> fetchAdDetails(int adId) async {
    _isLoading = true;
    _error = null;
    _adDetails = null;
    notifyListeners();

    try {
      // Public data - no token required for viewing service details
      _adDetails = await _repository.getOtherServiceDetails(adId: adId);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOtherServiceAd({
    required int adId,
    String? price,
    String? description,
    String? phoneNumber,
    String? whatsappNumber,
    File? mainImage,
    List<File>? thumbnailImages,
  }) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      await _repository.updateOtherServiceAd(
        adId: adId,
        token: token,
        price: price,
        description: description,
        phoneNumber: phoneNumber,
        whatsappNumber: whatsappNumber,
        mainImage: mainImage,
        thumbnailImages: thumbnailImages,
      );

      // Refresh details after update
      _adDetails = await _repository.getOtherServiceDetails(adId: adId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}