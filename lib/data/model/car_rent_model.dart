import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'ad_priority.dart';
import 'favorite_item_interface_model.dart';

class CarRentModel implements FavoriteItemInterface {
 
  late final String title;
  late final String price;
  final String day_rent;
  final String month_rent;
  final String location;
  final String date;
  final String details;
  final String contact;
  final bool isPremium;
  final List<String> _images;
  final AdPriority priority;
  final String image;
  final String year;
  final String km;
  final String carType;
  final String transType;
  final String color;
  final String interiorColor;
  final String fuelType;
  final String seats;

  CarRentModel({

    required this.day_rent,
    required this.month_rent,
    required this.year,
    required this.km,
    required this.title,
    required this.contact,
    required this.price,
    required this.location,
    required this.image,
    required this.date,
    required this.details,
    required this.isPremium,
    required this.priority,
    required this.carType,
    required this.transType,
    required this.color,
    required this.interiorColor,
    required this.fuelType,
    required this.seats,
    required List<String> images,
  }) : _images = images;

  @override
  String get line1 => "Day Rent $day_rent  Month Rent $month_rent";

  @override
  String get category => 'Car Rent'; // Category for car rent

  @override
  String get addCategory => 'Car Rent'; // API expects lowercase with underscores

  @override
  List<String> get images => _images;
  
  @override
  String get id => title.hashCode.toString();
}
