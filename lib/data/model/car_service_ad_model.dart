// lib/data/model/car_service_ad_model.dart
import 'dart:convert';

// Model لتمثيل الإعلان نفسه
class CarServiceModel {
  final int id;
  final String? planType;
  final String title;
  final String description;
  final String emirate;
  final String district;
  final String? area;
  final String serviceType;
  final String serviceName;
  final String price;
  final String advertiserName;
  final String phoneNumber;
  final String? whatsapp;
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? location;
  final String? createdAt; // سنضيفه للترتيب
  final String? addCategory; // Dynamic category from API

  CarServiceModel({
    required this.id,
    this.planType,
    required this.title,
    required this.description,
    required this.emirate,
    required this.district,
    this.area,
    required this.serviceType,
    required this.serviceName,
    required this.price,
    required this.advertiserName,
    required this.phoneNumber,
    this.whatsapp,
    this.mainImage,
    required this.thumbnailImages,
    this.location,
    this.createdAt,
    this.addCategory,
  });

  factory CarServiceModel.fromJson(Map<String, dynamic> json) {
    // --- معالجة الصورة الرئيسية بشكل مرن ---
    String? parseMainImage(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) {
        final v = raw.trim();
        return v.isEmpty ? null : v;
      }
      if (raw is Map<String, dynamic>) {
        final candidate = raw['url'] ?? raw['path'] ?? raw['src'] ?? raw['image'] ?? raw['main'];
        if (candidate == null) return null;
        final v = candidate.toString().trim();
        return v.isEmpty ? null : v;
      }
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is String) {
          final v = first.trim();
          return v.isEmpty ? null : v;
        }
        if (first is Map<String, dynamic>) {
          final candidate = first['url'] ?? first['path'] ?? first['src'] ?? first['image'];
          if (candidate == null) return null;
          final v = candidate.toString().trim();
          return v.isEmpty ? null : v;
        }
      }
      return raw.toString().trim().isEmpty ? null : raw.toString().trim();
    }

    // ابحث عن أكثر من مفتاح محتمل للصورة الرئيسية من الـ API
    final dynamic mainImageRaw =
        json['main_image_url'] ??
        json['main_image'] ??
        json['mainImageUrl'] ??
        json['mainImage'];
    final String? mainImageStr = parseMainImage(mainImageRaw);

    // --- معالجة الصور المصغرة بشكل مرن ---
    List<String> thumbs = [];
    dynamic thumbnailData =
        json['thumbnail_images_urls'] ??
        json['thumbnail_images'] ??
        json['thumbnails'] ??
        json['images'];

    if (thumbnailData != null) {
      if (thumbnailData is String) {
        // قد تأتي كسلسلة JSON
        try {
          final decoded = jsonDecode(thumbnailData);
          if (decoded is List) {
            thumbs = decoded
                .map((e) => e is Map<String, dynamic>
                    ? (e['url'] ?? e['path'] ?? e['src'] ?? e['image'] ?? '').toString()
                    : e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList();
          } else {
            // قد تكون سلسلة مفصولة بفاصلة
            final parts = thumbnailData.split(',');
            thumbs = parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {
          // في حال فشل التحويل، نحاول اعتبارها قائمة مفصولة بفواصل
          final parts = thumbnailData.split(',');
          thumbs = parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      } else if (thumbnailData is List) {
        // قائمة مباشرة من المسارات أو الكائنات
        thumbs = thumbnailData
            .map((e) => e is Map<String, dynamic>
                ? (e['url'] ?? e['path'] ?? e['src'] ?? e['image'] ?? '').toString()
                : e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      } else if (thumbnailData is Map<String, dynamic>) {
        // بعض الـ API قد يعيدها داخل مفتاح مثل 'urls' أو 'paths'
        final list = thumbnailData['urls'] ?? thumbnailData['paths'] ?? thumbnailData['images'];
        if (list is List) {
          thumbs = list
              .map((e) => e is Map<String, dynamic>
                  ? (e['url'] ?? e['path'] ?? e['src'] ?? e['image'] ?? '').toString()
                  : e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList();
        }
      }
    }
    
    String parseServiceType(dynamic raw) {
      if (raw == null) return 'other';
      if (raw is Map<String, dynamic>) {
        return (raw['name'] ?? raw['display_name'] ?? 'other').toString();
      }
      return raw.toString();
    }

    return CarServiceModel(
      id: json['id'],
      planType: json['plan_type'],
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      emirate: json['emirate'] ?? 'Unknown Emirate',
      district: json['district'] ?? 'Unknown District',
      area: json['area'],
      serviceType: parseServiceType(json['service_type']),
      serviceName: (json['service_name'] ?? 'No Service Name').toString(),
      price: (json['price'] ?? '0.00').toString(),
      advertiserName: (json['advertiser_name'] ?? 'N/A').toString(),
      phoneNumber: (json['phone_number'] ?? 'N/A').toString(),
      whatsapp: json['whatsapp']?.toString(),
      mainImage: mainImageStr,
      thumbnailImages: thumbs,
      location: json['location'],
      createdAt: json['created_at'],
      addCategory: json['add_category']?.toString(),
    );
  }
}

// Model لتغليف الاستجابة الكاملة من الـ API
class CarServiceAdResponse {
  final List<CarServiceModel> ads;
  final int currentPage;
  final int lastPage;

  CarServiceAdResponse({
    required this.ads,
    required this.currentPage,
    required this.lastPage,
  });

  factory CarServiceAdResponse.fromJson(Map<String, dynamic> json) {
    var adList = <CarServiceModel>[];
    if (json['data'] != null && json['data'] is List) {
      adList = (json['data'] as List).map((i) => CarServiceModel.fromJson(i)).toList();
    }
    return CarServiceAdResponse(
      ads: adList,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
    );
  }
}