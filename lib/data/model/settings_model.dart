class SystemSetting {
  final int id;
  final String key;
  final String value;
  final String type;
  final String description;
  final String? createdAt;
  final String? updatedAt;

  SystemSetting({
    required this.id,
    required this.key,
    required this.value,
    required this.type,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      id: json['id'],
      key: json['key'],
      value: json['value'],
      type: json['type'],
      description: json['description'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'type': type,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper methods for different data types
  int get intValue => int.tryParse(value) ?? 0;
  double get doubleValue => double.tryParse(value) ?? 0.0;
  bool get boolValue => value.toLowerCase() == 'true';
}

class SystemSettings {
  final Map<String, SystemSetting> _settings = {};

  SystemSettings(Map<String, dynamic> settingsData) {
    settingsData.forEach((key, value) {
      _settings[key] = SystemSetting.fromJson(value);
    });
  }

  SystemSetting? getSetting(String key) => _settings[key];
  
  // Convenience getters for specific settings
  int get freeAdCycleDays => getSetting('free_ad_cycle_days')?.intValue ?? 30;
  int get freeAdsLimitCarsSales => getSetting('free_ads_limit_cars_sales')?.intValue ?? 10;
  double get maxPriceFreeAdCarsSales => getSetting('max_price_free_ad_cars_sales')?.doubleValue ?? 120000;
  
  double get planPricePremiumStar => getSetting('plan_price_premium_star')?.doubleValue ?? 50.0;
  int get planDurationPremiumStar => getSetting('plan_duration_premium_star')?.intValue ?? 30;
  
  double get planPricePremium => getSetting('plan_price_premium')?.doubleValue ?? 35.0;
  int get planDurationPremium => getSetting('plan_duration_premium')?.intValue ?? 15;
  
  double get planPriceFeatured => getSetting('plan_price_featured')?.doubleValue ?? 15.0;
  int get planDurationFeatured => getSetting('plan_duration_featured')?.intValue ?? 7;
  
  bool get manualApprovalMode => getSetting('manual_approval_mode')?.boolValue ?? false;
}