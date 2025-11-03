// lib/data/repository/car_rent_repository.dart
import 'dart:io';

import 'package:advertising_app/data/model/car_rent_ad_model.dart';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart'; // لإعادة استخدام Make, Model
import 'package:advertising_app/data/model/car_specs_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart'; // لإعادة استخدام EmirateModel
import 'package:advertising_app/data/model/best_advertiser_model.dart';

class CarRentRepository {
  final ApiService _apiService;
  CarRentRepository(this._apiService);

  // --- دالة لجلب قائمة إعلانات الإيجار (موجودة لديك) ---
  Future<CarRentAdResponse> getCarRentAds(
      {String? token, Map<String, dynamic>? query}) async {
    // print('=== CarRentRepository.getCarRentAds ===');
    // print('Query parameters: $query');
    // print('API endpoint: /api/car-rent');
    final response = await _apiService.get('/api/car-rent', query: query);

    // كن مرنًا مع أشكال الاستجابة المحتملة
    if (response is Map<String, dynamic>) {
      // الشكل المتوقع: { data: [...], total: N }
      if (response.containsKey('data')) {
        return CarRentAdResponse.fromJson(response);
      }

      // بعض الـ APIs تُرجع القائمة تحت المفتاح 'ads' أو مفاتيح أخرى
      if (response.containsKey('ads')) {
        final transformed = {
          'data': response['ads'],
          'total': response['total'] ?? response['total_ads'] ?? response['count'] ?? (response['ads'] as List?)?.length ?? 0,
        };
        return CarRentAdResponse.fromJson(transformed);
      }

      // في حال كان هناك رسالة خطأ
      if (response.containsKey('error') || response.containsKey('message')) {
        final errorMessage = response['error'] ?? response['message'] ?? 'Unknown API error';
        throw Exception('API Error: $errorMessage');
      }

      // fallback: إذا وجدنا أي قيمة من نوع List ضمن الماب، اعتبرها البيانات
      final listValue = response.values.firstWhere((v) => v is List, orElse: () => null);
      if (listValue is List) {
        final transformed = {
          'data': listValue,
          'total': listValue.length,
        };
        return CarRentAdResponse.fromJson(transformed);
      }

      // إذا وصل شكل غير متوقع، أعد استجابة فارغة بدلًا من رمي استثناء مباشرة
      return CarRentAdResponse(ads: const [], total: response['total'] ?? 0);
    }

    // أحيانًا تُرجع الـ API قائمة مباشرة
    if (response is List) {
      final transformed = {
        'data': response,
        'total': response.length,
      };
      return CarRentAdResponse.fromJson(transformed);
    }

    // التعامل مع استجابة فارغة
    if (response == null) {
      final empty = {
        'data': <Map<String, dynamic>>[],
        'total': 0,
      };
      return CarRentAdResponse.fromJson(empty);
    }

    throw Exception('Unexpected response type: ${response.runtimeType}');
  }

  // --- دالة لجلب تفاصيل إعلان إيجار واحد بالـ ID ---
  Future<CarRentAdModel> getCarRentAdDetails({
    required String adId,
    String? token,
  }) async {
    // print('=== CarRentRepository.getCarRentAdDetails ===');
    // print('Ad ID: $adId');
    // print('API endpoint: /api/car-rent-ads/$adId');

    final response = await _apiService.get('/api/car-rent/$adId', token: token);

    // print('Raw API response type: ${response.runtimeType}');
    // print('Raw API response: $response');

    if (response is Map<String, dynamic>) {
      // Check if the response has a 'data' field or is the ad data directly
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return CarRentAdModel.fromJson(response['data']);
      } else if (response.containsKey('id')) {
        // Direct ad data without wrapper
        return CarRentAdModel.fromJson(response);
      } else {
        throw Exception('Invalid response format for car rent ad details');
      }
    }
    throw Exception('API response format is not as expected for CarRentAdModel.');
  }

  // --- دوال لجلب بيانات الفلاتر لشاشة الإضافة ---
  Future<List<EmirateModel>> getEmirates({String? token}) async {
    final response =
        await _apiService.get('/api/locations/emirates', token: token);
    if (response is Map<String, dynamic> && response.containsKey('emirates')) {
      return (response['emirates'] as List)
          .map((json) => EmirateModel.fromJson(json))
          .toList();
    }
    throw Exception('Failed to parse emirates from API response.');
  }

  // نفترض أن قسم الإيجار يستخدم نفس فلاتر الماركات والموديلات
  Future<List<MakeModel>> getMakes({String? token}) async {
    final response = await _apiService.get('/api/filters/car-sale/makes');
    if (response is List) {
      return response.map((make) => MakeModel.fromJson(make)).toList();
    } else if (response is Map<String, dynamic> &&
        response.containsKey('data')) {
      return (response['data'] as List)
          .map((make) => MakeModel.fromJson(make))
          .toList();
    }
    throw Exception('Failed to parse Makes list.');
  }

  Future<List<CarModel>> getModels({required int makeId, String? token}) async {
    final response =
        await _apiService.get('/api/filters/car-sale/makes/$makeId/models');
    if (response is List) {
      return response.map((model) => CarModel.fromJson(model)).toList();
    } else if (response is Map<String, dynamic> &&
        response.containsKey('data')) {
      return (response['data'] as List)
          .map((model) => CarModel.fromJson(model))
          .toList();
    }
    throw Exception('Failed to parse Models list from API.');
  }

  // دالة جديدة لجلب جميع الموديلات بدون تحديد make
  Future<List<CarModel>> getAllModels({String? token}) async {
    final response = await _apiService.get('/api/filters/car-sale/models');
    if (response is List) {
      return response.map((model) => CarModel.fromJson(model)).toList();
    } else if (response is Map<String, dynamic> &&
        response.containsKey('data')) {
      return (response['data'] as List)
          .map((model) => CarModel.fromJson(model))
          .toList();
    }
    throw Exception('Failed to parse All Models list from API.');
  }

  Future<List<TrimModel>> getTrims(
      {required int modelId, String? token}) async {
    final response =
        await _apiService.get('/api/filters/car-sale/models/$modelId/trims');
    if (response is List) {
      return response.map((trim) => TrimModel.fromJson(trim)).toList();
    } else if (response is Map<String, dynamic> &&
        response.containsKey('data')) {
      return (response['data'] as List)
          .map((trim) => TrimModel.fromJson(trim))
          .toList();
    }
    throw Exception('Failed to parse Trims list.');
  }

  // دالة إنشاء إعلان تأجير سيارات جديد
  Future<void> createCarRentAd(
      {required String token, required Map<String, dynamic> adData}) async {
    final Map<String, dynamic> data = {
      'emirate': adData['emirate'],
      'make': adData['make'],
      'model': adData['model'],
      'trim': adData['trim'],
      'price': adData['price'],
      'year': adData['year'],
      'day_rent': adData['day_rent'],
      'month_rent': adData['month_rent'],
      'title': adData['title'],
      'car_type': adData['car_type'],
      'trans_type': adData['trans_type'],
      'fuel_type': adData['fuel_type'],
      'color': adData['color'],
      'interior_color': adData['interior_color'],
      'seats_no': adData['seats_no'],
      'area': adData['area'],
      'phone_number': adData['phone_number'],
      'whatsapp': adData['whatsapp'],
      'advertiser_name': adData['advertiser_name'],
      'description': adData['description'],
      'location': adData['location'],
      'plan_type': adData['planType'],
      'plan_days': adData['planDays'],
      'plan_expires_at': adData['planExpiresAt'],
    };

    // Include payment only when explicitly provided
    if (adData['payment'] != null) {
      data['payment'] = adData['payment'].toString();
    }

    await _apiService.postFormData(
      '/api/car-rent-ads/', // Updated endpoint as requested
      data: data,
      mainImage: adData['mainImage'],
      thumbnailImages: adData['thumbnailImages'],
      token: token,
    );
  }

  // دالة تحديث إعلان تأجير سيارات موجود
  Future<void> updateCarRentAd({
    required int adId,
    required String token,
    required Map<String, dynamic> adData,
  }) async {
    // Prepare the data map with existing images information
    final Map<String, dynamic> requestData = {
      '_method': 'PUT', // Laravel method spoofing for PUT request
      'price': adData['price'],
      'day_rent': adData['day_rent'],
      'month_rent': adData['month_rent'],
      'phone_number': adData['phone_number'],
      'whatsapp': adData['whatsapp'],
      'advertiser_name': adData['advertiser_name'],
      'description': adData['description'],
      'location': adData['location'],
    };

    await _apiService.postFormData(
      '/api/car-rent-ads/$adId',
      data: requestData,
      mainImage: adData['mainImage'],
      thumbnailImages: adData['thumbnailImages'],
      token: token,
    );
  }

  Future<List<CarSpecField>> getCarAdSpecs({String? token}) async {
    final response = await _apiService.get('/api/car-sales-ad-specs');
    if (response is Map<String, dynamic> &&
        response['success'] == true &&
        response['data'] is List) {
      final List<dynamic> fieldsJson = response['data'];
      return fieldsJson.map((json) => CarSpecField.fromJson(json)).toList();
    }
    throw Exception('Failed to parse car specs from API response');
  }

  // دالة لجلب أفضل المعلنين لفئة تأجير السيارات
  Future<List<BestAdvertiser>> getBestAdvertiserAds(
      {String? token, required String category}) async {
    // استخدام الـ category في الـ endpoint مباشرة بدلاً من query parameter
    String endpoint = '/api/best-advertisers';
    if (category.isNotEmpty) {
      endpoint = '/api/best-advertisers/$category';
    }

    final response = await _apiService.get(endpoint, token: token);

    if (response is List) {
      // استخدام الـ filterByCategory في الـ fromJson مباشرة
      List<BestAdvertiser> advertisers = response
          .map((json) =>
              BestAdvertiser.fromJson(json, filterByCategory: category))
          .where((advertiser) => advertiser
              .ads.isNotEmpty) // فقط الـ advertisers الذين لديهم إعلانات
          .toList();
      return advertisers;
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      List<BestAdvertiser> advertisers = (response['data'] as List)
          .map((json) =>
              BestAdvertiser.fromJson(json, filterByCategory: category))
          .where((advertiser) => advertiser
              .ads.isNotEmpty) // فقط الـ advertisers الذين لديهم إعلانات
          .toList();
      return advertisers;
    }

    throw Exception('Failed to parse Best Advertiser Ads from API response.');
  }
}
