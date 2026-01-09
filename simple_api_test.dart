import 'package:dio/dio.dart';

class SimpleApiService {
  final Dio _dio = Dio();
  
  SimpleApiService() {
    _dio.options.baseUrl = 'https://dubaisale.app';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }
  
  Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final options = Options();
      if (token != null) {
        options.headers = {'Authorization': 'Bearer $token'};
      }
      
      print('Making request to: ${_dio.options.baseUrl}$endpoint');
      final response = await _dio.get(endpoint, options: options);
      return response.data;
    } on DioException catch (e) {
      print('DioException caught: ${e.type}');
      print('Status code: ${e.response?.statusCode}');
      print('Request path: ${e.requestOptions.path}');
      
      // This is the old behavior that was causing silent failures
      if (e.response?.statusCode == 404) {
        print('404 error - endpoint not found: ${e.requestOptions.path}');
        // Instead of returning empty data, we now throw the error
        rethrow;
      }
      
      rethrow;
    }
  }
}

void main() async {
  print('Testing API error handling fixes...\n');
  
  final apiService = SimpleApiService();
  
  // Test 1: Test a potentially valid endpoint
  print('Test 1: Testing car ads endpoint...');
  try {
    final response = await apiService.get('/api/car-ads');
    print('✓ Car ads endpoint returned data type: ${response.runtimeType}');
    if (response is List) {
      print('  - Returned list with ${response.length} items');
    } else if (response is Map) {
      print('  - Returned map with keys: ${response.keys}');
    }
  } catch (e) {
    print('✗ Car ads endpoint failed: $e');
    if (e.toString().contains('404')) {
      print('  - This is a 404 error, which means the endpoint doesn\'t exist');
    }
  }
  
  print('\n');
  
  // Test 2: Test an obviously invalid endpoint
  print('Test 2: Testing invalid endpoint...');
  try {
    final response = await apiService.get('/api/definitely-nonexistent-endpoint-12345');
    print('✗ Invalid endpoint should have thrown error but returned: ${response.runtimeType}');
  } catch (e) {
    print('✓ Invalid endpoint properly threw error: $e');
  }
  
  print('\n');
  
  // Test 3: Test electronics endpoint
  print('Test 3: Testing electronics ads endpoint...');
  try {
    final response = await apiService.get('/api/electronics-ads');
    print('✓ Electronics ads endpoint returned data type: ${response.runtimeType}');
    if (response is List) {
      print('  - Returned list with ${response.length} items');
    } else if (response is Map) {
      print('  - Returned map with keys: ${response.keys}');
    }
  } catch (e) {
    print('✗ Electronics ads endpoint failed: $e');
    if (e.toString().contains('404')) {
      print('  - This is a 404 error, which means the endpoint doesn\'t exist');
    }
  }
  
  print('\nAPI error handling test completed!');
  print('\nSummary:');
  print('- If endpoints return 404 errors, the API might have changed');
  print('- If endpoints return data, the fixes are working correctly');
  print('- The key improvement is that 404 errors are now visible instead of silent');
}