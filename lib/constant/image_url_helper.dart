class ImageUrlHelper {
  // الحصول على baseUrl (يجب أن يتطابق مع ApiService)
  static const String _baseUrl = 'https://dubaisale.app';

  /// تحويل مسار الصورة النسبي إلى URL كامل
  /// مثال: "cars/main/image.jpg" -> "https://dubaisale.app/storage/cars/main/image.jpg"
  static String getFullImageUrl(String? imagePath) {
   // print('🖼️ ImageUrlHelper.getFullImageUrl - Input: "$imagePath"');
    
    if (imagePath == null || imagePath.isEmpty) {
     // print('🖼️ ImageUrlHelper - Input is null or empty, returning empty string');
      return '';
    }

    // تنظيف المسار من المسافات الإضافية
    final cleanPath = imagePath.trim();
   // print('🖼️ ImageUrlHelper - After trim: "$cleanPath"');
    
    if (cleanPath.isEmpty) {
     // print('🖼️ ImageUrlHelper - Clean path is empty, returning empty string');
      return '';
    }

    // إذا كان المسار يحتوي بالفعل على http أو https، فهو URL كامل
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
     // print('🖼️ ImageUrlHelper - Already full URL, returning: "$cleanPath"');
      return cleanPath;
    }

    // إذا كان المسار يبدأ بـ file:// اعتبره مساراً محلياً ضمن التخزين وحوله إلى URL كامل
    if (cleanPath.startsWith('file://')) {
      // إزالة المخطط file:// والحفاظ على الشرطة المائلة الأولى إن كانت موجودة
      final withoutScheme = cleanPath.substring('file://'.length).trim();
      // إذا كان المسار يحتوي على /storage/ بالفعل، استخدمه مباشرة
      if (withoutScheme.contains('/storage/')) {
        final normalized = withoutScheme.startsWith('/') ? withoutScheme : '/$withoutScheme';
        final finalUrl = '$_baseUrl$normalized';
        return finalUrl;
      } else {
        // إضافة /storage/ إذا لم يكن موجوداً
        final normalized = withoutScheme.startsWith('/') ? withoutScheme.substring(1) : withoutScheme;
        final finalUrl = '$_baseUrl/storage/$normalized';
        return finalUrl;
      }
    }

    // Handle malformed URLs that might contain embedded full URLs with backticks
    // Example: "/storage/ `https://dubaisale.app/storage/car_rent/main/file.jpg` "
    if (cleanPath.contains('`') && cleanPath.contains('https://')) {
     // print('🖼️ ImageUrlHelper - Found backticks and https, processing malformed URL');
      // Extract the full URL from between backticks
      RegExp regExp = RegExp(r'`(https://[^`]+)`');
      Match? match = regExp.firstMatch(cleanPath);
      if (match != null) {
        final extractedUrl = match.group(1)!.trim();
       // print('🖼️ ImageUrlHelper - Extracted URL from backticks: "$extractedUrl"');
        return extractedUrl;
      }
      // Fallback: try to extract any https URL
      RegExp httpsRegExp = RegExp(r'https://[^\s`]+');
      Match? httpsMatch = httpsRegExp.firstMatch(cleanPath);
      if (httpsMatch != null) {
        final extractedUrl = httpsMatch.group(0)!.trim();
       // print('🖼️ ImageUrlHelper - Extracted HTTPS URL (fallback): "$extractedUrl"');
        return extractedUrl;
      }
    }

    // إذا بدأ المسار بشرطة مائلة "/" (مثل "/storage/..." أو "/images/..."),
    // نضيف الدومين مباشرة بدون إضافة "/storage" مرة أخرى
    if (cleanPath.startsWith('/')) {
      final finalUrl = '$_baseUrl$cleanPath';
     // print('🖼️ ImageUrlHelper - Path starts with "/", final URL: "$finalUrl"');
      return finalUrl;
    }

    // الحالات الأخرى (مسارات نسبية لا تبدأ بـ "/") نضيف "/storage/" كالمعتاد
    final finalUrl = '$_baseUrl/storage/$cleanPath';
   // print('🖼️ ImageUrlHelper - Relative path, final URL: "$finalUrl"');
    return finalUrl;
  }

  /// تحويل قائمة من مسارات الصور إلى URLs كاملة
  static List<String> getFullImageUrls(List<String>? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) {
      return [];
    }

    return imagePaths.map((path) => getFullImageUrl(path)).toList();
  }

  /// الحصول على URL الصورة الرئيسية
  static String getMainImageUrl(String? mainImagePath) {
    return getFullImageUrl(mainImagePath);
  }

  /// الحصول على URLs الصور المصغرة
  static List<String> getThumbnailImageUrls(List<String>? thumbnailPaths) {
    return getFullImageUrls(thumbnailPaths);
  }
}