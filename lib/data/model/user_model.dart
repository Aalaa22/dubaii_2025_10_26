class UserModel {
  final int id;
  final String? role;
  final String username;
  final String email;
  final String phone;
  final String? whatsapp;
  final String? advertiserName;
  final String? advertiserType;
  final String? advertiserLogo; // <-- حقل جديد
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? advertiserLocation;
  final String? userType; // إضافة حقل userType

  UserModel({
    required this.id,
    this.role,
    required this.username,
    required this.email,
    required this.phone,
    this.whatsapp,
    this.advertiserName,
    this.advertiserType,
    this.advertiserLogo,
    this.latitude,
    this.longitude,
    this.address,
    this.advertiserLocation,
    this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      role: json['role'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'],
      advertiserName: json['advertiser_name'],
      advertiserType: json['advertiser_type'],
      advertiserLogo: json['advertiser_logo'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      address: json['address'],
      advertiserLocation: json['advertiser_location'],
      userType: json['user_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'username': username,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'advertiser_name': advertiserName,
      'advertiser_type': advertiserType,
      'advertiser_logo': advertiserLogo,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'advertiser_location': advertiserLocation,
      'user_type': userType,
    };
  }
}