import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';

class UserAdsResponse {
  final String userId;
  final int totalAds;
  final List<UserAd> ads;

  UserAdsResponse({
    required this.userId,
    required this.totalAds,
    required this.ads,
  });

  factory UserAdsResponse.fromJson(Map<String, dynamic> json) {
    return UserAdsResponse(
      userId: json['user_id']?.toString() ?? '',
      totalAds: json['total_ads'] ?? 0,
      ads: json['ads'] != null
          ? List<UserAd>.from(json['ads'].map((ad) => UserAd.fromJson(ad)))
          : [],
    );
  }

  // تنظيم الإعلانات حسب الفئات
  Map<String, List<UserAd>> getAdsByCategory() {
    Map<String, List<UserAd>> categorizedAds = {};

    for (var ad in ads) {
      String category = _normalizeCategory(ad.addCategory);

      if (!categorizedAds.containsKey(category)) {
        categorizedAds[category] = [];
      }

      categorizedAds[category]!.add(ad);
    }

    return categorizedAds;
  }

  // الحصول على قائمة الإعلانات مرتبة حسب الفئات
  List<List<FavoriteItemInterface>> getAllItemsByCategory() {
    // ترتيب الفئات بنفس ترتيب التصنيفات في الواجهة
    final List<String> orderedCategories = [
      'car_sales', // index 0
      'real_estate', // index 1
      'electronics', // index 2
      'jobs', // index 3
      'car_rent', // index 4
      'car_services', // index 5
      'restaurant', // index 6
      'other_services', // index 7
    ];

    Map<String, List<UserAd>> categorizedAds = getAdsByCategory();
    List<List<FavoriteItemInterface>> result = [];

    // إنشاء قائمة لكل فئة بنفس الترتيب
    for (var category in orderedCategories) {
      if (categorizedAds.containsKey(category)) {
        result.add(
            categorizedAds[category]!.cast<FavoriteItemInterface>().toList());
      } else {
        // إضافة قائمة فارغة للفئات التي لا تحتوي على إعلانات
        result.add([]);
      }
    }

    return result;
  }

  // توحيد أسماء الفئات
  String _normalizeCategory(String category) {
    category = category.toLowerCase();

    // تحويل أسماء الفئات إلى الصيغة الموحدة
    switch (category) {
      case 'car sales':
      case 'carsales':
        return 'car_sales';
      case 'real estate':
      case 'realestate':
        return 'real_estate';
      case 'car rent':
      case 'carrent':
        return 'car_rent';
      case 'car services':
      case 'carservices':
        return 'car_services';
      case 'other services':
      case 'otherservices':
        return 'other_services';
      default:
        return category;
    }
  }
}

class UserAd implements FavoriteItemInterface {
  final int id;
  final int userId;
  final String title;
  final String? km;
  final String emirate;
  final String area;
  final String district;
  final String description;
  final String category; // Changed from String? to String
  final String mainImage;
  final List<String> thumbnailImages;
  final String advertiserName;
  final String? whatsappNumber;
  final String? phoneNumber;
  final String? address;
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
  final String? specs;
  // خصائص إضافية لفئات محددة
  final String? make;
  final String? model;
  final String? trim;
  final String contract_type;
  final String property_type;
  final String? year;
  final String? carType;
  final String? transType;
  final String? fuelType;
  final String? color;
  final String? interiorColor;
  final String? seatsNo;
  final String? dayRent;
  final String? monthRent;
  final String price; // Changed from String? to String
  final String? serviceType;
  final String? serviceName;
  final String location; // Changed from String? to String
  final String product_name;
  final String section_type;
  final String job_name;
  final String salary;
  // FavoriteItemInterface implementation
  @override
  String get line1 => title;

  @override
  String get details => description;

  @override
  String get date => createdAt;

  @override
  String get contact => whatsappNumber ?? phoneNumber ?? '';

  @override
  bool get isPremium => planType != null;

  @override
  List<String> get images =>
      thumbnailImagesUrls.isNotEmpty ? thumbnailImagesUrls : [mainImageUrl];

  @override
  AdPriority get priority => AdPriority.free;
  final int? activeOffersBoxRank;

  UserAd(
    this.section_type,
    this.product_name,
    this.km,
    this.specs,
    this.emirate,
    this.area,
    this.contract_type,
    this.property_type,
    this.district, this.job_name, this.salary, {
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.mainImage,
    required this.thumbnailImages,
    required this.advertiserName,
    this.whatsappNumber,
    this.phoneNumber,
    this.address,
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

    // خصائص إضافية
    this.make,
    this.model,
    this.trim,
    this.year,
    this.carType,
    this.transType,
    this.fuelType,
    this.color,
    this.interiorColor,
    this.seatsNo,
    this.dayRent,
    this.monthRent,
    required this.price,
    this.serviceType,
    this.serviceName,
    required this.location,
    this.activeOffersBoxRank,
  });

  factory UserAd.fromJson(Map<String, dynamic> json) {
    return UserAd(
      json['km']?.toString() ?? '',
      json['specs']?.toString() ?? '',
      json['emirate']?.toString() ?? '',
      json['area']?.toString() ?? '',
      json['contract_type']?.toString() ?? '',
      json['property_type']?.toString() ?? '',
      json['district']?.toString() ?? '',
      json["product_name"]?.toString() ?? '',
      json['section_type']?.toString() ?? '',
      json['salary']?.toString() ?? '',
      json['job_name']?.toString() ?? '',
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      mainImage: json['main_image']?.toString() ?? '',
      thumbnailImages: json['thumbnail_images'] != null
          ? List<String>.from(json['thumbnail_images'])
          : [],
      advertiserName: json['advertiser_name']?.toString() ?? '',
      whatsappNumber:
          json['whatsapp_number']?.toString() ?? json['whatsapp']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      address: json['address']?.toString(),
      addCategory: json['add_category']?.toString() ?? '',
      addStatus: json['add_status']?.toString() ?? '',
      adminApproved: json['admin_approved'] ?? false,
      views: json['views'] ?? 0,
      rank: json['rank'] ?? 0,
      planType: json['plan_type']?.toString(),
      planDays: json['plan_days'],
      planExpiresAt: json['plan_expires_at']?.toString(),
      activeOffersBoxStatus: json['active_offers_box_status'] ?? false,
      activeOffersBoxDays: json['active_offers_box_days'],
      activeOffersBoxExpiresAt:
          json['active_offers_box_expires_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      mainImageUrl: json['main_image_url']?.toString() ?? '',
      thumbnailImagesUrls: json['thumbnail_images_urls'] != null
          ? List<String>.from(json['thumbnail_images_urls'])
          : [],
      status: json['status']?.toString() ?? '',
      section:
          json['section']?.toString() ?? json['add_category']?.toString() ?? '',
      // خصائص إضافية
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      trim: json['trim']?.toString(),
      year: json['year']?.toString(),
      carType: json['car_type']?.toString(),
      transType: json['trans_type']?.toString(),
      fuelType: json['fuel_type']?.toString(),
      color: json['color']?.toString(),
      interiorColor: json['interior_color']?.toString(),
      seatsNo: json['seats_no']?.toString(),
      dayRent: json['day_rent']?.toString(),
      monthRent: json['month_rent']?.toString(),
      price: json['price']?.toString() ?? '',
      serviceType: json['service_type']?.toString(),
      serviceName: json['service_name']?.toString(),
      location: json['location']?.toString() ?? '',
      activeOffersBoxRank: json['active_offers_box_rank'],
    );
  }

  // تنفيذ واجهة FavoriteItemInterface
  // No need for additional getters as the properties are already defined in the class
}
