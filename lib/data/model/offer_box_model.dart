import 'dart:io';

class OfferBoxModel {
  final String image;
  final String price;
  final String title;
  final String location;
  final String contact;
  final String? year;
  final String? km;
  final String propertyType;
  final String contract_type;
  final String emirate;
  final String district;
  final int id;

  OfferBoxModel(
      this.propertyType, this.contract_type, this.emirate, this.district, this.id,
      {this.km,
      this.year,
      required this.image,
      required this.price,
      required this.title,
      required this.location,
      required this.contact});

  factory OfferBoxModel.fromJson(Map<String, dynamic> json) {
    return OfferBoxModel(
      json['property_type'] ?? '',
      json['contract_type'] ?? '',
      json['emirate'] ?? '',
      json['district'] ?? '',
      json['id'] ?? '',
      image: json['main_image'] ?? '',
      price: json['price'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      contact: json['advertiser_name'] ?? '',
      year: json['year'],
      km: json['km'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'price': price,
      'title': title,
      'location': location,
      'contact': contact,
      'year': year,
      'km': km,
    };
  }
}
