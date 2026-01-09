// lib/data/model/real_estate_options_model.dart

class RealEstateOptions {
  final List<String> propertyTypes;
  final List<String> contractTypes;

  RealEstateOptions({
    required this.propertyTypes,
    required this.contractTypes,
  });

  factory RealEstateOptions.fromJson(Map<String, dynamic> json) {
    List<String> propertyTypes = [];
    List<String> contractTypes = [];
    
    // تحليل البيانات من الشكل الجديد للـ API
    if (json['success'] == true && json['data'] != null) {
      final List<dynamic> data = json['data'];
      
      for (var item in data) {
        if (item['field_name'] == 'property_type' && item['options'] != null) {
          propertyTypes = List<String>.from(item['options']);
        } else if (item['field_name'] == 'contract_type' && item['options'] != null) {
          contractTypes = List<String>.from(item['options']);
        }
      }
    }
    
    return RealEstateOptions(
      propertyTypes: propertyTypes,
      contractTypes: contractTypes,
    );
  }
}