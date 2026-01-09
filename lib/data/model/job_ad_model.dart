// lib/data/model/job_ad_model.dart
import 'dart:convert';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/constant/image_url_helper.dart';

class JobAdModel implements FavoriteItemInterface {
  @override
  final int id;
  @override
  final String title;

  final String? description;
  final String? emirate;
  final String? district;
  final String? categoryType; // 'Job Wanted' or 'Job Offer'
  final String? sectionType; // 'Marketing', 'Driver'
  final String? salary;
  final String advertiserName;
  final String? address; // Location/address of the job or advertiser
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? planType;
  final String? createdAt;
  final String? contactInfo;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? job_name;
  final String? _addCategory; // Dynamic category from API

  // Implemented from FavoriteItemInterface
  @override
  String get contact => advertiserName;
  @override
  String get details =>  "${categoryType ?? 'N/A'} ${sectionType ?? 'N/A'} "; // Job Category Type
  @override
  String get category => 'Jop'; // Category for jobs
  
  @override
  String get addCategory => _addCategory ?? 'jobs'; // Use dynamic category from API or fallback
  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(mainImage ?? '');
  @override
  List<String> get images =>
      [imageUrl, ...thumbnailImages].where((img) => img.isNotEmpty).toList();
  @override
  String get line1 =>   job_name ?? 'N/A';// Specific section like Marketing
  @override
  String get line2 => "${salary ?? 'Not specified'}";
  @override
  String get price => salary ?? '';
  @override
  String get location => "${emirate} ${district}" ?? 'N/A';
  @override
  String get date => createdAt?.split('T').first ?? '';
  @override
  bool get isPremium => priority != AdPriority.free;

  @override
  AdPriority get priority {
    final plan = planType?.toLowerCase();
    if (plan == null || plan == 'free') return AdPriority.free;
    if (plan.contains('premium_star')) return AdPriority.PremiumStar;
    if (plan.contains('premium')) return AdPriority.premium;
    if (plan.contains('featured')) return AdPriority.featured;
    return AdPriority.free;
  }

  JobAdModel(this.job_name, {
    required this.id,
    required this.title,
    this.description,
    this.emirate,
    this.district,
    this.categoryType,
    this.sectionType,
    this.salary,
    required this.advertiserName,
    this.address,
    this.mainImage,
    required this.thumbnailImages,
    this.planType,
    this.createdAt,
    this.contactInfo,
    this.phoneNumber,
    this.whatsappNumber,
    String? addCategory,
  }) : _addCategory = addCategory;

  factory JobAdModel.fromJson(Map<String, dynamic> json) {
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
      } catch (e) {/* Ignore parsing errors */}
    }

    return JobAdModel(
      json['job_name'],
      id: json['id'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      emirate: json['emirate'],
      district: json['district'],
      categoryType: json['category_type'], // API sends 'category_type'
      sectionType: json['section_type'], // API sends 'section_type'
      salary: json['salary']?.toString(),
      advertiserName: json['advertiser_name'] ?? 'N/A',
      address: json['address'],
      mainImage: json['main_image_url'] ?? json['main_image'],
      thumbnailImages: thumbs,
      planType: json['plan_type'],
      createdAt: json['created_at'],
      contactInfo: json['contact_info'],
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      addCategory: json['add_category']?.toString(),
    );
  }
}

class JobAdResponse {
  final List<JobAdModel> ads;
  final int total;

  JobAdResponse({required this.ads, required this.total});

  factory JobAdResponse.fromJson(Map<String, dynamic> json) {
    var adList = <JobAdModel>[];
    if (json['data'] != null && json['data'] is List) {
      adList =
          (json['data'] as List).map((i) => JobAdModel.fromJson(i)).toList();
    }
    return JobAdResponse(
      ads: adList,
      total: json['total'] ?? 0,
    );
  }
}
