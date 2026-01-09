// lib/data/model/restaurant_ad_model.dart
import 'dart:convert';

class RestaurantAdModel {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String emirate;
  final String district;
  final String? area;
  final String priceRange;
  final String category;
  final String advertiserName;
  final String phoneNumber;
  final String? whatsappNumber;
  final String? address;
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? createdAt;
  final String? planType;
  final String addCategory;
  final String addStatus;
  final bool adminApproved;
  final int views;
  final int rank;
  final int planDays;
  final String? planExpiresAt;
  final bool activeOffersBoxStatus;
  final int activeOffersBoxDays;
  final String? activeOffersBoxExpiresAt;
  final String? mainImageUrl;
  final List<String> thumbnailImagesUrls;
  final String status;
  final String section;
  

  RestaurantAdModel(
      {required this.id,
      required this.userId,
      required this.title,
      required this.description,
      required this.emirate,
      required this.district,
      this.area,
      required this.priceRange,
      required this.category,
      required this.advertiserName,
      required this.phoneNumber,
      this.whatsappNumber,
      this.address,
      this.mainImage,
      required this.thumbnailImages,
      this.createdAt,
      this.planType,
      required this.addCategory,
      required this.addStatus,
      required this.adminApproved,
      required this.views,
      required this.rank,
      required this.planDays,
      this.planExpiresAt,
      required this.activeOffersBoxStatus,
      required this.activeOffersBoxDays,
      this.activeOffersBoxExpiresAt,
      this.mainImageUrl,
      required this.thumbnailImagesUrls,
      required this.status,
      required this.section,
      required});

  factory RestaurantAdModel.fromJson(Map<String, dynamic> json) {
    // معالجة الصور المصغرة
    List<String> thumbs = [];
    final rawThumbs = json['thumbnail_images_urls'] ?? json['thumbnail_images'];

    if (rawThumbs is List) {
      thumbs = rawThumbs.map((e) => e.toString()).toList();
    } else if (rawThumbs is String && rawThumbs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawThumbs);
        if (decoded is List) {
          thumbs = decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // Handle json parsing error if string is not valid json
      }
    }

    // معالجة thumbnail_images_urls
    List<String> thumbUrls = [];
    final rawThumbUrls = json['thumbnail_images_urls'];
    if (rawThumbUrls is List) {
      thumbUrls = rawThumbUrls.map((e) => e.toString()).toList();
    }

    return RestaurantAdModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      emirate: json['emirate'] ?? '',
      district: json['district'] ?? '',
      area: json['area'],
      priceRange: json['price_range'] ?? 'N/A',
      category: json['category'] ?? '',
      advertiserName: json['advertiser_name'] ?? 'N/A',
      phoneNumber: json['phone_number'] ?? 'N/A',
      whatsappNumber: json['whatsapp_number'],
      address: json['address'],
      mainImage: json['main_image'],
      thumbnailImages: thumbs,
      createdAt: json['created_at'],
      planType: json['plan_type'],
      addCategory: json['add_category'] ?? 'restaurant',
      addStatus: json['add_status'] ?? 'Valid',
      adminApproved: json['admin_approved'] ?? false,
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      planDays: int.tryParse(json['plan_days']?.toString() ?? '0') ?? 0,
      planExpiresAt: json['plan_expires_at'],
      activeOffersBoxStatus: json['active_offers_box_status'] ?? false,
      activeOffersBoxDays:
          int.tryParse(json['active_offers_box_days']?.toString() ?? '0') ?? 0,
      activeOffersBoxExpiresAt: json['active_offers_box_expires_at'],
      mainImageUrl: json['main_image_url'],
      thumbnailImagesUrls: thumbUrls,
      status: json['status'] ?? 'Valid',
      section: json['section'] ?? 'Restaurants',
    );
  }
}
