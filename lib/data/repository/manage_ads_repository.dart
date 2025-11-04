import 'package:advertising_app/data/model/my_ad_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class ManageAdsRepository {
  final ApiService _apiService;
  ManageAdsRepository(this._apiService);

  Future<MyAdsResponse> getMyAds({String? token}) async {
    // يمكن إضافة query parameters هنا إذا احتجت للـ pagination
    // مثال: final response = await _apiService.get('/api/my-ads', token: token, query: {'page': 1});
    final response = await _apiService.get('/api/my-ads', token: token);

    if (response is Map<String, dynamic>) {
      return MyAdsResponse.fromJson(response);
    }
    
    throw Exception('Failed to parse MyAdsResponse');
  }


  Future<void> activateOffer({
    required String token,
    required int adId,
    required String categorySlug,
    required int days,
  }) async {
    final body = {
      'ad_id': adId,
      'category_slug': categorySlug,
      'days': days,
    };
    
    try {
      // استخدم دالة 'post' الموجودة في ApiService
      final response = await _apiService.post('/api/offers-box/activate', data: body, token: token);
    } catch (e) {
      rethrow;
    }
  }

  // إضافة دالة حذف إعلان بحسب الفئة
  Future<void> deleteAd({
    required String token,
    required int id,
    required String category,
  }) async {
    String endpointBase = _resolveEndpointBase(category);
    final endpoint = '$endpointBase/$id';

    try {
      await _apiService.delete(endpoint, token: token);
    } catch (e) {
      rethrow;
    }
  }

  // إرسال طلب جعل الإعلان "Rank One" بحسب الفئة ورقم الإعلان
  Future<void> makeRankOne({
    required String token,
    required String category,
    required int adId,
  }) async {
    final body = {
      'category': category,
      'ad_id': adId,
    };

    try {
      await _apiService.post('/api/make-rank-one', data: body, token: token);
    } catch (e) {
      rethrow;
    }
  }

  String _resolveEndpointBase(String category) {
    final c = category.toLowerCase().trim();
    if (c.contains('real') && (c.contains('estate') || c.contains('state'))) {
      return '/api/real-estate';
    } else if (c.contains('cars sales') || (c.contains('car') && c.contains('sale'))) {
      return '/api/car-sales-ads';
    } else if (c.contains('car rent') || (c.contains('car') && c.contains('rent'))) {
      return '/api/car-rent-ads';
    } else if (c.contains('car services') || (c.contains('car') && c.contains('service'))) {
      return '/api/car-services-ads';
    } else if (c.contains('restaurant')) {
      return '/api/restaurants';
    } else if (c.contains('job') || c.contains('jop') || c.contains('jobs')) {
      return '/api/jobs';
    } else if (c.contains('electronics')) {
      return '/api/electronics';
    } else if (c.contains('other services')) {
      return '/api/other-services';
    }
    throw Exception('Unknown category for deletion: $category');
  }
}