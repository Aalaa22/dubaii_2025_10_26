// lib/data/repository/jobs_repository.dart
import 'package:advertising_app/data/model/job_ad_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class JobsRepository {
  final ApiService _apiService;
  JobsRepository(this._apiService);

  Future<JobAdResponse> getJobAds({String? token, Map<String, dynamic>? query}) async {
    try {
      final response = await _apiService.get('/api/jobs', query: query);
      
      // Handle different response formats
      if (response is Map<String, dynamic>) {
        // Check if response has the expected structure with 'data' key
        if (response.containsKey('data')) {
          return JobAdResponse.fromJson(response);
        }
        
        // Check if response has 'ads' key (alternative format)
        if (response.containsKey('ads')) {
          final transformedResponse = {
            'data': response['ads'],
            'total': response['total'] ?? response['count'] ?? 0,
          };
          return JobAdResponse.fromJson(transformedResponse);
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
        return JobAdResponse.fromJson(transformedResponse);
      }
      
      // Handle null or empty response
      if (response == null) {
        final emptyResponse = {
          'data': <Map<String, dynamic>>[],
          'total': 0,
        };
        return JobAdResponse.fromJson(emptyResponse);
      }
      
      throw Exception('Unexpected response type: ${response.runtimeType}');
      
    } catch (e) {
      // Re-throw with more context if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      
      // Wrap other errors
      throw Exception('Failed to fetch job ads: $e');
    }
  }

  Future<List<BestAdvertiser>> getBestAdvertisers({String? token}) async {
    final response = await _apiService.get('/api/best-advertisers/jobs');
    
    if (response is List) {
      return response.map((advertiserJson) => BestAdvertiser.fromJson(advertiserJson)).toList();
    }
    
    throw Exception('API response format is not as expected for BestAdvertisers.');
  }

  Future<List<JobAdModel>> getJobOfferAds({String? token, Map<String, String>? filters}) async {
    try {
      String endpoint = '/api/jobs/offers-box/ads';
      
      // إضافة الفلاتر كـ query parameters
      Map<String, dynamic>? queryParams;
      if (filters != null && filters.isNotEmpty) {
        queryParams = Map<String, dynamic>.from(filters);
      }
      
      final response = await _apiService.get(endpoint, token: token, query: queryParams);
      
      if (response is List) {
        return response.map((json) => JobAdModel.fromJson(json)).toList();
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List).map((json) => JobAdModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for job offer ads');
      }
    } catch (e) {
      throw Exception('Failed to fetch job offer ads: $e');
    }
  }
  

  Future<Map<String, String>> getJobCategoryImages({String? token}) async {
    final response = await _apiService.get('/api/job-category-images', token: token);
    
    if (response is Map<String, dynamic> && response['success'] == true && response['data'] is Map) {
      final Map<String, dynamic> data = response['data'];
      final Map<String, String> imagesMap = {};

      data.forEach((key, value) {
        if (value is Map && value.containsKey('image')) {
          // الـ key سيكون 'job_offer' أو 'job_seeker'
          // الـ value['image'] هو مسار الصورة
          imagesMap[key] = value['image'];
        }
      });
      return imagesMap;
    }
    
    throw Exception('Failed to parse job category images.');
  }

  /// Helper to resolve image path based on `category_type` value
  /// Returns the appropriate image from the provided `imagesMap`.
  String? resolveImageForCategoryType(String? categoryType, Map<String, String> imagesMap) {
    final isOffer = (categoryType ?? '').toLowerCase().contains('offer');
    final key = isOffer ? 'job_offer' : 'job_seeker';
    return imagesMap[key];
  }


Future<JobAdModel> getJobAdDetails({required int adId, String? token}) async {
    final response = await _apiService.get('/api/jobs/$adId', token: token);
    
    if (response is Map<String, dynamic>) {
      // الـ API قد يغلف البيانات داخل مفتاح "data"
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return JobAdModel.fromJson(response['data']);
      }
      // أو قد يرسلها مباشرة (كما في المثال الذي أرسلته)
      return JobAdModel.fromJson(response);
    }
    
    throw Exception('API response format is not as expected for JobAdModel.');
  }

  Future<void> updateJobAd(int adId, Map<String, dynamic> data, String token) async {
    try {
      // نستخدم POST مع form-data مع _method=PUT حسب متطلبات الـ API
      final Map<String, dynamic> textData = {
        '_method': 'PUT',
      };

      // تحويل مفاتيح الواجهة إلى مفاتيح الـ API وإرسال الحقول المطلوبة فقط
      final dynamic priceValue = data['salary'] ?? data['price'];
      if (priceValue != null && priceValue.toString().trim().isNotEmpty) {
        // في إعلانات الوظائف، الحقل المقابل هو "salary"
        textData['salary'] = priceValue.toString();
      }

      final dynamic descriptionValue = data['description'];
      if (descriptionValue != null && descriptionValue.toString().trim().isNotEmpty) {
        textData['description'] = descriptionValue.toString();
      }

      // دعم contact_info كحقل موحد لمعلومات التواصل
      final dynamic contactInfoValue = data['contact_info'] ?? data['contactInfo'] ?? data['contact'];
      if (contactInfoValue != null && contactInfoValue.toString().trim().isNotEmpty) {
        textData['contact_info'] = contactInfoValue.toString();
      }

      final response = await _apiService.postFormData(
        '/api/jobs/$adId',
        data: textData,
        token: token,
      );
      // اطبع الاستجابة في الترمنال للتشخيص
      print('=== JOB UPDATE RESPONSE ===');
      print(response);
    } catch (e) {
      throw Exception('Failed to update job ad: $e');
    }
  }
}