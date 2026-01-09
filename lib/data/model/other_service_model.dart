import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'ad_priority.dart';

class OtherServiceModel implements FavoriteItemInterface {
  final String title;
  final String price;
  final String image;
  final String details;
  final String contact;
  final String location;
  final String date;
  final bool isPremium;
  final List<String> _images;
  final AdPriority priority;


  OtherServiceModel({
    required this.title,
    required this.contact,
    required this.price,
    required this.image,
    required this.location,
    required this.date,
    required this.details,
    required this.isPremium,
    required List<String> images, 
    required this.priority,
  }) : _images = images;


  @override
  String get line1 => "";

  @override
  String get category => 'Other Services'; // Category for other services

  @override
  String get addCategory => 'Other Services'; // API expects lowercase with underscores

  @override
  List<String> get images => _images;
  
  @override
  String get id => title.hashCode.toString(); 
}
