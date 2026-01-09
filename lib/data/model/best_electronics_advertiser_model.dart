// lib/data/model/best_electronics_advertiser_model.dart

class BestElectronicsAd {
  final int id;
  final String title;
  final String price;
  final String emirate;
  final String district;
  final String area;
  final String productName;
  final String mainImage;
  final String mainImageUrl;
  final List<String> thumbnailImagesUrls;
  final String status;
  final String category;
  

  BestElectronicsAd({
    required this.id,
    required this.title,
    required this.price,
    required this.emirate,
    required this.district,
    required this.area,
    required this.productName,
    required this.mainImage,
    required this.mainImageUrl,
    required this.thumbnailImagesUrls,
    required this.status,
    required this.category,
  });

  factory BestElectronicsAd.fromJson(Map<String, dynamic> json) {
    return BestElectronicsAd(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: json['price']?.toString() ?? '0',
      emirate: json['emirate'] ?? '',
      district: json['district'] ?? '',
      area: json['area'] ?? '',
      productName: json['product_name'] ?? '',
      mainImage: json['main_image'] ?? '',
      mainImageUrl: json['main_image_url'] ?? '',
      thumbnailImagesUrls: json['thumbnail_images_urls'] != null 
          ? List<String>.from(json['thumbnail_images_urls']) 
          : [],
      status: json['status'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class BestElectronicsAdvertiser {
  final int id;
  final String advertiserName;
  final String category;
  final List<BestElectronicsAd> latestAds;

  BestElectronicsAdvertiser({
    required this.id,
    required this.advertiserName,
    required this.category,
    required this.latestAds,
  });

  factory BestElectronicsAdvertiser.fromJson(Map<String, dynamic> json) {
    // استخدام user_id بدلاً من id للحصول على معرف المعلن الصحيح
    return BestElectronicsAdvertiser(
      id: json['user_id'] ?? 0,
      advertiserName: json['advertiser_name'] ?? '',
      category: json['category'] ?? '',
      latestAds: json['latest_ads'] != null
          ? (json['latest_ads'] as List)
              .map((adJson) => BestElectronicsAd.fromJson(adJson))
              .toList()
          : [],
    );
  }
}