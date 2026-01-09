class NumberFormatter {
  /// تنسيق الأرقام بإضافة فواصل كل 3 أرقام
  /// مثال: 1234567 -> 1,234,567
  static String formatNumber(dynamic number) {
    if (number == null) return '0';
    
    String numberStr;
    if (number is String) {
      // إزالة أي فواصل موجودة مسبقاً والمسافات
      numberStr = number.replaceAll(RegExp(r'[,\s]'), '');
      // التحقق من أن النص يحتوي على أرقام فقط (مع دعم الأرقام العشرية)
      // تحسين regex للتعامل مع الأسعار بشكل أفضل - يقبل 0, 0.00, 100, 100.50 إلخ
      final regexMatch = RegExp(r'^\d*(\.\d+)?$').hasMatch(numberStr) && numberStr != '.' && numberStr.isNotEmpty;
      if (!regexMatch) {
        return '0'; // إرجاع 0 إذا لم يكن رقماً صحيحاً
      }
    } else {
      numberStr = number.toString();
    }
    
    // التعامل مع الأرقام العشرية
    List<String> parts = numberStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    // تحويل إلى رقم للتأكد من صحته
    double? parsedNumber = double.tryParse(numberStr);
    if (parsedNumber == null) return '0';
    
    // تطبيق التنسيق على الجزء الصحيح
    String formattedInteger = '';
    String reversed = integerPart.split('').reversed.join('');
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formattedInteger = ',$formattedInteger';
      }
      formattedInteger = reversed[i] + formattedInteger;
    }
    
    // إضافة الجزء العشري فقط إذا كان موجوداً وليس صفراً
    if (decimalPart.isNotEmpty && decimalPart != '0' && decimalPart != '00') {
      // إزالة الأصفار الزائدة من نهاية الجزء العشري
      decimalPart = decimalPart.replaceAll(RegExp(r'0+$'), '');
      if (decimalPart.isNotEmpty) {
        return '$formattedInteger.$decimalPart';
      }
    }
    
    return formattedInteger;
  }
  
  /// تنسيق السعر مع إضافة العملة
  /// مثال: formatPrice(1234567) -> '1,234,567 AED'
  static String formatPrice(dynamic price) {
    if (price == null) return '0 AED';
    String formattedNumber = formatNumber(price);
    return '$formattedNumber AED';
  }
  
  /// تنسيق الكيلومترات مع إضافة الوحدة
  /// مثال: formatKilometers(123456) -> '123,456 KM'
  static String formatKilometers(dynamic km) {
    if (km == null) return '0 KM';
    String formattedNumber = formatNumber(km);
    return '$formattedNumber KM';
  }
  
  /// تنسيق الأرقام للعرض في الواجهة
  /// يتعامل مع القيم الفارغة والنصوص غير الصحيحة
  static String formatDisplayNumber(dynamic number) {
    if (number == null || number.toString().trim().isEmpty) {
      return '0';
    }
    return formatNumber(number);
  }
}