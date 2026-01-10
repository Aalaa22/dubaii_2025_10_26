// lib/data/model/real_estate_ad_model.dart
import 'dart:convert';

class RealEstateAdModel {
  final int id;
  final String title;
  final String? description;
  final String? emirate;
  final String? district;
  final String? area;
  final String price;
  final String? propertyType;
  final String? contractType; // for 'Sale' or 'Rent'
  final String advertiserName;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? planType;
  final String? createdAt;
  final String location;
  final String? addCategory; // Dynamic category from API
  final double? latitude;
  final double? longitude;

  RealEstateAdModel(this.location, {
    required this.id,
    required this.title,
    this.description,
    this.emirate,
    this.district,
    this.area,
    required this.price,
    this.propertyType,
    this.contractType,
    required this.advertiserName,
    this.phoneNumber,
    this.whatsappNumber,
    this.mainImage,
    required this.thumbnailImages,
    this.planType,
    this.createdAt,
    this.addCategory,
    this.latitude,
    this.longitude,
  });

  factory RealEstateAdModel.fromJson(Map<String, dynamic> json) {
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

    return RealEstateAdModel(
      json['address'] ?? '',
      id: json['id'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      emirate: json['emirate'],
      district: json['district'],
      area: json['area'],
      price: json['price']?.toString() ?? '0',
      propertyType: json['property_type'], // assuming key from API
      contractType: json['contract_type'], // assuming key from API
      advertiserName: json['advertiser_name'] ?? 'N/A',
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      mainImage: json['main_image_url'] ?? json['main_image'],
      thumbnailImages: thumbs,
      planType: json['plan_type'],
      createdAt: json['created_at'],
      addCategory: json['add_category'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

class RealEstateAdResponse {
  final List<RealEstateAdModel> ads;
  final int total;

  RealEstateAdResponse({required this.ads, required this.total});

  factory RealEstateAdResponse.fromJson(Map<String, dynamic> json) {
    var adList = <RealEstateAdModel>[];
    if (json['data'] != null && json['data'] is List) {
      adList = (json['data'] as List)
          .map((i) => RealEstateAdModel.fromJson(i))
          .toList();
    }
    return RealEstateAdResponse(
      ads: adList,
      total: json['total'] ?? 0,
    );
  }
}
