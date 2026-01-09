import 'ad_priority.dart';

abstract class FavoriteItemInterface {
  String get title;
  String get location;
  String get price;
  String get line1;
  String get details;
  String get date;
  String get contact;
  bool get isPremium;
  List<String> get images;
  String get category; // Added category property
  String
      get addCategory; // Added addCategory property for dynamic category slug
 
  AdPriority get priority;

  get id => null;
}
