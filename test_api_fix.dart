import 'package:dio/dio.dart';
import 'lib/data/web_services/api_service.dart';
import 'lib/data/web_services/error_handler.dart';

void main() async {
  print('Testing API error handling fixes...\n');
  
  final apiService = ApiService();
  
  // Test 1: Test a valid endpoint (should work)
  print('Test 1: Testing valid endpoint...');
  try {
    final response = await apiService.get('/api/car-ads');
    print('✓ Valid endpoint returned data: ${response.runtimeType}');
  } catch (e) {
    print('✗ Valid endpoint failed: $e');
  }
  
  print('\n');
  
  // Test 2: Test an invalid endpoint (should now throw proper error)
  print('Test 2: Testing invalid endpoint...');
  try {
    final response = await apiService.get('/api/nonexistent-endpoint');
    print('✗ Invalid endpoint should have thrown error but returned: ${response.runtimeType}');
  } catch (e) {
    print('✓ Invalid endpoint properly threw error: $e');
    
    // Check if the error message includes the endpoint path
    if (e.toString().contains('/api/nonexistent-endpoint')) {
      print('✓ Error message includes endpoint path for debugging');
    } else {
      print('✗ Error message does not include endpoint path');
    }
  }
  
  print('\n');
  
  // Test 3: Test error handler directly
  print('Test 3: Testing error handler...');
  final dioError = DioException(
    requestOptions: RequestOptions(path: '/api/test-endpoint'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/test-endpoint'),
      statusCode: 404,
    ),
  );
  
  final handledException = ErrorHandler.handleDioError(dioError);
  print('Error handler result: $handledException');
  
  if (handledException.toString().contains('/api/test-endpoint')) {
    print('✓ Error handler includes endpoint path in error message');
  } else {
    print('✗ Error handler does not include endpoint path');
  }
  
  print('\nAPI error handling test completed!');
}