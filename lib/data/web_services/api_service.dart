import 'dart:io';

import 'package:advertising_app/data/web_services/error_handler.dart';
import 'package:dio/dio.dart';
import 'package:advertising_app/constant/string.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(milliseconds: 60000),
      receiveTimeout: const Duration(milliseconds: 60000),
      sendTimeout: const Duration(milliseconds: 60000),
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
    ),
  );

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? query, String? token}) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    
    try {
      final response = await _dio.get(endpoint, queryParameters: query);
      return response.data;
    } on DioException catch (e) {
      // Log the error for debugging
      print('=== API GET ERROR ===');
      print('Endpoint: $endpoint');
      print('Status Code: ${e.response?.statusCode}');
      print('Error Message: ${e.message}');
      print('Response Data: ${e.response?.data}');
      print('====================');
      
      // Don't silently return empty data - let the error propagate
      // This will help identify the actual issue causing empty ad lists
      throw ErrorHandler.handleDioError(e);
    }
  }
  
  Future<dynamic> post(String endpoint, {required dynamic data, Map<String, dynamic>? query, String? token}) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    // Ensure JSON content type for normal POST requests (do not rely on global header)
    final Options jsonOptions = Options(contentType: Headers.jsonContentType);
    
    try {
      print('=== API SERVICE POST ===');
      print('URL: $baseUrl$endpoint');
      print('Data: $data');
      print('Query: $query');
      print('Headers: ${_dio.options.headers}');
      print('=======================');

      final response = await _dio.post(endpoint, data: data, queryParameters: query, options: jsonOptions);
      
      print('=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('==================');
      
      return response.data;
    } on DioException catch (e) {
      print('=== API ERROR ===');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      print('================');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('======================');
      rethrow;
    }
  }

  Future<dynamic> postFormData(
    String endpoint, {
    required Map<String, dynamic> data,
    File? mainImage,
    List<File>? thumbnailImages,
    String? token,
  }) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    // Use per-request content type for multipart/form-data
    final Options multipartOptions = Options(contentType: Headers.multipartFormDataContentType);

    // Create a new copy of the data to avoid modifying the original
    // IMPORTANT: Remove any File objects from the data map to prevent JSON conversion errors
    final Map<String, dynamic> formDataMap = {};
    data.forEach((key, value) {
      // Skip File objects in the data map
      if (value is! File && value is! List<File>) {
        formDataMap[key] = value;
      }
    });
    
    // Use FormData to combine text data and files
    final formData = FormData.fromMap(formDataMap);

    // Add main image if provided
    if (mainImage != null) {
      formData.files.add(MapEntry(
        'main_image',
        await MultipartFile.fromFile(mainImage.path),
      ));
    }
    
    // Add thumbnail images if provided
    if (thumbnailImages != null && thumbnailImages.isNotEmpty) {
      for (var i = 0; i < thumbnailImages.length; i++) {
        formData.files.add(MapEntry(
          'thumbnail_images[]',
          await MultipartFile.fromFile(thumbnailImages[i].path),
        ));
      }
    }

    try {
      print('=== API REQUEST DEBUG ===');
      print('Endpoint: $endpoint');
      print('FormData fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
      print('FormData files: ${formData.files.map((e) => e.key).join(', ')}');
      print('Headers: ${_dio.options.headers}');
      print('========================');
      
      final response = await _dio.post(endpoint, data: formData, options: multipartOptions);
      
      print('=== API RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('=========================');
      
      return response.data;
    } on DioException catch (e) {
      print('=== API ERROR DEBUG ===');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Response Status: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('======================');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('======================');
      rethrow;
    }
  }

  Future<dynamic> uploadFile(
    String endpoint, {
    required String filePath,
    required String fieldName,
    String? token,
    Map<String, dynamic>? additionalData,
  }) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    final Options multipartOptions = Options(contentType: Headers.multipartFormDataContentType);

    final formData = FormData();
    
    // Add the file
    formData.files.add(MapEntry(
      fieldName,
      await MultipartFile.fromFile(filePath),
    ));

    // Add any additional data
    if (additionalData != null) {
      additionalData.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    try {
      print('=== API UPLOAD FILE DEBUG ===');
      print('Endpoint: $endpoint');
      print('Field Name: $fieldName');
      print('File Path: $filePath');
      print('Headers: ${_dio.options.headers}');
      print('============================');
      
      final response = await _dio.post(endpoint, data: formData, options: multipartOptions);
      
      print('=== API RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('=========================');
      
      return response.data;
    } on DioException catch (e) {
      print('=== API ERROR DEBUG ===');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Response Status: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('======================');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('======================');
      rethrow;
    }
  }

  Future<dynamic> putFormData(
    String endpoint, {
    required Map<String, dynamic> data,
    File? mainImage,
    List<File>? thumbnailImages,
    String? token,
  }) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    final Options multipartOptions = Options(contentType: Headers.multipartFormDataContentType);

    // Create a copy of the data to avoid modifying the original
    final Map<String, dynamic> formDataMap = Map<String, dynamic>.from(data);
    
    // Use FormData to combine text data and files
    final formData = FormData.fromMap(formDataMap);

    // Add main image if provided
    if (mainImage != null) {
      formData.files.add(MapEntry(
        'main_image',
        await MultipartFile.fromFile(mainImage.path),
      ));
    }
    
    // Add thumbnail images if provided
    if (thumbnailImages != null && thumbnailImages.isNotEmpty) {
      for (var i = 0; i < thumbnailImages.length; i++) {
        formData.files.add(MapEntry(
          'thumbnail_images[]',
          await MultipartFile.fromFile(thumbnailImages[i].path),
        ));
      }
    }

    try {
      print('=== API PUT FORM DATA DEBUG ===');
      print('Endpoint: $endpoint');
      print('FormData fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
      print('FormData files: ${formData.files.map((e) => e.key).join(', ')}');
      print('Headers: ${_dio.options.headers}');
      print('=============================');
      
      final response = await _dio.put(endpoint, data: formData, options: multipartOptions);
      
      print('=== API RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('=========================');
      
      return response.data;
    } on DioException catch (e) {
      print('=== API ERROR DEBUG ===');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Response Status: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('======================');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('======================');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, {required dynamic data, Map<String, dynamic>? query, String? token}) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    final Options jsonOptions = Options(contentType: Headers.jsonContentType);
    
    try {
      print('=== API PUT DEBUG ===');
      print('URL: $baseUrl$endpoint');
      print('Data: $data');
      print('Query: $query');
      print('Headers: ${_dio.options.headers}');
      print('====================');

      final response = await _dio.put(endpoint, data: data, queryParameters: query, options: jsonOptions);
      
      print('=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('==================');
      
      return response.data;
    } on DioException catch (e) {
      print('=== API ERROR ===');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      print('================');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('======================');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {dynamic data, Map<String, dynamic>? query, String? token}) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    
    try {
      print('=== API DELETE DEBUG ===');
      print('URL: $baseUrl$endpoint');
      print('Data: $data');
      print('Query: $query');
      print('Headers: ${_dio.options.headers}');
      print('=======================');

      final response = await _dio.delete(endpoint, data: data, queryParameters: query);
      
      print('=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('==================');
      
      return response.data;
    } on DioException catch (e) {
      print('=== API ERROR ===');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      print('================');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('======================');
      rethrow;
    }
  }
}