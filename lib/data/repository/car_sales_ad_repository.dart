import 'dart:io';

import 'package:advertising_app/data/model/car_ad_model.dart';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter/foundation.dart';

class CarAdRepository {
  final ApiService _apiService;
  CarAdRepository(this._apiService);

  // --- تم تحديث نوع الإرجاع (Return Type) للدالة ---
  Future<CarAdResponse> getCarAds(
      { Map<String, dynamic>? query}) async {
    // Fetching car ads with query parameters
    try {
      final response =
          await _apiService.get('/api/car-sales-ads', query: query);

      if (kDebugMode) {
        print(
            "==> CarAdRepository.getCarAds API Response Type: ${response.runtimeType}");
        print("==> CarAdRepository.getCarAds API Response: $response");
      }

      // Case 1: Response is a Map with expected structure
      if (response is Map<String, dynamic>) {
        // Check if response has the expected structure
        if (response.containsKey('data') || response.containsKey('total')) {
          return CarAdResponse.fromJson(response);
        }

        // Case 2: Response is a Map but with different structure (e.g., direct list in 'ads' key)
        if (response.containsKey('ads')) {
          return CarAdResponse(
            ads: (response['ads'] as List?)
                    ?.map((json) => CarAdModel.fromJson(json))
                    .toList() ??
                [],
            totalAds: response['total_ads'] ??
                response['totalAds'] ??
                response['count'] ??
                0,
          );
        }

        // Case 3: Response is a Map but might be an error response
        if (response.containsKey('error') || response.containsKey('message')) {
          throw Exception(
              'API Error: ${response['error'] ?? response['message']}');
        }

        // Case 4: Empty or unexpected Map structure - return empty response
        return CarAdResponse(ads: [], totalAds: 0);
      }

      // Case 5: Response is a List (direct list of ads)
      if (response is List) {
        return CarAdResponse(
          ads: response.map((json) => CarAdModel.fromJson(json)).toList(),
          totalAds: response.length,
        );
      }

      // Case 6: Response is null or empty
      if (response == null) {
        return CarAdResponse(ads: [], totalAds: 0);
      }

      // Case 7: Unexpected response type
      throw Exception(
          'Unexpected API response type: ${response.runtimeType}. Response: $response');
    } catch (e) {
      if (kDebugMode) {
        print("==> CarAdRepository.getCarAds Error: $e");
      }

      // If it's already our custom exception, re-throw it
      if (e.toString().contains('API Error:') ||
          e.toString().contains('Unexpected API response type:')) {
        rethrow;
      }

      // For other errors (network, parsing, etc.), wrap them
      throw Exception('Failed to fetch car ads: $e');
    }
  }

  // دالة إنشاء الإعلان تبقى كما هي
  Future<void> createCarAd(
      {required String title,
      required String description,
      required String make,
      required String model,
      String? trim,
      required String year,
      required String km,
      required String price,
      String? specs,
      String? carType,
      required String transType,
      String? fuelType,
      String? color,
      String? interiorColor,
      required bool warranty,
      String? engineCapacity,
      String? cylinders,
      String? horsepower,
      String? doorsNo,
      String? seatsNo,
      String? steeringSide,
      required String advertiserName,
      required String phoneNumber,
      String? whatsapp,
      required String emirate,
      required String area,
      required String advertiserType,
      required File mainImage,
      required List<File> thumbnailImages,
      required String token,
      required String planType,
      required int planDays,
      required String planExpiresAt,
      String? payment}) async {
    final String warrantyValue = warranty ? '1' : '0';

    // تنظيف قيمة engine_capacity لإزالة الحرف "L" إذا كان موجوداً
    String? cleanEngineCapacity;
    if (engineCapacity != null && engineCapacity.isNotEmpty) {
      cleanEngineCapacity = engineCapacity.replaceAll('L', '').trim();
      if (cleanEngineCapacity.isEmpty) cleanEngineCapacity = null;
    }

    // تنظيف قيمة cylinders لاستخراج الأرقام فقط
    String? cleanCylinders;
    if (cylinders != null && cylinders.isNotEmpty) {
      // استخراج الأرقام فقط من النص
      final match = RegExp(r'\d+').firstMatch(cylinders);
      if (match != null) {
        cleanCylinders = match.group(0);
      }
    }

    // تنظيف قيمة horsepower لاستخراج الأرقام والشرطة فقط
    String? cleanHorsepower;
    if (horsepower != null && horsepower.isNotEmpty) {
      // إذا كانت القيمة تحتوي على نطاق مثل "100-150", نأخذ الرقم الأول
      if (horsepower.contains('-')) {
        final parts = horsepower.split('-');
        final firstNumber = RegExp(r'\d+').firstMatch(parts[0]);
        if (firstNumber != null) {
          cleanHorsepower = firstNumber.group(0);
        }
      } else {
        // استخراج الأرقام فقط
        final match = RegExp(r'\d+').firstMatch(horsepower);
        if (match != null) {
          cleanHorsepower = match.group(0);
        }
      }
    }

    // تنظيف قيمة doors لاستخراج الأرقام فقط
    String? cleanDoorsNo;
    if (doorsNo != null && doorsNo.isNotEmpty) {
      final match = RegExp(r'\d+').firstMatch(doorsNo);
      if (match != null) {
        cleanDoorsNo = match.group(0);
      }
    }

    // تنظيف قيمة seats لاستخراج الأرقام فقط
    String? cleanSeatsNo;
    if (seatsNo != null && seatsNo.isNotEmpty) {
      final match = RegExp(r'\d+').firstMatch(seatsNo);
      if (match != null) {
        cleanSeatsNo = match.group(0);
      }
    }

    final Map<String, dynamic> textData = {
      'title': title,
      'description': description,
      'make': make,
      'model': model,
      'trim': trim,
      'year': year,
      'km': km,
      'price': price,
      'specs': specs,
      'car_type': carType,
      'trans_type': transType,
      'fuel_type': fuelType,
      'color': color,
      'interior_color': interiorColor,
      'warranty': warrantyValue,
      'engine_capacity': cleanEngineCapacity,
      'cylinders': cleanCylinders,
      'horsepower': cleanHorsepower,
      'doors_no': cleanDoorsNo,
      'seats_no': cleanSeatsNo,
      'steering_side': steeringSide,
      'advertiser_name': advertiserName,
      'phone_number': phoneNumber,
      'whatsapp': whatsapp,
      'emirate': emirate,
      'area': area,
      'advertiser_type': advertiserType,
      'plan_type': planType,
      'plan_days': planDays,
      'plan_expires_at': planExpiresAt,
    };

    if (payment != null) {
      textData['payment'] = payment;
    }

    try {
      await _apiService.postFormData(
        '/api/car-sales-ads',
        data: textData,
        mainImage: textData['mainImage'] as File,
       thumbnailImages: textData['thumbnailImages'] as List<File>,

        token: token,
        
      );
    } catch (e) {
      print('=== CAR SALES AD REPOSITORY ERROR ===');
      print('Error creating car sales ad: $e');
      print('====================================');
      rethrow;
    }
  }

  // في ملف: data/repository/car_sales_ad_repository.dart

  // --- استبدل الدالة القديمة بهذه الدالة المحدثة ---
  Future<CarAdModel> getCarAdDetails({required int adId}) async {
    final response =
        await _apiService.get('/api/car-sales-ads/$adId');

    // Parse API response for car ad details
    if (response is Map<String, dynamic>) {
      // Case 1: API response wrapped in "data" key
      if (response.containsKey('data') &&
          response['data'] is Map<String, dynamic>) {
        return CarAdModel.fromJson(response['data']);
      }

      // Case 2: Direct API response object
      else {
        return CarAdModel.fromJson(response);
      }
    }

    // إذا لم تكن أي من الحالات السابقة، إذن هناك خطأ في شكل الرد من الأساس
    throw Exception('API response is not a valid Map object for CarAdModel.');
  }

  // --- دالة جديدة لتحديث الإعلان ---
  Future<void> updateCarAd({
    required int adId,
    required String token,
    // الحقول القابلة للتعديل فقط
    required String price,
    required String description,
    required String phoneNumber,
    String? whatsapp,
    File? mainImage, // قد تكون null إذا لم يغيرها المستخدم
    List<File>? thumbnailImages, // قد تكون null
  }) async {
    final Map<String, dynamic> textData = {
      'price': price,
      'description': description,
      'phone_number': phoneNumber,
      'whatsapp': whatsapp,
    };

    // نستخدم الدالة الجديدة التي أضفناها في ApiService
    await _apiService.putFormData(
      '/api/car-sales-ads/$adId',
      data: textData,
      mainImage: mainImage,
      thumbnailImages: thumbnailImages,
      token: token,
    );
  }

  Future<List<MakeModel>> getMakes() async {
    final response = await _apiService.get('/api/filters/car-sale/makes');

    if (response is List) {
      return response.map((make) => MakeModel.fromJson(make)).toList();
    }
    // في حال كانت البيانات داخل مفتاح 'data'
    else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((make) => MakeModel.fromJson(make))
          .toList();
    }

    throw Exception('Failed to parse Makes list.');
  }

  Future<List<TrimModel>> getTrims(
      {required int modelId}) async {
    final response =
        await _apiService.get('/api/filters/car-sale/models/$modelId/trims');

    // الحالة الأولى: إذا كان الرد قائمة مباشرة
    if (response is List) {
      return response.map((trim) => TrimModel.fromJson(trim)).toList();
    }
    // الحالة الثانية: إذا كان الرد مغلفًا بـ "data"
    else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((trim) => TrimModel.fromJson(trim))
          .toList();
    }

    throw Exception(
        'Failed to parse Trims list. API response is in an unexpected format.');
  }

  // --- +++ دالة getModels المعدلة كإجراء وقائي بنفس المنطق +++ ---
  Future<List<CarModel>> getModels({required int makeId}) async {
    final response =
        await _apiService.get('/api/filters/car-sale/makes/$makeId/models');

    // الحالة الأولى: إذا كان الرد قائمة مباشرة
    if (response is List) {
      return response.map((model) => CarModel.fromJson(model)).toList();
    }
    // الحالة الثانية: إذا كان الرد مغلفًا بـ "data"
    else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((model) => CarModel.fromJson(model))
          .toList();
    }

    throw Exception(
        'Failed to parse Models list. API response is in an unexpected format.');
  }

  // --- +++ دالة جديدة لجلب جميع الـ models بدون تحديد make +++ ---
  Future<List<CarModel>> getAllModels() async {
    final response =
        await _apiService.get('/api/filters/car-sale/models');

    // الحالة الأولى: إذا كان الرد قائمة مباشرة
    if (response is List) {
      return response.map((model) => CarModel.fromJson(model)).toList();
    }
    // الحالة الثانية: إذا كان الرد مغلفًا بـ "data"
    else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((model) => CarModel.fromJson(model))
          .toList();
    }

    throw Exception(
        'Failed to parse All Models list. API response is in an unexpected format.');
  }

  Future<List<BestAdvertiser>> getBestAdvertiserAds({String? category}) async {
    // استخدام الـ endpoint الجديد مع الكاتجوري في المسار
    String endpoint = '/api/best-advertisers';
    if (category != null) {
      endpoint = '/api/best-advertisers/$category';
    }

    final response = await _apiService.get(endpoint);

    // الرد هو قائمة مباشرة
    if (response is List) {
      return response
          .map((advertiserJson) => BestAdvertiser.fromJson(advertiserJson,
              filterByCategory: category))
          .where((advertiser) => advertiser
              .ads.isNotEmpty) // فقط الـ advertisers الذين لديهم إعلانات
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((advertiserJson) => BestAdvertiser.fromJson(advertiserJson,
              filterByCategory: category))
          .where((advertiser) => advertiser
              .ads.isNotEmpty) // فقط الـ advertisers الذين لديهم إعلانات
          .toList();
    }

    throw Exception('Failed to parse Best Advertiser Ads: Expected a List.');
  }

  Future<List<CarAdModel>> getOfferAds() async {
    final response = await _apiService.get('/api/offers-box/car_sales');

    // API العروض غالبًا ما يرسل قائمة مباشرة
    if (response is List) {
      return response.map((adJson) => CarAdModel.fromJson(adJson)).toList();
    }
    // حالة احتياطية إذا كانت مغلفة بـ "data"
    else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((adJson) => CarAdModel.fromJson(adJson))
          .toList();
    }

    throw Exception('Failed to parse Offer Ads list.');
  }

  /// Get car makes and models from API
  Future<Map<String, dynamic>?> getCarMakesAndModels() async {
    try {
      final response = await _apiService.get('/api/car-makes-models');
      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Get car specifications from API
  Future<Map<String, dynamic>?> getCarSpecs() async {
    try {
      final response = await _apiService.get('/api/car-specs');
      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
