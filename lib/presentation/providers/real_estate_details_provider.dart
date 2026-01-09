import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/real_estate_ad_model.dart';
import 'package:advertising_app/data/repository/real_estate_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RealEstateDetailsProvider extends ChangeNotifier {
  final RealEstateRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RealEstateDetailsProvider() : _repository = RealEstateRepository(ApiService());

  RealEstateAdModel? _realEstateDetails;
  bool _isLoading = false;
  String? _error;

  RealEstateAdModel? get realEstateDetails => _realEstateDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRealEstateDetails(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // إزالة الاعتماد على التوكن في طلبات GET لتفاصيل العقار
      _realEstateDetails = await _repository.getRealEstateDetails(
        id: id,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDetails() {
    _realEstateDetails = null;
    _error = null;
    notifyListeners();
  }
}