import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/repository/user_packages_repository.dart';

class UserPackagesProvider extends ChangeNotifier {
  final UserPackagesRepository _repository = UserPackagesRepository(ApiService());
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _error;
  UserPackageSummary? _summary;

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserPackageSummary? get summary => _summary;
  bool get hasPackages => _summary != null;

  Future<void> fetch({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authToken = token ?? await _storage.read(key: 'auth_token');
      final result = await _repository.fetchUserPackages(token: authToken);
      _summary = result; // may be null -> no packages
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}