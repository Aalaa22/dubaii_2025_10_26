import 'package:advertising_app/data/web_services/api_service.dart';

class SettingsRepository {
  final ApiService _apiService;

  SettingsRepository(this._apiService);

  /// Fetch system settings from API
  Future<Map<String, dynamic>> getSystemSettings({String? token}) async {
    try {
      final response = await _apiService.get('/api/settings', token: token);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch system settings: $e');
    }
  }
}