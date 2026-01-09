import 'package:advertising_app/data/web_services/api_service.dart';

class ReportRepository {
  final ApiService _apiService;

  ReportRepository(this._apiService);

  Future<Map<String, dynamic>> reportAd({
    required String adType,
    required int adId,
    required String reason,
    required String description,
    String? token,
  }) async {
    final data = {
      "ad_type": adType,
      "ad_id": adId,
      "reason": reason,
      "description": description,
    };

    try {
      final response = await _apiService.post(
        '/api/reports',
        data: data,
        token: token,
      );
      
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
