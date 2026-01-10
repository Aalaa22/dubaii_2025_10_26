// lib/data/model/electronics_ad_model.dart

import 'dart:convert';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:flutter/material.dart';

// -----------------  الكلاس الأول: يمثل إعلان واحد (سطر واحد) -----------------
class ElectronicAdModel implements FavoriteItemInterface {
  @override
  final int id;
  @override
  final String title;

  final String? description;
  final String? emirate;
  final String? district;
  final String? area;
  @override
  final String price;
  final String? productName;
  final String? sectionType;
  final String advertiserName;
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? planType;
  final String? createdAt;
  final String? contactInfo;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? addres;
  final String? _addCategory; // Dynamic category from API
  final double? latitude;
  final double? longitude;

  // -- الخصائص المطلوبة من FavoriteItemInterface لعرضها في الكارد --
  @override
  String get contact => advertiserName;
  @override
  String get details => "${productName ?? 'N/A'}";
  @override
  String get category => 'Electronics'; // Category for electronics
  
  @override
  String get addCategory => this._addCategory ?? 'electronics'; // API expects lowercase

  @override
  String get Title => "${productName ?? 'N/A'}";

  String get imageUrl => ImageUrlHelper.getMainImageUrl(mainImage ?? '');
  @override
  List<String> get images =>
      [imageUrl, ...thumbnailImages].where((img) => img.isNotEmpty).toList();
  @override
  String get line1 => "${sectionType ?? ''}";

  String get line2 => "$productName".trim();
  @override
  String get location =>
      "${emirate ?? ''} ${district ?? ''} ${area ?? ''}".trim();
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

  ElectronicAdModel(
    this.addres, {
    required this.id,
    required this.title,
    this.description,
    this.emirate,
    this.district,
    this.area,
    required this.price,
    this.productName,
    this.sectionType,
    required this.advertiserName,
    this.mainImage,
    required this.thumbnailImages,
    this.planType,
    this.createdAt,
    this.contactInfo,
    this.phoneNumber,
    this.whatsappNumber,
    String? addCategory,
    this.latitude,
    this.longitude,
  }) : _addCategory = addCategory;

  factory ElectronicAdModel.fromJson(Map<String, dynamic> json) {
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
      } catch (e) {/* Ignore */}
    }

    return ElectronicAdModel(
      json['address'] ?? '',
      id: json['id'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      emirate: json['emirate'],
      district: json['district'],
      area: json['area'],
      price: json['price']?.toString() ?? '0',
      productName: json['product_name'],
      sectionType: json['section_type'],
      advertiserName: json['advertiser_name'] ?? 'N/A',
      mainImage: json['main_image_url'] ?? json['main_image'],
      thumbnailImages: thumbs,
      planType: json['plan_type'],
      createdAt: json['created_at'],
      contactInfo: json['contact_info'],
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      addCategory: json['add_category']?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

// -----------------  الكلاس الثاني: يمثل الاستجابة الكاملة من الـ API -----------------
class ElectronicAdResponse {
  final List<ElectronicAdModel> ads;
  final int total;
  ElectronicAdResponse({required this.ads, required this.total});

  factory ElectronicAdResponse.fromJson(Map<String, dynamic> json) {
    var adList = <ElectronicAdModel>[];
    if (json['data'] != null && json['data'] is List) {
      adList = (json['data'] as List)
          .map((i) => ElectronicAdModel.fromJson(i))
          .toList();
    }
    return ElectronicAdResponse(
      ads: adList,
      total: json['total'] ?? 0,
    );
  }
}
