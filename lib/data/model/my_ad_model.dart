class MyAdModel {
  final int id;
  final String title;
  final String? planType;
  final String mainImageUrl;
  final String price;
  final String status;
  final String category;
  final String createdAt;
  // نوع الفئة للوظائف (Job Offer / Job Seeker)
  final String? categoryType;
  // إضافة حقول Make, Model, Trim للسيارات
  final String? make;
  final String? model;
  final String? trim;
  final String? year;
  // إضافة حقول المطاعم وخدمات السيارات
  final String? description;
  final String? emirate;
  final String? district;
  final String? area;
  final String? priceRange;
  final String? serviceType;
  final String? serviceName;
  final String categorySlug;
  MyAdModel({
    required this.id,
    required this.title,
    this.planType,
    required this.mainImageUrl,
    required this.price,
    required this.status,
    required this.category,
    required this.createdAt,
    required this.categorySlug,
    this.categoryType,
    this.make,
    this.model,
    this.trim,
    this.year,
    this.description,
    this.emirate,
    this.district,
    this.area,
    this.priceRange,
    this.serviceType,
    this.serviceName,
  });

  factory MyAdModel.fromJson(Map<String, dynamic> json) {
    // Normalize planType from various possible API shapes
    String? _extractPlanType(Map<String, dynamic> j) {
      // Direct keys first (snake_case and camelCase)
      var raw = j['plan_type'] ?? j['planType'];

      // Some payloads might nest plan info in 'plan' object/string
      if (raw == null && j['plan'] != null) {
        final planVal = j['plan'];
        if (planVal is String) raw = planVal;
        if (planVal is Map) raw = planVal['type'] ?? planVal['plan_type'] ?? planVal['name'];
      }

      // Fallback to priority field used by several models
      if (raw == null && j['priority'] != null) {
        final p = j['priority'].toString().toLowerCase();
        if (p.contains('featured')) raw = 'featured';
        if (p.contains('premium_star')) raw = 'premium_star';
        if (p == 'premium') raw = 'premium';
      }

      // Fallback to boolean flags indicating premium/featured status
      if (raw == null) {
        final offersActive = (j['active_offers_box_status'] == true);
        final isFeatured = (j['is_featured'] == true) || (j['featured'] == true);
        if (isFeatured) raw = 'featured';
        else if (offersActive) raw = 'premium';
      }

      // Normalize to string
      return raw?.toString();
    }

    return MyAdModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? (json['id'] is int ? json['id'] as int : 0),
      title: json['title']?.toString() ?? '',
      // Support multiple shapes for plan type to ensure visibility across categories
      planType: _extractPlanType(json),
      mainImageUrl: json['main_image_url']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      // في إعلانات الوظائف قد يأتي الحقل باسم category_type أو contract_type
      categoryType: json['category_type']?.toString() ?? json['contract_type']?.toString(),
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      trim: json['trim']?.toString(),
      year: json['year']?.toString(),
      description: json['description']?.toString(),
      emirate: json['emirate']?.toString(),
      district: json['district']?.toString(),
      area: json['area']?.toString(),
      priceRange: json['price_range']?.toString(),
      serviceType: json['service_type']?.toString(),
      serviceName: json['service_name']?.toString(),
      categorySlug: json['category_slug']?.toString() ?? '',
    );
  }
}

class MyAdsResponse {
  final List<MyAdModel> ads;
  final int total;
  final int currentPage;
  final int lastPage;

  MyAdsResponse({
    required this.ads,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  factory MyAdsResponse.fromJson(Map<String, dynamic> json) {
    // Be tolerant to various API shapes: data, ads, or null
    List<dynamic> rawList = const [];
    if (json['data'] is List) {
      rawList = json['data'] as List;
    } else if (json['ads'] is List) {
      rawList = json['ads'] as List;
    } else {
      rawList = const [];
    }

    final parsedAds = rawList
        .whereType<Map<String, dynamic>>()
        .map((ad) => MyAdModel.fromJson(ad))
        .toList();

    final total = json['total'] ?? json['total_ads'] ?? json['count'] ?? parsedAds.length;
    final currentPage = json['current_page'] ?? json['currentPage'] ?? 1;
    final lastPage = json['last_page'] ?? json['lastPage'] ?? 1;

    return MyAdsResponse(
      ads: parsedAds,
      total: total is int ? total : int.tryParse(total.toString()) ?? parsedAds.length,
      currentPage: currentPage is int ? currentPage : int.tryParse(currentPage.toString()) ?? 1,
      lastPage: lastPage is int ? lastPage : int.tryParse(lastPage.toString()) ?? 1,
    );
  }
}