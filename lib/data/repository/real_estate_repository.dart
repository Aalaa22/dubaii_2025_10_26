// // lib/data/repository/real_estate_repository.dart
// import 'package:advertising_app/data/model/car_service_filter_models.dart';
// import 'package:advertising_app/data/model/real_estate_ad_model.dart';
// import 'package:advertising_app/data/model/real_estate_options_model.dart';
// import 'package:advertising_app/data/web_services/api_service.dart';

// class RealEstateRepository {
//   final ApiService _apiService;
//   RealEstateRepository(this._apiService);

//   Future<RealEstateAdResponse> getRealEstateAds({String? token, Map<String, dynamic>? query}) async {
//     final response = await _apiService.get('/api/real-estates', token: token, query: query);
    
//     if (response is Map<String, dynamic>) {
//       return RealEstateAdResponse.fromJson(response);
//     }
    
//     throw Exception('API response format is not as expected for RealEstateAdResponse.');
//   }


//   Future<RealEstateOptions> getRealEstateOptions({String? token}) async {
//     final response = await _apiService.get('/api/real_estate_options', token: token);
//     if (response is Map<String, dynamic>) {
//       return RealEstateOptions.fromJson(response);
//     }
//     throw Exception('Failed to parse real estate options.');
//   }
  
//   // دالة لجلب الإمارات (معاد استخدامها)
//   Future<List<EmirateModel>> getEmirates({String? token}) async {
//     final response = await _apiService.get('/api/locations/emirates', token: token);
//     if (response is Map<String, dynamic> && response.containsKey('emirates')) {
//       return (response['emirates'] as List).map((json) => EmirateModel.fromJson(json)).toList();
//     }
//     throw Exception('Failed to parse emirates from API response.');
//   }
  
//   // دالة لإنشاء إعلان عقار جديد
//   Future<void> createRealEstateAd({
//     String? token,
//     required Map<String, dynamic> adData
//   }) async {
//     final Map<String, dynamic> textData = {
//       'title': adData['title'],
//       'description': adData['description'],
//       'emirate': adData['emirate'],
//       'district': adData['district'],
//       'area': adData['area'],
//       'price': adData['price'],
//       'contract_type': adData['contract_type'],
//       'property_type': adData['property_type'],
//       'advertiser_name': adData['advertiser_name'],
//       'phone_number': adData['phone_number'],
//       'whatsapp_number': adData['whatsapp_number'],
//       'address': adData['address'],
//       'plan_type': adData['planType'],
//       'plan_days': adData['planDays'],
//       'plan_expires_at': adData['planExpiresAt'],
//     };

//     await _apiService.postFormData(
//       '/api/real-estates', // Endpoint for creating real estate ads
//       data: textData,
//       mainImage: adData['mainImage'],
//       thumbnailImages: adData['thumbnailImages'],
//       token: token,
//     );
//   }
// }

// lib/data/repository/real_estate_repository.dart

import 'dart:io';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/model/offer_box_model.dart';
import 'package:advertising_app/data/model/real_estate_options_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/model/real_estate_ad_model.dart';

class RealEstateRepository {
  final ApiService _apiService;
  RealEstateRepository(this._apiService);

  Future<RealEstateAdResponse> getRealEstateAds({ Map<String, dynamic>? query}) async {
    try {
      final response = await _apiService.get('/api/real-estates', query: query);
      
      // Handle different response formats
      if (response is Map<String, dynamic>) {
        // Check if response has the expected structure with 'data' key
        if (response.containsKey('data')) {
          return RealEstateAdResponse.fromJson(response);
        }
        
        // Check if response has 'ads' key (alternative format)
        if (response.containsKey('ads')) {
          final transformedResponse = {
            'data': response['ads'],
            'total': response['total'] ?? response['count'] ?? 0,
          };
          return RealEstateAdResponse.fromJson(transformedResponse);
        }
        
        // Check if it's an error response
        if (response.containsKey('error') || response.containsKey('message')) {
          final errorMessage = response['error'] ?? response['message'] ?? 'Unknown API error';
          throw Exception('API Error: $errorMessage');
        }
        
        // If response is a map but doesn't have expected keys, throw error
        throw Exception('Unexpected API response format: ${response.keys.join(', ')}');
      }
      
      // Handle direct list response
      if (response is List) {
        final transformedResponse = {
          'data': response,
          'total': response.length,
        };
        return RealEstateAdResponse.fromJson(transformedResponse);
      }
      
      // Handle null or empty response
      if (response == null) {
        final emptyResponse = {
          'data': <Map<String, dynamic>>[],
          'total': 0,
        };
        return RealEstateAdResponse.fromJson(emptyResponse);
      }
      
      throw Exception('Unexpected response type: ${response.runtimeType}');
      
    } catch (e) {
      // Re-throw with more context if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      
      // Wrap other errors
      throw Exception('Failed to fetch real estate ads: $e');
    }
  }

  // --- دوال لجلب بيانات الفلاتر لشاشة الإضافة ---
  Future<RealEstateOptions> getRealEstateOptions() async {
    final response = await _apiService.get('/api/real_estate_options');
    if (response is Map<String, dynamic>) {
      return RealEstateOptions.fromJson(response);
    }
    throw Exception('Failed to parse real estate options.');
  }

  Future<List<EmirateModel>> getEmirates() async {
    final response = await _apiService.get('/api/locations/emirates');
    if (response is Map<String, dynamic> && response.containsKey('emirates')) {
      return (response['emirates'] as List).map((json) => EmirateModel.fromJson(json)).toList();
    }
    throw Exception('Failed to parse emirates from API response.');
  }

  // دالة لجلب تفاصيل عقار واحد
  Future<RealEstateAdModel> getRealEstateDetails({ required String id}) async {
    // Use plural endpoint to match RESTful resource routes
    final response = await _apiService.get('/api/real-estates/$id');
    if (response is Map<String, dynamic>) {
      return RealEstateAdModel.fromJson(response);
    }
    throw Exception('Failed to parse real estate details from API response.');
  }

  // --- دالة لجلب عروض العقارات ---
  Future<List<OfferBoxModel>> getRealEstateOffers( {Map<String, dynamic>? query}) async {
    try {
      print('=== RealEstateRepository: استدعاء API ===');
      print('URL: /api/offers-box/real-estate');
      print('Query: $query');
     
      
      final response = await _apiService.get('/api/offers-box/real-estate', query: query);
      print('API Response type: ${response.runtimeType}');
      print('API Response: $response');
      
      // Handle direct List response
      if (response is List) {
        print('Data type: List<dynamic>');
        print('Data length: ${response.length}');
        
        final offers = response.map((json) => OfferBoxModel.fromJson(json)).toList();
        print('تم تحويل ${offers.length} عنصر بنجاح');
        return offers;
      }
      // Handle Map response with data key (fallback)
      else if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          final data = response['data'];
          print('Data type: ${data.runtimeType}');
          print('Data length: ${data is List ? data.length : 'Not a list'}');
          
          if (data is List) {
            final offers = data.map((json) => OfferBoxModel.fromJson(json)).toList();
            print('تم تحويل ${offers.length} عنصر بنجاح');
            return offers;
          } else {
            throw Exception('البيانات المستلمة ليست قائمة: ${data.runtimeType}');
          }
        } else {
          throw Exception('الاستجابة لا تحتوي على مفتاح data: ${response.keys}');
        }
      } else {
        throw Exception('نوع الاستجابة غير متوقع: ${response.runtimeType}');
      }
    } catch (e) {
      print('خطأ في getRealEstateOffers: $e');
      rethrow;
    }
  }

  // --- دالة إنشاء إعلان عقار جديد ---
  Future<dynamic> createRealEstateAd({
    required String token,
    required Map<String, dynamic> adData
  }) async {
    
    final Map<String, dynamic> textData = {
      'title': adData['title'],
      'description': adData['description'],
      'emirate': adData['emirate'],
      'district': adData['district'],
      'area': adData['area'],
      'price': adData['price'],
      'contract_type': adData['contract_type'],
      'property_type': adData['property_type'],
      'advertiser_name': adData['advertiser_name'],
      'phone_number': adData['phone_number'],
      'whatsapp_number': adData['whatsapp_number'],
      'address': adData['address'],
      'plan_type': adData['planType'],
      'plan_days': adData['planDays'],
      'plan_expires_at': adData['planExpiresAt'],
    };

    // Only include payment when explicitly set by payment step
    if (adData['payment'] != null) {
      textData['payment'] = adData['payment'].toString();
    }

    final response = await _apiService.postFormData(
      '/api/real-estate',
      data: textData,
      mainImage: adData['mainImage'],
      thumbnailImages: adData['thumbnailImages'],
      token: token,
    );
    return response;
  }
}