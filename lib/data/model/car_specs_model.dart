class CarSpecsResponse {
  final bool success;
  final List<CarSpecField> data;

  CarSpecsResponse({required this.success, required this.data});

  factory CarSpecsResponse.fromJson(Map<String, dynamic> json) {
    return CarSpecsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List)
          .map((field) => CarSpecField.fromJson(field))
          .toList(),
    );
  }
}

class CarSpecField {
  final String fieldName;
  final String displayName;
  final List<String> options;

  CarSpecField({
    required this.fieldName,
    required this.displayName,
    required this.options,
  });

  factory CarSpecField.fromJson(Map<String, dynamic> json) {
    return CarSpecField(
      fieldName: json['field_name'] ?? '',
      displayName: json['display_name'] ?? '',
      options: (json['options'] as List).map((e) => e.toString()).toList(),
    );
  }
}