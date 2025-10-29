// lib/data/repository/other_services_repository.dart
import 'dart:io';
import 'package:advertising_app/data/model/car_service_filter_models.dart'; // Reusing EmirateModel
import 'package:advertising_app/data/model/other_service_ad_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class OtherServicesRepository {
  final ApiService _apiService;
  OtherServicesRepository(this._apiService);



    // دالة لجلب قائمة إعلانات الخدمات الأخرى
  Future<OtherServiceAdResponse> getOtherServiceAds({String? token, Map<String, dynamic>? query}) async {
    try {
      final response = await _apiService.get('/api/other-services', query: query);
      
      // Handle different response formats
      if (response is Map<String, dynamic>) {
        // Check if response has the expected structure with 'data' key
        if (response.containsKey('data')) {
          return OtherServiceAdResponse.fromJson(response);
        }
        
        // Check if response has 'ads' key (alternative format)
        if (response.containsKey('ads')) {
          final transformedResponse = {
            'data': response['ads'],
            'total': response['total'] ?? response['count'] ?? 0,
          };
          return OtherServiceAdResponse.fromJson(transformedResponse);
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
        return OtherServiceAdResponse.fromJson(transformedResponse);
      }
      
      // Handle null or empty response
      if (response == null) {
        final emptyResponse = {
          'data': <Map<String, dynamic>>[],
          'total': 0,
        };
        return OtherServiceAdResponse.fromJson(emptyResponse);
      }
      
      throw Exception('Unexpected response type: ${response.runtimeType}');
      
    } catch (e) {
      // Re-throw with more context if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      
      // Wrap other errors
      throw Exception('Failed to fetch other service ads: $e');
    }
  }


  Future<OtherServiceAdModel> getOtherServiceDetails({required int adId, String? token}) async {
    final response = await _apiService.get('/api/other-services/$adId');
    if (response is Map<String, dynamic>) {
      return OtherServiceAdModel.fromJson(response['data'] ?? response);
    }
    throw Exception('Failed to parse other service details');
  }

  // Function to fetch section types
  Future<List<String>> getSectionTypes() async {
    // Try multiple known endpoints to avoid hard 404s across environments
    final List<String> candidateEndpoints = [
      '/api/other_service_options',            // legacy
      '/api/other-services/options',           // hyphenated resource path
      '/api/filters/other-services/section-types', // filters namespace
    ];

    dynamic response;
    for (final endpoint in candidateEndpoints) {
      try {
        response = await _apiService.get(endpoint);
        break; // success
      } catch (e) {
        // Try next endpoint on network or 404 errors
        response = null;
        continue;
      }
    }

    // If options endpoints are unreachable, try deriving section types from ads
    if (response == null) {
      try {
        final OtherServiceAdResponse adsResp = await getOtherServiceAds(query: {'page': 1});
        final Set<String> uniqueTypes = adsResp.ads
            .map((ad) => ad.sectionType?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();
        if (uniqueTypes.isNotEmpty) {
          return uniqueTypes.toList()..sort();
        }
      } catch (_) {
        // swallow and fall through to final error
      }
      throw Exception('Failed to fetch section types: endpoints unreachable and no ads to infer from.');
    }

    // Parse common shapes
    // Case A: List of objects with { field_name: 'section_type', options: [...] }
    if (response is List && response.isNotEmpty) {
      final sectionTypeObject = response.first;
      if (sectionTypeObject is Map &&
          (sectionTypeObject['field_name'] == 'section_type' || sectionTypeObject['name'] == 'section_type') &&
          sectionTypeObject['options'] is List) {
        return List<String>.from((sectionTypeObject['options'] as List).map((item) => item.toString()));
      }
    }

    // Case B: Wrapped in { data: [...] }
    if (response is Map<String, dynamic>) {
      final dataList = (response['data'] is List) ? response['data'] as List : null;
      if (dataList != null && dataList.isNotEmpty) {
        final first = dataList.first;
        if (first is Map && first['options'] is List) {
          return List<String>.from((first['options'] as List).map((item) => item.toString()));
        }
      }

      // Case C: Direct list under 'section_types'
      if (response['section_types'] is List) {
        return List<String>.from((response['section_types'] as List).map((item) => item.toString()));
      }
    }

    // Fallback: derive from ads if response shape is unexpected
    try {
      final OtherServiceAdResponse adsResp = await getOtherServiceAds(query: {'page': 1});
      final Set<String> uniqueTypes = adsResp.ads
          .map((ad) => ad.sectionType?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
      if (uniqueTypes.isNotEmpty) {
        return uniqueTypes.toList()..sort();
      }
    } catch (_) {
      // ignore and throw final error
    }
    throw Exception('Failed to parse section types from API response and could not infer from ads.');
  }
  
  // Re-used function to fetch emirates
  Future<List<EmirateModel>> getEmirates({String? token}) async {
    final response = await _apiService.get('/api/locations/emirates');
    if (response is Map<String, dynamic> && response.containsKey('emirates')) {
      return (response['emirates'] as List).map((json) => EmirateModel.fromJson(json)).toList();
    }
    throw Exception('Failed to parse emirates from API response.');
  }
  
  // Function to create a new "Other Service" ad
  Future<void> createOtherServiceAd({
    required String token,
    required Map<String, dynamic> adData
  }) async {
    await _apiService.postFormData(
      '/api/other-services',
      data: {
        'title': adData['title'],
        'description': adData['description'],
        'emirate': adData['emirate'],
        'district': adData['district'],
        'area': adData['area'],
        'price': adData['price'],
        'service_name': adData['service_name'],
        'section_type': adData['section_type'],
        'advertiser_name': adData['advertiser_name'],
        'phone_number': adData['phone_number'],
        'whatsapp_number': adData['whatsapp_number'],
        'address': adData['address'],
        'plan_type': adData['planType'],
        'plan_days': adData['planDays'],
        'plan_expires_at': adData['planExpiresAt'],
      },
      mainImage: adData['mainImage'] as File?, // It has only one image
      token: token,
    );
  }


  Future<List<OtherServiceAdModel>> getOffersBoxAds({String? token, Map<String, dynamic>? query}) async {
    final response = await _apiService.get('/api/other-services/offers-box/ads', query: query);
    
    List<dynamic> adListJson = [];
    if (response is List) {
      adListJson = response;
    } else if (response is Map<String, dynamic> && response.containsKey('data') && response['data'] is List) {
      adListJson = response['data'];
    } else {
      throw Exception('API response format for offers box is not as expected.');
    }
    
    return adListJson.map((json) => OtherServiceAdModel.fromJson(json)).toList();
  }

  // Update existing Other Service ad (editable fields only)
  Future<void> updateOtherServiceAd({
    required int adId,
    required String token,
    String? price,
    String? description,
    String? phoneNumber,
    String? whatsappNumber,
    File? mainImage,
    List<File>? thumbnailImages,
  }) async {
    final Map<String, dynamic> textData = {
      '_method': 'PUT',
    };

    if (price != null) textData['price'] = price;
    if (description != null) textData['description'] = description;
    if (phoneNumber != null) textData['phone_number'] = phoneNumber;
    if (whatsappNumber != null) textData['whatsapp_number'] = whatsappNumber;

    await _apiService.postFormData(
      '/api/other-services/$adId',
      data: textData,
      mainImage: mainImage,
      thumbnailImages: thumbnailImages,
      token: token,
    );
  }


}