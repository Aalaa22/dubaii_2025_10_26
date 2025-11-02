import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/utils/number_formatter.dart';

class FavoritesResponse {
  final bool status;
  final FavoritesData data;

  FavoritesResponse({
    required this.status,
    required this.data,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      status: json['status'] ?? false,
      data: FavoritesData.fromJson(json['data'] ?? {}),
    );
  }
}

class FavoritesData {
  final List<FavoriteItem> restaurant;
  final List<FavoriteItem> carServices;
  final List<FavoriteItem> carSales;
  final List<FavoriteItem> realEstate;
  final List<FavoriteItem> electronics;
  final List<FavoriteItem> jobs;
  final List<FavoriteItem> carRent;
  final List<FavoriteItem> otherServices;

  FavoritesData({
    this.restaurant = const [],
    this.carServices = const [],
    this.carSales = const [],
    this.realEstate = const [],
    this.electronics = const [],
    this.jobs = const [],
    this.carRent = const [],
    this.otherServices = const [],
  });

  factory FavoritesData.fromJson(Map<String, dynamic> json) {
    return FavoritesData(
      restaurant: _parseItemList(json['restaurant'] ?? json['Restaurant']),
      carServices: _parseItemList(json['car_services'] ?? json['Car Services']),
      carSales: _parseItemList(json['car_sales'] ?? json['Cars Sales']),
      realEstate: _parseItemList(json['real_estate'] ?? json['Real State']),
      electronics: _parseItemList(json['electronics'] ?? json['Electronics']),
      jobs: _parseItemList(
          json['jobs'] ?? json['Jobs'] ?? json['Jop'] ?? json['Job']),
      carRent: _parseItemList(json['car_rent'] ?? json['Car Rent']),
      otherServices:
          _parseItemList(json['other_services'] ?? json['Other Services']),
    );
  }

  static List<FavoriteItem> _parseItemList(dynamic jsonList) {
    if (jsonList == null) return [];
    return (jsonList as List)
        .map((item) => FavoriteItem.fromJson(item))
        .toList();
  }

  // Helper method to get all items as a list organized by category
  List<List<FavoriteItem>> getAllItemsByCategory() {
    return [
      carSales, // index 0 - carsales
      realEstate, // index 1 - realestate
      electronics, // index 2 - electronics
      jobs, // index 3 - jobs
      carRent, // index 4 - carrent
      carServices, // index 5 - carservices
      restaurant, // index 6 - restaurants
      otherServices, // index 7 - otherservices
    ];
  }
}

class FavoriteItem implements FavoriteItemInterface {
  final int favoriteId;
  final AdData ad;

  FavoriteItem({
    required this.favoriteId,
    required this.ad,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    // Handle the case where 'ad' might be a List or Map
    dynamic adData = json['ad'] ?? {};
    Map<String, dynamic> adMap;

    if (adData is List && adData.isNotEmpty) {
      // If 'ad' is a List, take the first item
      adMap = adData[0] as Map<String, dynamic>;
    } else if (adData is Map<String, dynamic>) {
      // If 'ad' is already a Map, use it directly
      adMap = adData;
    } else {
      // Fallback to empty map
      adMap = <String, dynamic>{};
    }

    return FavoriteItem(
      favoriteId: json['favorite_id'] ?? 0,
      ad: AdData.fromJson(adMap),
    );
  }

  // Implementation of FavoriteItemInterface
  String _slug() {
    final raw = (ad.addCategory.isNotEmpty ? ad.addCategory : ad.section).toLowerCase().trim();
    return raw;
  }

  String _safe(String? s) => (s ?? '').trim();

  bool _has(String? s) => s != null && s.trim().isNotEmpty && s.toLowerCase() != 'null';

  // Canonicalize category slug to a consistent format
  String _canonicalSlug() {
    final s = _slug().replaceAll(RegExp(r'\s+'), '_');
    switch (s) {
      // Cars Sales aliases
      case 'car_sales':
      case 'Cars Sales':
      case 'cars_sales':
      case 'car_sale':
      case 'cars_sale':
        return 'car_sales';
      // Car Services aliases
      case 'car_services':
      case 'car_service':
        return 'car_service';
      // Real Estate aliases
      case 'real_state':
      case 'real_estate':
        return 'real_estate';
      // Other Services aliases
      case 'other_services':
      case 'other_service':
        return 'other_services';
      // Jobs aliases
      case 'jobs':
      case 'job':
      case 'jop':
        return 'jobs';
      default:
        return s;
    }
  }

  @override
  String get title {
    switch (_canonicalSlug()) {
      case 'car_sales':
        // كما هو مطلوب: العنوان لسيارات البيع = السنة/الكيلو/المواصفات
        final parts = <String>[];
        final year = _safe(ad.year);
        final km = _safe(ad.km);
        final specs = _safe(ad.specs);
        if (year.isNotEmpty) parts.add('Year: $year');
        if (km.isNotEmpty) parts.add('Km: ${NumberFormatter.formatNumber(km)}');
        if (specs.isNotEmpty) parts.add('Specs: $specs');
        return parts.join('  ');
      case 'car_rent':
        return '${_safe(ad.make)} ${_safe(ad.model)} ${_safe(ad.trim)} ${_safe(ad.year)}'.trim();
      case 'car_service':
        return _has(ad.serviceName) ? _safe(ad.serviceName) : ad.title;
      default:
        return ad.title;
    }
  }

  @override
  String get location {
    switch (_canonicalSlug()) {
      case 'car_sales':
        // الأساس: الإمارة والمنطقة، ثم الحي، ثم location الخام
        final primary = '${_safe(ad.emirate)} ${_safe(ad.area)}'.trim();
        if (primary.isNotEmpty) return primary;
        if (_safe(ad.district).isNotEmpty) return _safe(ad.district);
        return _safe(ad.location);
      default:
        return '${_safe(ad.emirate)} ${_safe(ad.district)} ${_safe(ad.area)}'.trim();
    }
  }

  @override
  String get price {
    switch (_canonicalSlug()) {
      case 'jobs':
        return _safe(ad.salary).isNotEmpty ? _safe(ad.salary) : (_safe(ad.price).isNotEmpty ? _safe(ad.price) : 'غير محدد');
      case 'restaurants':
        return _safe(ad.priceRange);
      default:
        return _safe(ad.price).isNotEmpty ? _safe(ad.price) : (_safe(ad.priceRange).isNotEmpty ? _safe(ad.priceRange) : 'غير محدد');
    }
  }

  @override
  String get line1 {
    switch (_canonicalSlug()) {
      case 'car_sales':
        // كما هو مطلوب: السطر الأول يعرض الماركة/الموديل/الفئة
        return '${_safe(ad.make)} ${_safe(ad.model)} ${_safe(ad.trim)}'.trim();
      case 'car_rent':
        return 'Day ${_safe(ad.dayRent)} Month Rent ${_safe(ad.monthRent)}';
      case 'car_service':
        return ad.title;
      case 'electronics':
        return _safe(ad.sectionType);
        
      case 'jobs':
        return _safe(ad.jobName);
      case 'restaurants':
        return _safe(ad.category) == '' ? _safe(ad.addCategory) : _safe(ad.category);
      case 'other_services':
        return ad.title;
      default:
        return ad.title;
    }
  }

  @override
  String get details {
    switch (_canonicalSlug()) {
      case 'car_sales':
        return ad.title;
      case 'car_rent':
        return ad.title;
      case 'car_service':
        return _safe(ad.serviceType);
      case 'real_estate':
        return '${_safe(ad.propertyType)} ${_safe(ad.contractType)}'.trim();
      case 'electronics':
        return _safe(ad.productName);
      case 'jobs':
        final cat = _safe(ad.categoryType).isNotEmpty ? _safe(ad.categoryType) : 'N/A';
        final sec = _safe(ad.sectionType).isNotEmpty ? _safe(ad.sectionType) : 'N/A';
        return '$cat $sec';
      case 'restaurants':
        return '';
      case 'other_services':
        if (_has(ad.sectionType)) return _safe(ad.sectionType);
        if (_has(ad.serviceType)) return _safe(ad.serviceType);
        return '';
      default:
        return ad.description;
    }
  }

  @override
  String get date => ad.createdAt.split('T')[0];

  @override
  String get contact {
    switch (_canonicalSlug()) {
      case 'car_service':
      case 'real_estate':
      case 'electronics':
      case 'jobs':
      case 'restaurants':
      case 'other_services':
      case 'car_sales':
      case 'car_rent':
        return ad.advertiserName;
      default:
        return _safe(ad.whatsappNumber).isNotEmpty
            ? _safe(ad.whatsappNumber)
            : _safe(ad.phoneNumber);
    }
  }

  @override
  bool get isPremium {
    final plan = _safe(ad.planType).toLowerCase();
    if (plan.isEmpty) return false;
    return plan != 'free';
  }

  @override
  List<String> get images {
    final list = <String>[];
    bool _valid(String s) {
      final t = s.trim();
      return t.isNotEmpty && t.toLowerCase() != 'null';
    }
    final mainUrl = _safe(ad.mainImageUrl);
    final mainPath = _safe(ad.mainImage);
    if (_valid(mainUrl)) {
      list.add(mainUrl);
    } else if (_valid(mainPath)) {
      list.add(mainPath);
    }
    final thumbsUrl = ad.thumbnailImagesUrls.where(_valid).toList();
    if (thumbsUrl.isNotEmpty) {
      list.addAll(thumbsUrl);
    } else {
      list.addAll(ad.thumbnailImages.where(_valid));
    }
    return list;
  }

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;

  @override
  String get category => _safe(ad.category).isNotEmpty ? _safe(ad.category) : ad.addCategory;

  @override
  String get addCategory => ad.addCategory;

  @override
  int get id => ad.id;
}

class AdData {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String emirate;
  final String district;
  final String area;
  final String priceRange;
  final String? price;
  final String? category;
  final String mainImage;
  final List<String> thumbnailImages;
  final String advertiserName;
  final String whatsappNumber;
  final String phoneNumber;
  final String address;
  final String addCategory;
  final String addStatus;
  final bool adminApproved;
  final int views;
  final int rank;
  final String? planType;
  final int? planDays;
  final String? planExpiresAt;
  final bool activeOffersBoxStatus;
  final int? activeOffersBoxDays;
  final String? activeOffersBoxExpiresAt;
  final String createdAt;
  final double? latitude;
  final double? longitude;
  final String mainImageUrl;
  final List<String> thumbnailImagesUrls;
  final String status;
  final String section;

  // Additional fields for specific categories
  final String? serviceType;
  final String? serviceName;
  final String? location;
  // More category-specific optional fields
  final String? dayRent;
  final String? monthRent;
  final String? productName;
  final String? sectionType;
  final String? categoryType;
  final String? jobName;
  final String? salary;
  final String? propertyType;
  final String? contractType;

  // Car sales specific fields (optional, present when category is Cars Sales)
  final String? make;
  final String? model;
  final String? trim;
  final String? year;
  final String? km;
  final String? specs;
  final String? carType;
  final String? transType;
  final String? fuelType;
  final String? color;
  final String? interiorColor;
  final String? seatsNo;
  final String? doorsNo;
  final String? engineCapacity;
  final String? cylinders;
  final String? horsepower;

  AdData({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.emirate,
    required this.district,
    required this.area,
    required this.priceRange,
    this.price,
    this.category,
    required this.mainImage,
    required this.thumbnailImages,
    required this.advertiserName,
    required this.whatsappNumber,
    required this.phoneNumber,
    required this.address,
    required this.addCategory,
    required this.addStatus,
    required this.adminApproved,
    required this.views,
    required this.rank,
    this.planType,
    this.planDays,
    this.planExpiresAt,
    required this.activeOffersBoxStatus,
    this.activeOffersBoxDays,
    this.activeOffersBoxExpiresAt,
    required this.createdAt,
    this.latitude,
    this.longitude,
    required this.mainImageUrl,
    required this.thumbnailImagesUrls,
    required this.status,
    required this.section,
    this.serviceType,
    this.serviceName,
    this.location,
    this.dayRent,
    this.monthRent,
    this.productName,
    this.sectionType,
    this.categoryType,
    this.jobName,
    this.salary,
    this.propertyType,
    this.contractType,
    this.make,
    this.model,
    this.trim,
    this.year,
    this.km,
    this.specs,
    this.carType,
    this.transType,
    this.fuelType,
    this.color,
    this.interiorColor,
    this.seatsNo,
    this.doorsNo,
    this.engineCapacity,
    this.cylinders,
    this.horsepower,
  });

  factory AdData.fromJson(Map<String, dynamic> json) {
    return AdData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      emirate: json['emirate'] ?? '',
      district: json['district'] ?? '',
      area: json['area'] ?? '',
      priceRange: json['price_range'] ?? json['price'] ?? '',
      price: json['price']?.toString(),
      category: json['category'],
      mainImage: json['main_image'] ?? '',
      thumbnailImages: _parseStringList(json['thumbnail_images']),
      advertiserName: json['advertiser_name'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? json['whatsapp'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? json['location'] ?? '',
      addCategory: json['add_category'] ?? '',
      addStatus: json['add_status'] ?? '',
      adminApproved: json['admin_approved'] ?? false,
      views: json['views'] ?? 0,
      rank: json['rank'] ?? 0,
      planType: json['plan_type'],
      planDays: json['plan_days'],
      planExpiresAt: json['plan_expires_at'],
      activeOffersBoxStatus: json['active_offers_box_status'] ?? false,
      activeOffersBoxDays: json['active_offers_box_days'],
      activeOffersBoxExpiresAt: json['active_offers_box_expires_at'],
      createdAt: json['created_at'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      mainImageUrl: json['main_image_url'] ?? '',
      thumbnailImagesUrls: _parseStringList(json['thumbnail_images_urls']),
      status: json['status'] ?? '',
      section: json['section'] ?? json['add_category'] ?? '',
      serviceType: json['service_type'],
      serviceName: json['service_name'],
      location: json['location'],
      // category-specific optional fields
      dayRent: json['day_rent']?.toString(),
      monthRent: json['month_rent']?.toString(),
      productName: json['product_name']?.toString(),
      sectionType: json['section_type']?.toString(),
      categoryType: json['category_type']?.toString(),
      jobName: json['job_name']?.toString(),
      salary: json['salary']?.toString(),
      propertyType: json['property_type']?.toString(),
      contractType: json['contract_type']?.toString(),
      // Car sales specific mapping
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      trim: json['trim']?.toString(),
      year: json['year']?.toString(),
      km: json['km']?.toString(),
      specs: json['specs']?.toString(),
      carType: json['car_type']?.toString(),
      transType: json['trans_type']?.toString(),
      fuelType: json['fuel_type']?.toString(),
      color: json['color']?.toString(),
      interiorColor: json['interior_color']?.toString(),
      seatsNo: json['seats_no']?.toString(),
      doorsNo: json['doors_no']?.toString(),
      engineCapacity: json['engine_capacity']?.toString(),
      cylinders: json['cylinders']?.toString(),
      horsepower: json['horsepower']?.toString(),
    );
  }

  static List<String> _parseStringList(dynamic jsonList) {
    if (jsonList == null) return [];
    if (jsonList is List) {
      return jsonList.map((item) => item.toString()).toList();
    }
    return [];
  }
}
