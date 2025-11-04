// lib/presentation/providers/restaurants_ad_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/repository/restaurants_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RestaurantsAdProvider extends ChangeNotifier {
  final RestaurantsRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  String? _error;
  
  RestaurantsAdProvider() : _repository = RestaurantsRepository(ApiService());
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<bool> submitRestaurantAd(Map<String, dynamic> adData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _error = 'Authentication token not found';
        return false;
      }
      
      final response = await _repository.createRestaurantAd(
        token: token,
        title: adData['title'],
        description: adData['description'],
        emirate: adData['emirate'],
        district: adData['district'],
        area: adData['area'],
        priceRange: adData['price_range'],
        category: adData['category'],
        advertiserName: adData['advertiser_name'],
        phoneNumber: adData['phone_number'],
        whatsappNumber: adData['whatsapp_number'],
        address: adData['address'],
        mainImage: adData['mainImage'] as File?,
        thumbnailImages: (adData['thumbnailImages'] as List<File>?) ?? [],
        planType: adData['planType'],
        planDays: adData['planDays'],
        planExpiresAt: adData['planExpiresAt'],
        payment: adData['payment']?.toString(),
      );
      
      bool success = false;
      String? apiMessage;
      if (response is Map<String, dynamic>) {
        success = response['success'] == true || response.containsKey('id');
        apiMessage = response['message']?.toString();
      } else {
        success = true;
      }

      if (success) {
        return true;
      } else {
        _error = apiMessage ?? 'فشل إنشاء إعلان المطاعم';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}