import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GoogleApiService {
  static final List<String> _apiKeys = [
    dotenv.env['GOOGLE_API_KEY_1']!,
    dotenv.env['GOOGLE_API_KEY_2']!,
    dotenv.env['GOOGLE_API_KEY_3']!,
    dotenv.env['GOOGLE_API_KEY_4']!,
  ];
  int _currentApiKeyIndex = 0;

  Future<T> _makeRequest<T>(
      Future<T> Function(String apiKey) requestFunction) async {
    int keyIndex = _currentApiKeyIndex;
    for (int i = 0; i < _apiKeys.length; i++) {
      try {
        final result = await requestFunction(_apiKeys[keyIndex]);
        _currentApiKeyIndex = keyIndex; // Update successful key index
        return result;
      } catch (e) {
        print('API Key $keyIndex failed. Trying next key.');
        keyIndex = (keyIndex + 1) % _apiKeys.length;
        if (i == _apiKeys.length - 1) {
          // All keys failed
          rethrow;
        }
      }
    }
    throw Exception('All API keys failed');
  }

  Future<List<dynamic>> searchPlaces(String query, String sessionToken,
      {String language = 'en'}) async {
    return _makeRequest<List<dynamic>>((apiKey) async {
      final String encodedQuery = Uri.encodeComponent(query);
      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey&sessiontoken=$sessionToken&language=$language';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'] ?? [];
        } else if (data['status'] == 'REQUEST_DENIED' ||
            data['status'] == 'INVALID_REQUEST') {
          throw Exception(
              'API Key failed: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        } else {
          return [];
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    });
  }

  Future<Map<String, dynamic>?> getPlaceDetails(
      String placeId, String sessionToken,
      {String language = 'en'}) async {
    return _makeRequest<Map<String, dynamic>?>((apiKey) async {
      final String detailsURL =
          'https://maps.googleapis.com/maps/api/place/details/json';
      final String detailsRequest =
          '$detailsURL?place_id=$placeId&key=$apiKey&sessiontoken=$sessionToken&fields=geometry,formatted_address,name&language=$language';

      final response = await http.get(Uri.parse(detailsRequest));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          return data['result'];
        } else if (data['status'] == 'REQUEST_DENIED' ||
            data['status'] == 'INVALID_REQUEST') {
          throw Exception(
              'API Key failed: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      }
      throw Exception('Failed to get place details');
    });
  }
}