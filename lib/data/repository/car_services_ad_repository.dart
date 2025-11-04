// lib/data/repository/car_services_ad_repository.dart

import 'dart:io';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class CarServicesAdRepository {
  final ApiService _apiService;
  CarServicesAdRepository(this._apiService);

  // دالة لجلب أنواع الخدمات من الـ API
  Future<List<ServiceTypeModel>> getServiceTypes({String? token}) async {
    final response = await _apiService.get('/api/car-services/filters', token: token);

    // الـ API يرسل الأنواع داخل مفتاح "service_types"
    if (response is Map<String, dynamic> && response.containsKey('service_types')) {
      final List<dynamic> serviceTypesJson = response['service_types'];
      return serviceTypesJson.map((json) => ServiceTypeModel.fromJson(json)).toList();
    }
    throw Exception('Failed to parse service types from API response.');
  }

  // دالة لجلب الإمارات والمناطق التابعة لها
  Future<List<EmirateModel>> getEmirates({String? token}) async {
    final response = await _apiService.get('/api/locations/emirates', token: token);

    // الـ API يرسل الإمارات داخل مفتاح "emirates"
    if (response is Map<String, dynamic> && response.containsKey('emirates')) {
      final List<dynamic> emiratesJson = response['emirates'];
      return emiratesJson.map((json) => EmirateModel.fromJson(json)).toList();
    }
    throw Exception('Failed to parse emirates from API response.');
  }

  // دالة لإنشاء إعلان خدمات سيارات جديد
  Future<dynamic> createCarServiceAd({
    required String token,
    required String title,
    required String description,
    required String emirate,
    required String district,
    required String area,
    required String serviceName,
    required String serviceType,
    required String price,
    required String advertiserName,
    required String phoneNumber,
    String? whatsapp,
    String? location, // يمكن أن يكون اختياري
    required File mainImage,
    List<File>? thumbnailImages, // جعلها اختيارية
    // بيانات خطة الإعلان التي ستأتي من الصفحة التالية
    required String planType,
    required int planDays,
    required String planExpiresAt,
    String? payment,
  }) async {
    final Map<String, dynamic> textData = {
      'title': title,
      'description': description,
      'emirate': emirate,
      'district': district,
      'area': area,
      'service_name': serviceName,
      'service_type': serviceType,
      'price': price,
      'advertiser_name': advertiserName,
      'phone_number': phoneNumber,
      'whatsapp': whatsapp,
      'location': location,
      'plan_type': planType,
      'plan_days': planDays,
      'plan_expires_at': planExpiresAt,
    };

    // Include payment only when explicitly provided (i.e., user pressed Pay Now)
    if (payment != null) {
      textData['payment'] = payment;
    }

    try {
      final response = await _apiService.postFormData(
        '/api/car-services-ads',
        data: textData,
        mainImage: mainImage,
        thumbnailImages: thumbnailImages,
        token: token,
      );
      return response;
    } catch (e) {
      if (e.toString().contains('500')) {
        throw Exception('حدث خطأ في الخادم، يرجى المحاولة مرة أخرى لاحقاً');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        throw Exception('انتهت صلاحية جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
      } else if (e.toString().contains('400')) {
        throw Exception('بيانات الإعلان غير صحيحة، يرجى التحقق من جميع الحقول');
      } else {
        throw Exception('فشل في إنشاء الإعلان: ${e.toString()}');
      }
    }
  }

  Future<CarServiceAdResponse> getCarServiceAds({
    String? token,
    Map<String, dynamic>? query, // سيستخدم للفلترة لاحقًا
  }) async {
    final endpoint = (query != null && query.isNotEmpty) ? '/api/car-services/search' : '/api/car-services';

    try {
      final response = await _apiService.get(endpoint, token: token, query: query);

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return CarServiceAdResponse.fromJson(response);
        }
        if (response.containsKey('ads')) {
          final transformedResponse = {
            'data': response['ads'],
            'currentPage': response['currentPage'] ?? 1,
            'lastPage': response['lastPage'] ?? 1,
          };
          return CarServiceAdResponse.fromJson(transformedResponse);
        }
        if (response.containsKey('error') || response.containsKey('message')) {
          final errorMessage = response['error'] ?? response['message'] ?? 'Unknown API error';
          throw Exception('API Error: $errorMessage');
        }
        throw Exception('Unexpected API response format: ${response.keys.join(', ')}');
      }

      if (response is List) {
        final transformedResponse = {
          'data': response,
          'currentPage': 1,
          'lastPage': 1,
        };
        return CarServiceAdResponse.fromJson(transformedResponse);
      }

      if (response == null) {
        final emptyResponse = {
          'data': <Map<String, dynamic>>[],
          'currentPage': 1,
          'lastPage': 1,
        };
        return CarServiceAdResponse.fromJson(emptyResponse);
      }

      throw Exception('Unexpected response type: ${response.runtimeType}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch car service ads: $e');
    }
  }

  Future<List<BestAdvertiser>> getTopGarages({String? token, String? category}) async {
    String endpoint = '/api/best-advertisers';
    if (category != null) {
      endpoint = '/api/best-advertisers/$category';
    }

    final response = await _apiService.get(endpoint);

    if (response is List) {
      List<BestAdvertiser> advertisers = response
          .map((json) => BestAdvertiser.fromJson(json, filterByCategory: category))
          .where((advertiser) => advertiser.ads.isNotEmpty)
          .toList();
      return advertisers;
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      List<BestAdvertiser> advertisers = (response['data'] as List)
          .map((json) => BestAdvertiser.fromJson(json, filterByCategory: category))
          .where((advertiser) => advertiser.ads.isNotEmpty)
          .toList();
      return advertisers;
    }

    throw Exception('Failed to parse Top Garages list from API response.');
  }

  // جلب إعلانات صندوق العروض مع فلاتر اختيارية
  Future<List<CarServiceModel>> getOfferAds({String? token, Map<String, String>? filters}) async {
    try {
      String endpoint = '/api/car-services/offers-box/ads';

      Map<String, dynamic>? queryParams;
      if (filters != null && filters.isNotEmpty) {
        queryParams = Map<String, dynamic>.from(filters);
      }

      final response = await _apiService.get(endpoint, query: queryParams);

      if (response is List) {
        return response.map((json) => CarServiceModel.fromJson(json)).toList();
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List).map((json) => CarServiceModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for offer ads');
      }
    } catch (e) {
      throw Exception('Failed to fetch offer ads: $e');
    }
  }

  // جلب تفاصيل إعلان خدمات سيارات محدد
  Future<CarServiceModel> getCarServiceAdDetails({required int adId, String? token}) async {
    final response = await _apiService.get('/api/car-services-ads/$adId', token: token);
    if (response is Map<String, dynamic>) {
      final json = response['data'] ?? response;
      return CarServiceModel.fromJson(json);
    }
    throw Exception('Failed to parse car service ad details.');
  }

  // طريقة أبسط كما اقترحت: جلب إعلان الخدمة مباشرة عبر `/api/car-services/:id`
  Future<CarServiceModel> getCarServiceById({required int adId}) async {
    final response = await _apiService.get('/api/car-services/$adId');

    // دعم أشكال متعددة من الردود من الـ API
    // 1) { data: { ...obj } }
    // 2) { car_service: { ...obj } } أو { ad: { ...obj } }
    // 3) { ...obj } مباشرةً
    // 4) [ { ...obj } ] قائمة تحتوي عنصر واحد
    if (response is Map<String, dynamic>) {
      final dynamic dataField = response['data'];

      if (dataField is Map<String, dynamic>) {
        return CarServiceModel.fromJson(dataField);
      }
      if (dataField is List && dataField.isNotEmpty && dataField.first is Map<String, dynamic>) {
        return CarServiceModel.fromJson(dataField.first as Map<String, dynamic>);
      }

      // مفاتيح بديلة محتملة
      final altKeys = ['car_service', 'ad', 'item', 'result'];
      for (final key in altKeys) {
        final val = response[key];
        if (val is Map<String, dynamic>) {
          return CarServiceModel.fromJson(val);
        }
      }

      // إذا كان الرد نفسه يمثل الكائن مباشرةً (يحتوي على id)
      if (response.containsKey('id')) {
        return CarServiceModel.fromJson(response);
      }

      throw Exception('Unexpected API response shape for car service by id: ${response.keys.join(', ')}');
    }

    if (response is List) {
      if (response.isNotEmpty && response.first is Map<String, dynamic>) {
        return CarServiceModel.fromJson(response.first as Map<String, dynamic>);
      }
      throw Exception('Empty list returned for car service details.');
    }

    throw Exception('Failed to parse car service details by id. Type: ${response.runtimeType}');
  }

  // تحديث إعلان خدمات سيارات موجود (الحقول القابلة للتعديل فقط)
  Future<void> updateCarServiceAd({
    required int adId,
    required String token,
    required String price,
    required String description,
    required String phoneNumber,
    String? whatsapp,
    File? mainImage,
    List<File>? thumbnailImages,
  }) async {
    final Map<String, dynamic> textData = {
      '_method': 'PUT',
      'price': price,
      'description': description,
      'phone_number': phoneNumber,
      'whatsapp': whatsapp,
    };

    await _apiService.postFormData(
      '/api/car-services-ads/$adId',
      data: textData,
      mainImage: mainImage,
      thumbnailImages: thumbnailImages,
      token: token,
    );
  }
}