import 'favorite_item_interface_model.dart';
import 'ad_priority.dart';

class CarSalesModel implements FavoriteItemInterface {

  final String title;
  final String price;
  final String year;
  final String km;
  final String specs;
  final String location;
  final String contact;
  final String date;
  final String details;

  final String image;
  
  
  final bool isPremium;
  final List<String> _images;
  final AdPriority priority;
  final String carType;
  final String transType;
final String color;
final String interiorColor;
final String fuelType;
final String warranty;
final String doors;
final String seats;
final String engineCapacity;
final String cylinders;
final String horsePower;
final String steeringSide;


  CarSalesModel(
   
    {

  required  this.image ,
  required  this.carType,
  required  this.transType,
  required  this.color,
  required  this.interiorColor,
  required  this.fuelType,
  required  this.warranty,
  required  this.doors,
  required  this.seats,
  required  this.engineCapacity,
  required  this.cylinders,
  required  this.horsePower,
  required  this.steeringSide,
           
    required this.title,
    required this.contact,
    required this.price,
    required this.year,
    required this.km,
    required this.specs,
    required this.location,
    required this.date,
    required this.details,
    required this.isPremium,
    required List<String> images,
    required this.priority,
  }) : _images = images;

  @override
  String get line1 => "Year: $year   Km: $km   Specs: $specs";

  @override
  String get category => 'Cars Sales'; // Category for car sales

  @override
  String get addCategory => 'Cars Sales'; // API expects lowercase with underscores

  @override
  List<String> get images => _images;
  
  @override
  String get id => title.hashCode.toString(); // استخدام hash code للـ title كـ id فريد
}



