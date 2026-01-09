// import 'package:advertising_app/constant/image_url_helper.dart';
// import 'package:advertising_app/data/model/user_ads_model.dart';
// import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
// import 'package:advertising_app/data/model/ad_priority.dart';

// /// محول لتحويل UserAd إلى شكل إعلان السيارات
// class CarSalesAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   CarSalesAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => '${userAd.make ?? ''} ${userAd.model ?? ''} ${userAd.year ?? ''}'.trim();

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;

//   // خصائص إضافية خاصة بالسيارات
//   String get make => userAd.make ?? '';
//   String get model => userAd.model ?? '';
//   String get year => userAd.year ?? '';
//   String get carType => userAd.carType ?? '';
//   String get transType => userAd.transType ?? '';
//   String get fuelType => userAd.fuelType ?? '';
//   String get color => userAd.color ?? '';
//   String get seatsNo => userAd.seatsNo ?? '';
//   @override
//   String get id => userAd.id.toString();
  
//   @override
//   String get category => userAd.category;
  
//   @override
//   String get addCategory => userAd.addCategory;
// }

// /// محول لتحويل UserAd إلى شكل إعلان تأجير السيارات
// class CarRentAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   CarRentAdAdapter(this.userAd);

//   String get dayRent => userAd.dayRent ?? '';
//   String get model => userAd.monthRent ?? '';

//   @override int get id => userAd.id;
//   @override String get contact => userAd.advertiserName;
//   @override String get details => userAd.title;
//   @override String get category => 'Car Rent'; // Category for car rent
  
//   @override String get addCategory => 'Car Rent'; // Dynamic category for API
//   @override String get imageUrl => ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? '');
//   @override List<String> get images => [ ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? ''), ...ImageUrlHelper.getThumbnailImageUrls(userAd.thumbnailImages) ].where((img) => img.isNotEmpty).toList();
//   @override String get line1 => 'Day/ ${userAd.dayRent} Month Rent'; // تغيير من '' إلى قيمة غير فارغة
//   @override String get line2 => userAd.title;
//   @override String get price => userAd.price;
//   @override String get location => "${userAd.location} ";
//   @override String get title => "${userAd.make ?? ''} ${userAd.model ?? ''} ${userAd.trim ?? ''} ${userAd.year ?? ''}".trim();
//   @override String get date => userAd.createdAt?.split('T').first ?? '';

//   @override
//   AdPriority get priority {
//     final plan = userAd.planType?.toLowerCase();
//     if (plan == null || plan == 'free') return AdPriority.free;
//     if (plan.contains('premium_star')) return AdPriority.PremiumStar;
//     if (plan.contains('premium')) return AdPriority.premium;
//     if (plan.contains('featured')) return AdPriority.featured;
//     return AdPriority.free;
//   }
//   @override bool get isPremium => priority != AdPriority.free;
// }
// /// محول لتحويل UserAd إلى شكل إعلان خدمات السيارات
// class CarServiceAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   CarServiceAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => userAd.serviceType ?? userAd.serviceName ?? '';

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;

//   // خصائص إضافية خاصة بخدمات السيارات
//   String get serviceType => userAd.serviceType ?? '';
//   String get serviceName => userAd.serviceName ?? '';
//   @override
//   String get id => userAd.id.toString();
//   @override
//   String get category => userAd.category;
//   @override
//   String get addCategory => userAd.addCategory;
// }

// /// محول لتحويل UserAd إلى شكل إعلان العقارات
// class RealEstateAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   RealEstateAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => userAd.category;

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
//   @override
//   String get id => userAd.id.toString();
//   @override
//   String get category => userAd.category;
//   @override
//   String get addCategory => userAd.addCategory;
// }

// /// محول لتحويل UserAd إلى شكل إعلان الإلكترونيات
// class ElectronicsAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   ElectronicsAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => userAd.category;

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
//   @override
//   String get id => userAd.id.toString();
//   @override
//   String get category => userAd.category;
//   @override
//   String get addCategory => userAd.addCategory;
// }

// /// محول لتحويل UserAd إلى شكل إعلان الوظائف
// class JobAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   JobAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => userAd.category;

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
//   @override
//   String get id => userAd.id.toString();
//   @override
//   String get category => userAd.category;
//   @override
//   String get addCategory => userAd.addCategory;
// }

// /// محول لتحويل UserAd إلى شكل إعلان المطاعم
// class RestaurantAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   RestaurantAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => userAd.category;

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
//   @override
//   String get id => userAd.id.toString();
//   @override
//   String get category => userAd.category;
//   @override
//   String get addCategory => userAd.addCategory;
// }

// /// محول لتحويل UserAd إلى شكل إعلان الخدمات الأخرى
// class OtherServiceAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   OtherServiceAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => userAd.serviceType ?? userAd.serviceName ?? userAd.category;

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;

//   // خصائص إضافية خاصة بالخدمات الأخرى
//   String get serviceType => userAd.serviceType ?? '';
//   String get serviceName => userAd.serviceName ?? '';
//   @override
//   String get id => userAd.id.toString();
//   @override
//   String get category => userAd.category;
//   @override
//   String get addCategory => userAd.addCategory;
// }

// /// Factory class لإنشاء المحول المناسب حسب فئة الإعلان
// class UserAdAdapterFactory {
//   static FavoriteItemInterface createAdapter(UserAd userAd) {
//     switch (userAd.addCategory.toLowerCase()) {
//       case 'car_sales':
//       case 'cars':
//         return CarSalesAdAdapter(userAd);
//       case 'car_rent':
//         return CarRentAdAdapter(userAd);
//       case 'car_service':
//         return CarServiceAdAdapter(userAd);
//       case 'real_estate':
//         return RealEstateAdAdapter(userAd);
//       case 'electronics':
//         return ElectronicsAdAdapter(userAd);
//       case 'jobs':
//         return JobAdAdapter(userAd);
//       case 'restaurants':
//         return RestaurantAdAdapter(userAd);
//       case 'other_services':
//         return OtherServiceAdAdapter(userAd);
//       default:
//         // استخدام محول عام للفئات غير المعروفة
//         return _GenericAdAdapter(userAd);
//     }
//   }
// }

// /// محول عام للفئات غير المعروفة
// class _GenericAdAdapter implements FavoriteItemInterface {
//   final UserAd userAd;

//   _GenericAdAdapter(this.userAd);

//   @override
//   String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

//   @override
//   String get details => userAd.description;

//   @override
//   String get imageUrl => userAd.mainImageUrl;

//   @override
//   List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty 
//       ? userAd.thumbnailImagesUrls 
//       : [userAd.mainImageUrl];

//   @override
//   String get line1 => userAd.title;

//   @override
//   String get line2 => userAd.category;

//   @override
//   String get price => userAd.price;

//   @override
//   String get location => userAd.location;

//   @override
//   String get title => userAd.title;

//   @override
//   String get date => userAd.createdAt;

//   @override
//   bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

//   @override
//   AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
//   @override
//   String get id => userAd.id.toString();
//   @override
//   String get category => userAd.category;
//   @override
//   String get addCategory => userAd.addCategory;
// }