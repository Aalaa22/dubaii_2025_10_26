import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/constant/image_url_helper.dart';

// Adapter for BestAdvertiserAd in Car Sales category
class BestAdvertiserCarSalesItemAdapter implements FavoriteItemInterface {
  final BestAdvertiserAd ad;
  BestAdvertiserCarSalesItemAdapter(this.ad);

  @override
  String get id => ad.id.toString();

  @override
  String get title => "${ad.make} ${ad.model} ${ad.trim ?? ''}".trim();

  @override
  String get location => [ad.emirate ?? '', ad.district ?? '', ad.area ?? '']
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  @override
  String get price => ad.price;

  @override
  String get line1 => "Year: ${ad.year}  Km: ${ad.km}";

  @override
  String get details => title;

  @override
  String get date => '';

  @override
  String get contact => ad.advertiserName;

  @override
  bool get isPremium => false;

  @override
  List<String> get images {
    final main = (ad.mainImage).trim();
    final thumbs = ad.images;
    final all = [main, ...thumbs]
        .map((e) => ImageUrlHelper.getFullImageUrl(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return all.isNotEmpty ? all : [main].where((e) => e.isNotEmpty).toList();
  }

  @override
  String get category => 'car_sales';

  @override
  String get addCategory => (ad.category?.trim().isNotEmpty ?? false)
      ? ad.category!.trim()
      : 'car_sales';

  @override
  AdPriority get priority => AdPriority.free;
}

// Adapter for BestAdvertiserAd in Jobs category
class BestAdvertiserJobItemAdapter implements FavoriteItemInterface {
  final BestAdvertiserAd ad;
  BestAdvertiserJobItemAdapter(this.ad);

  @override
  String get id => ad.id.toString();

  @override
  String get title => (ad.title?.trim().isNotEmpty == true
      ? ad.title!.trim()
      : (ad.job_name?.trim() ?? ''));

  @override
  String get location => [ad.emirate ?? '', ad.district ?? '', ad.area ?? '']
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  @override
  String get price => (ad.priceRange?.trim().isNotEmpty == true
      ? ad.priceRange!.trim()
      : (ad.salary?.trim() ?? ''));

  @override
  String get line1 => (ad.job_name?.trim().isNotEmpty == true
      ? ad.job_name!.trim()
      : (ad.title?.trim() ?? ''));

  @override
  String get details => price;

  @override
  String get date => '';

  @override
  String get contact => ad.advertiserName;

  @override
  bool get isPremium => false;

  @override
  List<String> get images {
    final main = (ad.mainImage).trim();
    final thumbs = ad.images;
    final all = [main, ...thumbs]
        .map((e) => ImageUrlHelper.getFullImageUrl(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return all.isNotEmpty ? all : [main].where((e) => e.isNotEmpty).toList();
  }

  @override
  String get category => 'jobs';

  @override
  String get addCategory => (ad.category?.trim().isNotEmpty ?? false)
      ? ad.category!.trim()
      : 'jobs';

  @override
  AdPriority get priority => AdPriority.free;
}

// Adapter for BestAdvertiserAd in Restaurant category
class BestAdvertiserRestaurantItemAdapter implements FavoriteItemInterface {
  final BestAdvertiserAd ad;
  BestAdvertiserRestaurantItemAdapter(this.ad);

  @override
  String get id => ad.id.toString();

  @override
  String get title => ad.title?.trim() ?? '';

  @override
  String get location => [ad.emirate ?? '', ad.district ?? '', ad.area ?? '']
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  @override
  String get price => ad.priceRange?.trim() ?? '';

  @override
  String get line1 => title;

  @override
  String get details => title;

  @override
  String get date => '';

  @override
  String get contact => ad.advertiserName;

  @override
  bool get isPremium => false;

  @override
  List<String> get images {
    final main = (ad.mainImage).trim();
    final thumbs = ad.images;
    final all = [main, ...thumbs]
        .map((e) => ImageUrlHelper.getFullImageUrl(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return all.isNotEmpty ? all : [main].where((e) => e.isNotEmpty).toList();
  }

  @override
  String get category => 'restaurant';

  @override
  String get addCategory => (ad.category?.trim().isNotEmpty ?? false)
      ? ad.category!.trim()
      : 'restaurant';

  @override
  AdPriority get priority => AdPriority.free;
}

// Adapter for BestAdvertiserAd in Real Estate category
class BestAdvertiserRealEstateItemAdapter implements FavoriteItemInterface {
  final BestAdvertiserAd ad;
  BestAdvertiserRealEstateItemAdapter(this.ad);

  @override
  String get id => ad.id.toString();

  @override
  String get title {
    final p = (ad.propertyType ?? '').trim();
    final c = (ad.contractType ?? '').trim();
    final t = (ad.title ?? '').trim();
    final combined = [p, c].where((e) => e.isNotEmpty).join(' ');
    return combined.isNotEmpty ? combined : t;
  }

  @override
  String get location => [ad.emirate ?? '', ad.district ?? '', ad.area ?? '']
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  @override
  String get price => ad.price;

  @override
  String get line1 => title;

  @override
  String get details => title;

  @override
  String get date => '';

  @override
  String get contact => ad.advertiserName;

  @override
  bool get isPremium => false;

  @override
  List<String> get images {
    final main = (ad.mainImage).trim();
    final thumbs = ad.images;
    final all = [main, ...thumbs]
        .map((e) => ImageUrlHelper.getFullImageUrl(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return all.isNotEmpty ? all : [main].where((e) => e.isNotEmpty).toList();
  }

  @override
  String get category => 'real_estate';

  @override
  String get addCategory => (ad.category?.trim().isNotEmpty ?? false)
      ? ad.category!.trim()
      : 'real_estate';

  @override
  AdPriority get priority => AdPriority.free;
}

// Adapter for BestAdvertiserAd in Other Services category
class BestAdvertiserOtherServiceItemAdapter implements FavoriteItemInterface {
  final BestAdvertiserAd ad;
  BestAdvertiserOtherServiceItemAdapter(this.ad);

  @override
  String get id => ad.id.toString();

  @override
  String get title {
    final name = (ad.title?.trim().isNotEmpty == true)
        ? ad.title!.trim()
        : (ad.serviceName?.trim() ?? '');
    return name;
  }

  @override
  String get location => [ad.emirate ?? '', ad.district ?? '', ad.area ?? '']
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  @override
  String get price => ad.price;

  @override
  String get line1 {
    final st = (ad.serviceType ?? '').trim();
    final sn = (ad.serviceName ?? '').trim();
    if (sn.isNotEmpty) return sn;
    if (st.isNotEmpty) return st;
    return title;
  }

  @override
  String get details => line1;

  @override
  String get date => '';

  @override
  String get contact => ad.advertiserName;

  @override
  bool get isPremium => false;

  @override
  List<String> get images {
    final main = (ad.mainImage).trim();
    final thumbs = ad.images;
    final all = [main, ...thumbs]
        .map((e) => ImageUrlHelper.getFullImageUrl(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return all.isNotEmpty ? all : [main].where((e) => e.isNotEmpty).toList();
  }

  @override
  String get category => 'other_services';

  @override
  String get addCategory => (ad.category?.trim().isNotEmpty ?? false)
      ? ad.category!.trim()
      : 'Other Services';

  @override
  AdPriority get priority => AdPriority.free;
}

// Adapter for BestAdvertiserAd in Car Services category
class BestAdvertiserCarServiceItemAdapter implements FavoriteItemInterface {
  final BestAdvertiserAd ad;
  BestAdvertiserCarServiceItemAdapter(this.ad);

  @override
  String get id => ad.id.toString();

  @override
  String get title {
    final name = (ad.serviceName?.trim().isNotEmpty == true)
        ? ad.serviceName!.trim()
        : (ad.title?.trim() ?? '');
    return name;
  }

  @override
  String get location => [ad.emirate ?? '', ad.district ?? '', ad.area ?? '']
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  @override
  String get price => ad.price;

  @override
  String get line1 {
    final st = (ad.serviceType ?? '').trim();
    final sn = (ad.serviceName ?? '').trim();
    if (sn.isNotEmpty) return sn;
    if (st.isNotEmpty) return st;
    return title;
  }

  @override
  String get details => line1;

  @override
  String get date => '';

  @override
  String get contact => ad.advertiserName;

  @override
  bool get isPremium => false;

  @override
  List<String> get images {
    final main = (ad.mainImage).trim();
    final thumbs = ad.images;
    final all = [main, ...thumbs]
        .map((e) => ImageUrlHelper.getFullImageUrl(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return all.isNotEmpty ? all : [main].where((e) => e.isNotEmpty).toList();
  }

  @override
  String get category => 'car_services';

  @override
  String get addCategory => (ad.category?.trim().isNotEmpty ?? false)
      ? ad.category!.trim()
      : 'Car Services';

  @override
  AdPriority get priority => AdPriority.free;
}