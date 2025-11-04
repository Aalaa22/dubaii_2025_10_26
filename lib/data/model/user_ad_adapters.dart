import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/data/model/user_ads_model.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/utils/number_formatter.dart';

/// محول لتحويل UserAd إلى شكل إعلان السيارات
class CarSalesAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  CarSalesAdAdapter(this.userAd);

  @override
  String get contact => userAd.advertiserName ?? '';

  @override
  String get details => userAd.title;

  @override
  String get imageUrl {
    final url = (userAd.mainImageUrl).trim();
    if (url.isNotEmpty) return url;
    return ImageUrlHelper.getMainImageUrl(userAd.mainImage);
  }

  @override
  List<String> get images {
    final urls = userAd.thumbnailImagesUrls;
    if (urls.isNotEmpty) {
      return [userAd.mainImageUrl, ...urls].where((img) => img.isNotEmpty).toList();
    }
    return [
      ImageUrlHelper.getMainImageUrl(userAd.mainImage),
      ...ImageUrlHelper.getThumbnailImageUrls(userAd.thumbnailImages)
    ].where((img) => img.isNotEmpty).toList();
  }

  @override
  String get line1 =>
      "Year: ${userAd.year}  Km: ${NumberFormatter.formatNumber(userAd.km)}   Specs: ${userAd.specs ?? ''}";

  @override
  String get line2 => '${userAd.title ?? ''} '.trim();

  @override
  String get price => userAd.price;

  @override
  String get location {
    // القيمة الأساسية من الإمارة والمنطقة
    final primary = '${userAd.emirate} ${userAd.area}'.trim();
    if (primary.isNotEmpty) return primary;
    // fallback: استخدم الحي إن وجد، وإلا استخدم location الخام من API
    if (userAd.district.trim().isNotEmpty) return userAd.district.trim();
    return userAd.location.trim();
  }

  @override
  String get title =>
      '${userAd.make ?? ''} ${userAd.model ?? ''} ${userAd.trim ?? ''}'.trim();

  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium {
    // الإعلان يعتبر Premium إذا كان planType موجودًا وقيمته ليست 'free'
    if (userAd.planType == null) return false;
    return userAd.planType!.toLowerCase() != 'free';
  }

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;

  // خصائص إضافية خاصة بالسيارات
  String get make => userAd.make ?? '';
  String get model => userAd.model ?? '';
  String get year => userAd.year ?? '';
  String get carType => userAd.carType ?? '';
  String get transType => userAd.transType ?? '';
  String get fuelType => userAd.fuelType ?? '';
  String get color => userAd.color ?? '';
  String get seatsNo => userAd.seatsNo ?? '';
  @override
  String get id => userAd.id.toString();

  @override
  String get category => userAd.category;

  @override
  String get addCategory => userAd.addCategory;
}

/// محول لتحويل UserAd إلى شكل إعلان تأجير السيارات
class CarRentAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  CarRentAdAdapter(this.userAd);

  String get dayRent => userAd.dayRent ?? '';
  String get model => userAd.monthRent ?? '';

  @override
  int get id => userAd.id;
  @override
  String get contact => userAd.advertiserName;
  @override
  String get details => userAd.title;
  @override
  String get category => 'Car Rent'; // Category for car rent

  @override
  String get addCategory => 'Car Rent'; // Dynamic category for API
  @override
  String get imageUrl {
    final url = (userAd.mainImageUrl).trim();
    if (url.isNotEmpty) return url;
    return ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? '');
  }
  @override
  List<String> get images {
    final urls = userAd.thumbnailImagesUrls;
    if (urls.isNotEmpty) {
      return [userAd.mainImageUrl, ...urls].where((img) => img.isNotEmpty).toList();
    }
    return [
      ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? ''),
      ...ImageUrlHelper.getThumbnailImageUrls(userAd.thumbnailImages)
    ].where((img) => img.isNotEmpty).toList();
  }
  @override
  String get line1 =>
      'Day ${userAd.dayRent} Month Rent ${userAd.monthRent}'; // تغيير من '' إلى قيمة غير فارغة
  @override
  String get line2 => userAd.title;
  @override
  String get price => userAd.price;
  @override
  String get location => "${userAd.emirate} ${userAd.district} ${userAd.area}";
  @override
  String get title =>
      "${userAd.make ?? ''} ${userAd.model ?? ''} ${userAd.trim ?? ''} ${userAd.year ?? ''}"
          .trim();
  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  AdPriority get priority {
    final plan = userAd.planType?.toLowerCase();
    if (plan == null || plan == 'free') return AdPriority.free;
    if (plan.contains('premium_star')) return AdPriority.PremiumStar;
    if (plan.contains('premium')) return AdPriority.premium;
    if (plan.contains('featured')) return AdPriority.featured;
    return AdPriority.free;
  }

  @override
  bool get isPremium => priority != AdPriority.free;
}

/// محول لتحويل UserAd إلى شكل إعلان خدمات السيارات
class CarServiceAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  CarServiceAdAdapter(this.userAd);

  @override
  String get contact => userAd.advertiserName;

  @override
  String get details => userAd.serviceType ?? '';

  @override
  String get imageUrl => userAd.mainImageUrl;

  @override
  List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty
      ? userAd.thumbnailImagesUrls
      : [userAd.mainImageUrl];

  @override
  String get line1 => userAd.title;

  @override
  String get line2 => userAd.serviceType ?? userAd.serviceName ?? '';

  @override
  String get price => userAd.price;

  @override
  String get location => "${userAd.emirate} ${userAd.district} ${userAd.area}";

  @override
  String get title => userAd.serviceName ?? '';

  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;

  // خصائص إضافية خاصة بخدمات السيارات
  String get serviceType => userAd.serviceType ?? '';
  String get serviceName => userAd.serviceName ?? '';
  @override
  String get id => userAd.id.toString();
  @override
  String get category => userAd.category;
  @override
  String get addCategory => userAd.addCategory;
}

/// محول لتحويل UserAd إلى شكل إعلان العقارات
class RealEstateAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  RealEstateAdAdapter(this.userAd);

  @override
  String get contact => userAd.advertiserName ?? '';

  @override
  String get details => "${userAd.property_type} ${userAd.contract_type}";

  @override
  String get imageUrl {
    final url = (userAd.mainImageUrl).trim();
    if (url.isNotEmpty) return url;
    return ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? '');
  }
  @override
  List<String> get images {
    final urls = userAd.thumbnailImagesUrls;
    if (urls.isNotEmpty) {
      return [userAd.mainImageUrl, ...urls].where((img) => img.isNotEmpty).toList();
    }
    return [
      ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? ''),
      ...ImageUrlHelper.getThumbnailImageUrls(userAd.thumbnailImages)
    ].where((img) => img.isNotEmpty).toList();
  }

  @override
  String get line1 => '';

  @override
  String get line2 => "${userAd.property_type} ${userAd.contract_type}";

  @override
  String get price => userAd.price;

  @override
  String get location =>
      '${userAd.emirate ?? ''} ${userAd.district ?? ''}  ${userAd.area ?? ''}';

  @override
  String get title => userAd.title;

  @override
  String get date => userAd.createdAt.split('T').first ?? '';

  @override
  bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
  @override
  String get id => userAd.id.toString();
  @override
  String get category => userAd.category;
  @override
  String get addCategory => userAd.addCategory;
}

/// محول لتحويل UserAd إلى شكل إعلان الإلكترونيات
class ElectronicsAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  ElectronicsAdAdapter(this.userAd);

  @override
  String get contact => userAd.advertiserName ?? '';

  @override
  String get details => userAd.product_name;

  @override
  String get imageUrl {
    final url = (userAd.mainImageUrl).trim();
    if (url.isNotEmpty) return url;
    return ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? '');
  }

  @override
  List<String> get images {
    final urls = userAd.thumbnailImagesUrls;
    if (urls.isNotEmpty) {
      return [userAd.mainImageUrl, ...urls].where((img) => img.isNotEmpty).toList();
    }
    return [
      ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? ''),
      ...ImageUrlHelper.getThumbnailImageUrls(userAd.thumbnailImages)
    ].where((img) => img.isNotEmpty).toList();
  }

  @override
  String get line1 => userAd.section_type;

  @override
  String get line2 => userAd.product_name;

  @override
  String get price => userAd.price;

  @override
  String get location =>
      "${userAd.emirate ?? ''} ${userAd.district ?? ''} ${userAd.area ?? ''}"
          .trim();

  @override
  String get title => userAd.title;

  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
  @override
  String get id => userAd.id.toString();
  @override
  String get category => userAd.category;
  @override
  String get addCategory => userAd.addCategory;
}

/// محول لتحويل UserAd إلى شكل إعلان الوظائف
class JobAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  JobAdAdapter(this.userAd);

  @override
  String get contact => userAd.advertiserName ?? '';

  @override
  String get details =>
      "${userAd.category_type ?? 'N/A'} ${userAd.section_type ?? 'N/A'} "; // Job Category Type

  @override
  String get imageUrl => (userAd.mainImageUrl).trim();

  @override
  List<String> get images {
    final urls = userAd.thumbnailImagesUrls;
    if (urls.isNotEmpty) {
      return [userAd.mainImageUrl, ...urls].where((img) => img.isNotEmpty).toList();
    }
    return [
      ImageUrlHelper.getMainImageUrl(userAd.mainImage ?? ''),
      ...ImageUrlHelper.getThumbnailImageUrls(userAd.thumbnailImages)
    ].where((img) => img.isNotEmpty).toList();
  }

  @override
  String get line1 => userAd.job_name;

  @override
  String get line2 => userAd.salary;

  @override
  String get price => userAd.salary;

  @override
  String get location =>
      '${userAd.emirate ?? ''} ${userAd.district ?? ''}  ${userAd.area ?? ''}';

  @override
  String get title => userAd.title;

  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
  @override
  String get id => userAd.id.toString();
  @override
  String get category => userAd.category;
  @override
  String get addCategory => userAd.addCategory;
}

/// محول لتحويل UserAd إلى شكل إعلان المطاعم
class RestaurantAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  RestaurantAdAdapter(this.userAd);

  @override
  String get contact => userAd.advertiserName ?? '';

  @override
  String get details => '';

  @override
  String get imageUrl => userAd.mainImageUrl;

  @override
  List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty
      ? userAd.thumbnailImagesUrls
      : [userAd.mainImageUrl];

  @override
  String get line1 => userAd.category.trim();

  @override
  String get line2 => '';

  @override
  String get price => userAd.price_range?.toString() ?? '';

  @override
  String get location => "${userAd.emirate} ${userAd.district} ${userAd.area}";

  @override
  String get title => userAd.title;

  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
  @override
  String get id => userAd.id.toString();
  @override
  String get category => userAd.category;
  @override
  String get addCategory => userAd.addCategory;
}

/// محول لتحويل UserAd إلى شكل إعلان الخدمات الأخرى
class OtherServiceAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  OtherServiceAdAdapter(this.userAd);

  @override
  String get contact => userAd.advertiserName ?? '';

  @override
  String get details {
    final sec = userAd.section_type.trim();
    if (sec.isNotEmpty && sec.toLowerCase() != 'null') return sec;
    final st = (userAd.serviceType ?? '').trim();
    if (st.isNotEmpty && st.toLowerCase() != 'null') return st;
    return '';
  }

  @override
  String get imageUrl => userAd.mainImageUrl;

  @override
  List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty
      ? userAd.thumbnailImagesUrls
      : [userAd.mainImageUrl];

  @override
  String get line1 => userAd.title;

  @override
  String get line2 {
    final sec = userAd.section_type.trim();
    if (sec.isNotEmpty && sec.toLowerCase() != 'null') return sec;
    final st = (userAd.serviceType ?? '').trim();
    if (st.isNotEmpty && st.toLowerCase() != 'null') return st;
    final sn = (userAd.serviceName ?? '').trim();
    if (sn.isNotEmpty && sn.toLowerCase() != 'null') return sn;
    return userAd.category;
  }

  @override
  String get price => userAd.price;

  @override
  String get location => "${userAd.emirate} ${userAd.district} ${userAd.area}";

  @override
  String get title {
    final sn = (userAd.serviceName ?? '').trim();
    if (sn.isNotEmpty && sn.toLowerCase() != 'null') return sn;
    return userAd.title;
  }

  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;

  // خصائص إضافية خاصة بالخدمات الأخرى
  String get serviceType => userAd.serviceType ?? '';
  String get serviceName => userAd.serviceName ?? '';
  @override
  String get id => userAd.id.toString();
  @override
  String get category => userAd.category;
  @override
  String get addCategory => userAd.addCategory;
}

/// Factory class لإنشاء المحول المناسب حسب فئة الإعلان
class UserAdAdapterFactory {
  static FavoriteItemInterface createAdapter(UserAd userAd) {
    switch (userAd.addCategory.toLowerCase()) {
      case 'car_sales':
      case 'cars':
        return CarSalesAdAdapter(userAd);
      case 'car_rent':
        return CarRentAdAdapter(userAd);
      case 'car_service':
        return CarServiceAdAdapter(userAd);
      case 'real_estate':
        return RealEstateAdAdapter(userAd);
      case 'electronics':
        return ElectronicsAdAdapter(userAd);
      case 'jobs':
        return JobAdAdapter(userAd);
      case 'restaurants':
        return RestaurantAdAdapter(userAd);
      case 'other_services':
        return OtherServiceAdAdapter(userAd);
      default:
        // استخدام محول عام للفئات غير المعروفة
        return _GenericAdAdapter(userAd);
    }
  }
}

/// محول عام للفئات غير المعروفة
class _GenericAdAdapter implements FavoriteItemInterface {
  final UserAd userAd;

  _GenericAdAdapter(this.userAd);

  @override
  String get contact => userAd.whatsappNumber ?? userAd.phoneNumber ?? '';

  @override
  String get details => userAd.description;

  @override
  String get imageUrl => userAd.mainImageUrl;

  @override
  List<String> get images => userAd.thumbnailImagesUrls.isNotEmpty
      ? userAd.thumbnailImagesUrls
      : [userAd.mainImageUrl];

  @override
  String get line1 => userAd.title;

  @override
  String get line2 => userAd.category;

  @override
  String get price => userAd.price;

  @override
  String get location => "${userAd.emirate} ${userAd.district} ${userAd.area}";

  @override
  String get title => userAd.title;

  @override
  String get date => userAd.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium => userAd.planType != null && userAd.planType!.isNotEmpty;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
  @override
  String get id => userAd.id.toString();
  @override
  String get category => userAd.category;
  @override
  String get addCategory => userAd.addCategory;
}
