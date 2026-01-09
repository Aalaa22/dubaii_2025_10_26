import 'package:flutter/material.dart';
import 'package:advertising_app/data/repository/settings_repository.dart';
import 'package:advertising_app/data/model/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository;

  SettingsProvider(this._settingsRepository);

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error state
  String? _error;
  String? get error => _error;

  // Settings data
  SystemSettings? _systemSettings;
  SystemSettings? get systemSettings => _systemSettings;

  // Fetch system settings from API
  Future<void> fetchSystemSettings({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final settingsData = await _settingsRepository.getSystemSettings();
      _systemSettings = SystemSettings(settingsData);
    } catch (e) {
      _error = e.toString();
      // Use default settings in case of error
      _systemSettings = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods to get specific settings with fallback values
  double getPlanPrice(String planType) {
    if (_systemSettings == null) {
      // Default fallback values
      switch (planType) {
        case 'premium_star':
          return 50.0;
        case 'premium':
          return 35.0;
        case 'featured':
          return 15.0;
        default:
          return 0.0;
      }
    }

    switch (planType) {
      case 'premium_star':
        return _systemSettings!.planPricePremiumStar;
      case 'premium':
        return _systemSettings!.planPricePremium;
      case 'featured':
        return _systemSettings!.planPriceFeatured;
      default:
        return 0.0;
    }
  }

  int getPlanDuration(String planType) {
    if (_systemSettings == null) {
      // Default fallback values
      switch (planType) {
        case 'premium_star':
          return 30;
        case 'premium':
          return 15;
        case 'featured':
          return 7;
        default:
          return 30;
      }
    }

    switch (planType) {
      case 'premium_star':
        return _systemSettings!.planDurationPremiumStar;
      case 'premium':
        return _systemSettings!.planDurationPremium;
      case 'featured':
        return _systemSettings!.planDurationFeatured;
      default:
        return 30;
    }
  }

  int getFreeAdCycleDays() {
    return _systemSettings?.freeAdCycleDays ?? 30;
  }

  bool canPostFreeAd(double adPrice) {
    final maxPrice = _systemSettings?.maxPriceFreeAdCarsSales ?? 120000;
    return adPrice <= maxPrice;
  }
}