

import 'lib/constant/image_url_helper.dart';

void main() {
  // اختبار تحويل مسار الصورة الرئيسية
  String mainImagePath = 'cars/main/uqGOaq4nkHHOjaU7UzdwxoN8niozA9QzkPXqq0MO.jpg';
  String fullMainImageUrl = ImageUrlHelper.getMainImageUrl(mainImagePath);
  print('Main Image URL: $fullMainImageUrl');
  
  // اختبار تحويل قائمة الصور المصغرة
  List<String> thumbnailPaths = [
    'cars/thumbnails/image1.jpg',
    'cars/thumbnails/image2.jpg',
    'cars/thumbnails/image3.jpg'
  ];
  List<String> fullThumbnailUrls = ImageUrlHelper.getThumbnailImageUrls(thumbnailPaths);
  print('Thumbnail URLs:');
  for (String url in fullThumbnailUrls) {
    print('  - $url');
  }
  
  // اختبار مع مسار فارغ
  String emptyPath = '';
  String emptyResult = ImageUrlHelper.getFullImageUrl(emptyPath);
  print('Empty path result: "$emptyResult"');
  
  // اختبار مع URL كامل بالفعل
  String fullUrl = 'https://example.com/image.jpg';
  String fullUrlResult = ImageUrlHelper.getFullImageUrl(fullUrl);
  print('Full URL result: $fullUrlResult');
}