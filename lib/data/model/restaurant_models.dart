// lib/data/model/restaurant_models.dart

// Model بسيط لتمثيل فئة المطعم
class RestaurantCategoryModel {
  final String name;
  final String displayName;

  RestaurantCategoryModel({required this.name, required this.displayName});

  // سنفترض أن الـ API يرجع قائمة من الكائنات بهذا الشكل
  factory RestaurantCategoryModel.fromJson(Map<String, dynamic> json) {
    return RestaurantCategoryModel(
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}