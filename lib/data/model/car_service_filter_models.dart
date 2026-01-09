// lib/data/model/car_service_filter_models.dart

// Model لتمثيل نوع الخدمة
class ServiceTypeModel {
  final String name;
  final String displayName;

  ServiceTypeModel({required this.name, required this.displayName});

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      name: json['name'] as String,
      displayName: json['display_name'] as String,
    );
  }
}

// Model لتمثيل الإمارة والمناطق التابعة لها
class EmirateModel {
  final String name;
  final String displayName;
  final List<String> districts;

  EmirateModel({
    required this.name,
    required this.displayName,
    required this.districts,
  });

  factory EmirateModel.fromJson(Map<String, dynamic> json) {
    // التأكد من أن districts هي قائمة من الـ Strings
    final districtData = json['districts'] as List<dynamic>;
    final districtsList = districtData.map((d) => d.toString()).toList();

    return EmirateModel(
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      districts: districtsList,
    );
  }
}