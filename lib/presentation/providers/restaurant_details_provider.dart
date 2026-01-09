// lib/presentation/providers/restaurant_details_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/restaurant_ad_model.dart';
import 'package:advertising_app/data/repository/restaurants_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RestaurantDetailsProvider extends ChangeNotifier {
  final RestaurantsRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RestaurantDetailsProvider() : _repository = RestaurantsRepository(ApiService());

  RestaurantAdModel? _adDetails;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;

  RestaurantAdModel? get adDetails => _adDetails;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  Future<void> fetchAdDetails(int adId) async {
    _isLoading = true;
    _error = null;
    _adDetails = null;
    notifyListeners();

    try {
      // Public data - no token required for viewing restaurant ad details
      _adDetails = await _repository.getRestaurantAdDetails(adId: adId);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRestaurantAd({
    required int adId,
    String? priceRange,
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

      await _repository.updateRestaurantAd(
        token: token,
        adId: adId,
        priceRange: priceRange,
        description: description,
        phoneNumber: phoneNumber,
        whatsappNumber: whatsappNumber,
        mainImage: mainImage,
        thumbnailImages: thumbnailImages,
      );

      // Refresh the ad details after update
      await fetchAdDetails(adId);
      
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