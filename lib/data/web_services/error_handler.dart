import 'package:dio/dio.dart';

// يمكن تحويل هذه لفئة لمعالجة أخطاء أكثر تعقيدًا في المستقبل
class ErrorHandler {
  
  // دالة ثابتة يمكن استدعاؤها مباشرة من الكلاس
  static Exception handleDioError(DioException e) {
    // لو السيرفر رد علينا بخطأ (زي 404, 500, 401)
    if (e.response != null) {
      print('Error Response Data: ${e.response?.data}');
      print('Error Response Status Code: ${e.response?.statusCode}');
      
      // هنا ممكن تفصل الأخطاء بناءً على status code
      switch (e.response?.statusCode) {
        case 400: // Bad Request
          return Exception("طلب غير صالح، تحقق من البيانات المدخلة.");
        case 401: // Unauthorized
        case 403: // Forbidden
          // افترض أن الباك اند بيرجع رسالة الخطأ في 'message'
          return Exception(e.response?.data['message'] ?? "بيانات الدخول غير صحيحة.");
        case 404: // Not Found
          // For search/browse endpoints, return a more specific error
          // This will help identify if the API endpoints are actually missing
          final endpoint = e.requestOptions.path;
          return Exception("API endpoint not found: $endpoint - البيانات المطلوبة غير موجودة.");
        case 422: // Validation Error
          // للأخطاء التحقق من صحة البيانات، نحتفظ بالرسالة الأصلية
          final responseData = e.response?.data;
          if (responseData != null && responseData is Map) {
            // إذا كان هناك أخطاء في حقول معينة
            if (responseData['errors'] != null) {
              return Exception("VALIDATION_ERROR:${responseData.toString()}");
            }
            // إذا كان هناك رسالة عامة
            if (responseData['message'] != null) {
              return Exception(responseData['message']);
            }
            // بعض الـ APIs ترجع الحقل 'error' بدلاً من 'message'
            if (responseData['error'] != null) {
              return Exception(responseData['error']);
            }
          }
          return Exception("خطأ في التحقق من صحة البيانات.");
        case 500: // Internal Server Error
        default:
          return Exception("حدث خطأ من الخادم، حاول مرة أخرى لاحقًا.");
      }
    } else {
      // لو مفيش رد من السيرفر أساسًا (مشكلة في الاتصال أو مهلة)
      print('Error sending request: $e');
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          return Exception("انتهت مهلة الاتصال بالخادم.");
      }
      return Exception("لا يمكن الاتصال بالخادم، تحقق من اتصالك بالإنترنت.");
    }
  }

  // يمكن إضافة دوال أخرى لمعالجة أنواع أخرى من الأخطاء هنا
}