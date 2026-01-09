import 'package:advertising_app/data/model/user_ads_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class UserAdsRepository {
  final ApiService _apiService;

  UserAdsRepository(this._apiService);

  /// استدعاء API للحصول على إعلانات المستخدم
  Future<UserAdsResponse> getUserAds(String userId) async {
    final response = await _apiService.get('/api/user-ads/$userId');
    
    if (response is Map<String, dynamic>) {
      return UserAdsResponse.fromJson(response);
    } else {
      throw Exception('Failed to load user ads: Unexpected response format');
    }
  }
}