import 'package:advertising_app/data/model/smart_search_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class SmartSearchRepository {
  final ApiService _api;
  SmartSearchRepository(this._api);

  Future<SmartSearchResponse> smartSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      return SmartSearchResponse(keyword: '', results: const []);
    }
    try {
      // Primary: GET with query param
      final resp = await _api.get('/api/smart-search', query: {'keyword': keyword});
      return SmartSearchResponse.fromJson(resp);
    } catch (_) {
      // Fallback: POST with JSON body if GET with body is required by backend
      try {
        final resp = await _api.post('/api/smart-search', data: {'keyword': keyword});
        return SmartSearchResponse.fromJson(resp);
      } catch (e) {
        // On error, return empty response to keep UI responsive
        return SmartSearchResponse(keyword: keyword, results: const []);
      }
    }
  }
}