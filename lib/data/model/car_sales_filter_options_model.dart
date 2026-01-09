// في ملف: data/model/filter_options_model.dart

class MakeModel {
  final int id;
  final String name;

  MakeModel({required this.id, required this.name});

  factory MakeModel.fromJson(Map<String, dynamic> json) {
    return MakeModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Make',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MakeModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class CarModel {
  final int id;
  final String name;
  final int makeId; // سيبقى اسمه هكذا داخل التطبيق

  CarModel({required this.id, required this.name, required this.makeId});

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Model',
      // +++ التصحيح: اقرأ من الحقل الصحيح car_make_id +++
      makeId: json['car_make_id'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarModel &&
        other.id == id &&
        other.name == name &&
        other.makeId == makeId;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ makeId.hashCode;
}

class TrimModel {
  final int id;
  final String name;
  // +++ إضافة الحقل المفقود للربط +++
  final int modelId;

  TrimModel({required this.id, required this.name, required this.modelId});

  factory TrimModel.fromJson(Map<String, dynamic> json) {
    return TrimModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Trim',
      // +++ التصحيح: اقرأ من الحقل الصحيح car_model_id +++
      modelId: json['car_model_id'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrimModel &&
        other.id == id &&
        other.name == name &&
        other.modelId == modelId;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ modelId.hashCode;
}