// lib/data/model/car_rent_ad_model.dart
import 'dart:convert';

class CarRentAdModel {
  final int id;
  final String title;
  final String price;
  final String? make;
  final String? model;
  final String? trim;
  final String? area;
  final String? year;
  final String dayRent;
  final String monthRent;
  final String advertiserName;
  final String emirate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? planType;
  final String? createdAt;
  final String? phoneNumber;
  final String? whatsapp;
  final String? district;
  final String? carType;
  final String? transType;
  final String? fuelType;
  final String? color;
  final String? interior_color;
  final String? seats_no;
  final String? description;
  final String? addCategory;

  // Getters for compatibility with screen code
  String? get interiorColor => interior_color;
  String? get seatsNo => seats_no;

  CarRentAdModel(
    this.carType,
    this.transType,
    this.fuelType,
    this.color,
    this.interior_color,
    this.seats_no,
    this.description, this.addCategory, {
    required this.id,
    required this.title,
    required this.price,
    this.district,
    this.make,
    this.model,
    this.trim,
    this.year,
    this.area,
    required this.dayRent,
    required this.monthRent,
    required this.advertiserName,
    required this.emirate,
    this.location,
    this.latitude,
    this.longitude,
    this.mainImage,
    required this.thumbnailImages,
    this.planType,
    this.createdAt,
    this.phoneNumber,
    this.whatsapp,
  });

  factory CarRentAdModel.fromJson(Map<String, dynamic> json) {
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
        // Handle json parsing error
      }
    }

    return CarRentAdModel(
        json['car_type']?.toString(),
        json['trans_type']?.toString(),
        json['fuel_type']?.toString(),
        json['color']?.toString(),
        json['interior_color']?.toString(),
        json['seats_no']?.toString(),
        json['description']?.toString(),
        json['add_category']?.toString(),
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        price: json['price']?.toString() ?? '0',
        title: json['title']?.toString() ?? 'No Title',
        make: json['make']?.toString(),
        model: json['model']?.toString(),
        trim: json['trim']?.toString(),
        year: json['year']?.toString(),
        area: json["area"]?.toString(),
        dayRent: json['day_rent']?.toString() ?? 'N/A',
        monthRent: json['month_rent']?.toString() ?? 'N/A',
        advertiserName: json['advertiser_name']?.toString() ?? 'N/A',
        emirate: json['emirate']?.toString() ?? '',
        location: json['location']?.toString(),
        latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
        longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
        mainImage: json['main_image_url']?.toString() ?? json['main_image']?.toString(),
        thumbnailImages: thumbs,
        planType: json['plan_type']?.toString(),
        createdAt: json['created_at']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        whatsapp: json['whatsapp']?.toString(),
        district: json['district']?.toString());
  }
}

class CarRentAdResponse {
  final List<CarRentAdModel> ads;
  final int total;

  CarRentAdResponse({required this.ads, required this.total});

  factory CarRentAdResponse.fromJson(Map<String, dynamic> json) {
    var adList = <CarRentAdModel>[];
    if (json['data'] != null && json['data'] is List) {
      adList = (json['data'] as List)
          .map((i) => CarRentAdModel.fromJson(i))
          .toList();
    }
    return CarRentAdResponse(
      ads: adList,
      total: json['total'] ?? 0,
    );
  }
}
