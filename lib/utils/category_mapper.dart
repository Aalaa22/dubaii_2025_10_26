class CategoryMapper {
  // Map display names to API format
  static const Map<String, String> _displayToApi = {
    'Real State': 'real_estate',
    'Cars Sales': 'car_sales', 
    'Car Rent': 'car_rent',
    'Car Services': 'car_services',
    'restaurant': 'restaurant',
    // دعم صيغ عرض إضافية للفئات (إنجليزية/عربية)
    'Restaurants': 'restaurant',
    'مطاعم': 'restaurant',
    // وظائف
    'Jop': 'jobs',
    'Job': 'jobs',
    'Jobs': 'jobs',
    'وظائف': 'jobs',
    'Electronics': 'electronics',
    'Other Services': 'other_services',
  };

  // Map API format to display names
  static const Map<String, String> _apiToDisplay = {
    'real_estate': 'Real State',
    'car_sales': 'Cars Sales',
    'car_rent': 'Car Rent', 
    'car_services': 'Car Services',
    'restaurant': 'restaurant',
    'jobs': 'Jop',
    'electronics': 'Electronics',
    'other_services': 'Other Services',
  };

  /// Convert display category name to API format
  /// Example: 'Cars Sales' -> 'car_sales'
  static String toApiFormat(String displayCategory) {
    return _displayToApi[displayCategory] ?? displayCategory.toLowerCase().replaceAll(' ', '_');
  }

  /// Convert API category name to display format
  /// Example: 'car_sales' -> 'Cars Sales'
  static String toDisplayFormat(String apiCategory) {
    return _apiToDisplay[apiCategory] ?? apiCategory;
  }

  /// Get all display category names
  static List<String> getAllDisplayCategories() {
    return _displayToApi.keys.toList();
  }

  /// Get all API category names
  static List<String> getAllApiCategories() {
    return _apiToDisplay.keys.toList();
  }

  /// Check if a display category is valid
  static bool isValidDisplayCategory(String category) {
    return _displayToApi.containsKey(category);
  }

  /// Check if an API category is valid
  static bool isValidApiCategory(String category) {
    return _apiToDisplay.containsKey(category);
  }
}