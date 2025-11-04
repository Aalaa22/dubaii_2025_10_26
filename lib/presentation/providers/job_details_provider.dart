// lib/presentation/providers/job_details_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/job_ad_model.dart';
import 'package:advertising_app/data/repository/jobs_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class JobDetailsProvider extends ChangeNotifier {
  final JobsRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  JobDetailsProvider() : _repository = JobsRepository(ApiService());

  JobAdModel? _adDetails;
  bool _isLoading = false;
  String? _error;
  
  // سنضيف متغير لتخزين صور الفئات هنا أيضًا
  Map<String, String> _categoryImages = {};

  JobAdModel? get adDetails => _adDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get categoryImages => _categoryImages;

  Future<void> fetchAdDetails(int adId) async {
    _isLoading = true;
    _error = null;
    _adDetails = null;
    notifyListeners();

    try {
      // Public data - no token required for viewing job ad details
      // جلب تفاصيل الإعلان وصور الفئات في نفس الوقت
      final results = await Future.wait([
        _repository.getJobAdDetails(adId: adId),
        _repository.getJobCategoryImages(),
      ]);

      _adDetails = results[0] as JobAdModel;
      _categoryImages = results[1] as Map<String, String>;

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAdDetails(int adId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token not found');
      }
      debugPrint('=== JobDetailsProvider.updateAdDetails ===');
      debugPrint('Ad ID: $adId');
      debugPrint('Token prefix: ${token.substring(0, token.length > 12 ? 12 : token.length)}...');
      debugPrint('Update payload keys: ${data.keys.toList()}');
      debugPrint('salary=${data['salary']}, description=${data['description']}, contact_info=${data['contact_info']}');
      await _repository.updateJobAd(adId, data, token);
      // After updating, you might want to refetch the ad details
      // to ensure the UI is displaying the most up-to-date information.
      await fetchAdDetails(adId);
    } catch (e) {
      _error = e.toString();
      debugPrint('=== JobDetailsProvider.updateAdDetails ERROR ===');
      debugPrint(_error ?? 'Unknown error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}