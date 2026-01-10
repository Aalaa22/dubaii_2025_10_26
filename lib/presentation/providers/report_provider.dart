import 'package:flutter/material.dart';
import 'package:advertising_app/data/repository/report_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReportProvider with ChangeNotifier {
  final ReportRepository _reportRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  ReportProvider(this._reportRepository);

  bool get isLoading => _isLoading;

  Future<void> reportAd({
    required String adType,
    required int adId,
    required String reason,
    required String description,
    String? token,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? authToken = token;
      if (authToken == null) {
        authToken = await _storage.read(key: 'auth_token');
      }

      final response = await _reportRepository.reportAd(
        adType: adType,
        adId: adId,
        reason: reason,
        description: description,
        token: authToken,
      );

      if (response['success'] == true) {
        onSuccess(response['message'] ?? 'Report sent successfully');
      } else {
        onError(response['message'] ?? 'Failed to send report');
      }
    } catch (e) {
      onError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
