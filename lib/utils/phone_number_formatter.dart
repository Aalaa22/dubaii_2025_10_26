// المسار: lib/utils/phone_number_formatter.dart

class PhoneNumberFormatter {

  /// قائمة بكودات الدول المقبولة (ISO 3166-1 alpha-2)
  static const Map<String, String> countryCodes = {
    'AE': '+971', // الإمارات العربية المتحدة
    'SA': '+966', // المملكة العربية السعودية
    'KW': '+965', // الكويت
    'QA': '+974', // قطر
    'BH': '+973', // البحرين
    'OM': '+968', // سلطنة عمان
    'EG': '+20',  // مصر
    'JO': '+962', // الأردن
    'LB': '+961', // لبنان
    'SY': '+963', // سوريا
  };

  /// قائمة بأنماط أرقام الهواتف حسب الدولة
  static final Map<String, RegExp> countryPatterns = {
    'AE': RegExp(r'^(\+971|00971|0)?[1-9][0-9]{7,8}$'),
    'SA': RegExp(r'^(\+966|00966|0)?5[0-9]{8}$'),
    'KW': RegExp(r'^(\+965|00965|0)?[1-9][0-9]{7}$'),
    'QA': RegExp(r'^(\+974|00974|0)?[1-9][0-9]{7}$'),
    'BH': RegExp(r'^(\+973|00973|0)?[1-9][0-9]{7}$'),
    'OM': RegExp(r'^(\+968|00968|0)?[1-9][0-9]{7}$'),
    'EG': RegExp(r'^(\+20|0020|0)?1[0-9]{9}$'),
    'JO': RegExp(r'^(\+962|00962|0)?7[0-9]{8}$'),
    'LB': RegExp(r'^(\+961|00961|0)?[1-9][0-9]{7}$'),
    'SY': RegExp(r'^(\+963|00963|0)?9[0-9]{8}$'),
  };

  /// ينسق رقم الهاتف للصيغة الدولية مع التحقق من صحة كود الدولة
  static String formatForApi(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return '';
    }

    // إزالة أي مسافات أو رموز غير الأرقام
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // البحث عن كود الدولة المناسب
    for (var entry in countryCodes.entries) {
      String countryCode = entry.value;
      String codeWithoutPlus = countryCode.substring(1);
      
      if (digitsOnly.startsWith(codeWithoutPlus)) {
        return '+$digitsOnly';
      }
    }

    // التحقق من أنماط الأرقام لكل دولة
    for (var entry in countryPatterns.entries) {
      if (entry.value.hasMatch(phoneNumber)) {
        String countryCode = countryCodes[entry.key]!;
        
        // إزالة كود الدولة أو البادئة المحلية
        String localNumber = digitsOnly;
        if (digitsOnly.startsWith(countryCode.substring(1))) {
          localNumber = digitsOnly.substring(countryCode.substring(1).length);
        } else if (digitsOnly.startsWith('0')) {
          localNumber = digitsOnly.substring(1);
        }
        
        return '$countryCode$localNumber';
      }
    }

    // إذا لم يتم التعرف على أي نمط، استخدم كود الإمارات كافتراضي
    if (digitsOnly.startsWith('0')) {
      return '+971${digitsOnly.substring(1)}';
    }
    
    return '+971$digitsOnly';
  }

  /// يتحقق من صحة رقم الهاتف وكود الدولة
  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return false;
    }

    String normalized = phoneNumber.trim();
    
    // التحقق من أنماط الأرقام لكل دولة
    for (var entry in countryPatterns.entries) {
      if (entry.value.hasMatch(normalized)) {
        return true;
      }
    }

    // التحقق من الأرقام التي تبدأ بكود الدولة
    for (var entry in countryCodes.entries) {
      String countryCode = entry.value;
      String codeWithoutPlus = countryCode.substring(1);
      
      if (normalized.startsWith(countryCode) || 
          normalized.startsWith('00$codeWithoutPlus') ||
          (normalized.startsWith('0') && !normalized.startsWith('00'))) {
        return true;
      }
    }

    return false;
  }

  /// يعيد كود الدولة من رقم الهاتف
  static String? getCountryCode(String phoneNumber) {
    String normalized = phoneNumber.trim();
    
    for (var entry in countryCodes.entries) {
      if (normalized.startsWith(entry.value)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// يتحقق إذا كان الرقم خاص بدولة الإمارات
  static bool isValidUAENumber(String phoneNumber) {
    String normalized = phoneNumber.trim();
    RegExp uaePattern = countryPatterns['AE']!;
    return uaePattern.hasMatch(normalized);
  }

  /// يعيد رسالة الخطأ المناسبة حسب الدولة
  static String getValidationMessage(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return "Phone number is required";
    }

    String normalized = phoneNumber.trim();
    
    // التحقق من الأرقام التي لا تحتوي على كود دولة
    if (!normalized.startsWith('+') && !normalized.startsWith('00')) {
      return "Please include country code (e.g., +971, +966)";
    }

    return "Please enter a valid phone number with correct country code";
  }

  /// ينشئ رابط واتساب قابل للضغط مع التحقق من الصحة
  static String getWhatsAppUrl(String phoneNumber) {
    if (!isValidPhoneNumber(phoneNumber)) {
      throw ArgumentError('Invalid phone number format');
    }
    
    final formattedNumber = formatForApi(phoneNumber);
    final numberForUrl = formattedNumber.replaceAll(RegExp(r'\D'), '');
    return 'https://wa.me/$numberForUrl';
  }

  /// ينشئ رابط اتصال هاتفي قابل للضغط مع التحقق من الصحة
  static String getTelUrl(String phoneNumber) {
    if (!isValidPhoneNumber(phoneNumber)) {
      throw ArgumentError('Invalid phone number format');
    }
    
    final formattedNumber = formatForApi(phoneNumber);
    return 'tel:$formattedNumber';
  }
}