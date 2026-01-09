// lib/data/model/other_service_ad_model.dart

import 'dart:convert';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/cupertino.dart';

class OtherServiceAdModel implements FavoriteItemInterface {
  @override
  final int id;
  @override
  final String title;

  final String? description;
  final String? emirate;
  final String? district;
  final String? area;
  final String price;
  final String? serviceName;
  final String? sectionType;
  final String advertiserName;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? planType;
  final String? createdAt;
  final String? addres;
  final String? _addCategory; // Dynamic category from API

  // Implemented from FavoriteItemInterface
  @override
  String get contact => advertiserName;
  @override
  String get Title => serviceName ?? 'N/A';
  @override
  String get details => serviceName ?? 'N/A';
  @override
  String get category => 'Other Services'; // Category for other services
  
  @override
  String get addCategory => _addCategory ?? 'other_services'; // API expects lowercase with underscores
  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(mainImage ?? '');
  @override
  List<String> get images =>
      [imageUrl, ...thumbnailImages].where((img) => img.isNotEmpty).toList();
  @override
  String get line1 => sectionType ?? "";
  @override
  String get line2 => "Section: ${sectionType ?? 'N/A'}";
  @override
  String get location => "${emirate ?? ''}  ${district ?? ''} ${area ?? ''}";
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

  OtherServiceAdModel(this.addres, {
    required this.id,
    required this.title,
    this.description,
    this.emirate,
    this.district,
    this.area,
    required this.price,
    this.serviceName,
    this.sectionType,
    required this.advertiserName,
    this.phoneNumber,
    this.whatsappNumber,
    this.mainImage,
    required this.thumbnailImages,
    this.planType,
    this.createdAt,
    String? addCategory,
  }) : _addCategory = addCategory;

  factory OtherServiceAdModel.fromJson(Map<String, dynamic> json) {
    // Handling thumbnails which might not exist
    List<String> thumbs = [];
    if (json['thumbnail_images'] != null) {
      final rawThumbs =
          json['thumbnail_images_urls'] ?? json['thumbnail_images'];
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
    }

    return OtherServiceAdModel(
      json['address'],
      id: json['id'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      emirate: json['emirate'],
      district: json['district'],
      area: json['area'],
      price: json['price']?.toString() ?? '0',
      serviceName: json['service_name'],
      sectionType: json['section_type'],
      advertiserName: json['advertiser_name'] ?? 'N/A',
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      mainImage: json['main_image_url'] ?? json['main_image'],
      thumbnailImages: thumbs,
      planType: json['plan_type'],
      createdAt: json['created_at'],
      addCategory: json['add_category']?.toString(),
    );
  }
}

class OtherServiceAdResponse {
  final List<OtherServiceAdModel> ads;
  final int total;
  OtherServiceAdResponse({required this.ads, required this.total});

  factory OtherServiceAdResponse.fromJson(Map<String, dynamic> json) {
    var adList = <OtherServiceAdModel>[];
    if (json['data'] != null && json['data'] is List) {
      adList = (json['data'] as List)
          .map((i) => OtherServiceAdModel.fromJson(i))
          .toList();
    }
    return OtherServiceAdResponse(
      ads: adList,
      total: json['total'] ?? 0,
    );
  }
}
