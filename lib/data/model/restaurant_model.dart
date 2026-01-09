import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'ad_priority.dart';

class RestaurantModel implements FavoriteItemInterface {

  @override
  String get id => title; // Using title as unique identifier
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
  final String? _addCategory; // Dynamic category from API


  RestaurantModel({
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
    String? addCategory,
  }) : _images = images, _addCategory = addCategory;


  @override
  String get line1 => "";

  @override
  String get category => 'restaurant'; // Category for restaurants

  @override
  String get addCategory => _addCategory ?? 'restaurant'; // Use dynamic category from API or fallback

  @override
  List<String> get images => _images; 
}
