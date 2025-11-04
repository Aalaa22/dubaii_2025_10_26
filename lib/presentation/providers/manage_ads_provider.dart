import 'dart:async';
import 'package:advertising_app/data/model/my_ad_model.dart';
import 'package:advertising_app/data/repository/manage_ads_repository.dart';
import 'package:advertising_app/data/repository/jobs_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';


class MyAdsProvider with ChangeNotifier {
  final ManageAdsRepository _myAdsRepository;
  MyAdsProvider(this._myAdsRepository);

  // التخزين الآمن مثل JobAdProvider لضمان نفس المصدر
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // مستودع الوظائف لجلب صور فئات الوظائف
  final JobsRepository _jobsRepository = JobsRepository(ApiService());

  // خريطة صور الفئات (job_offer, job_seeker)
  Map<String, String> _jobCategoryImages = {};
  Map<String, String> get jobCategoryImages => _jobCategoryImages;

  // --- حالات Provider ---
  bool _isLoading = false;
  String? _error;
  
  List<MyAdModel> _allAds = []; // قائمة تحتوي على كل الإعلانات الأصلية
  List<MyAdModel> _filteredAds = []; // القائمة التي ستعرض على الشاشة
  String _selectedStatus = 'All'; // الفلتر المختار حالياً
  
  // --- متغيرات التحديث التلقائي ---
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = false;
  bool _disposed = false;

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MyAdModel> get displayedAds => _filteredAds; // الشاشة ستستخدم هذه القائمة
  String get selectedStatus => _selectedStatus;

  // --- دوال رئيسية ---
  
  // دالة لجلب البيانات من الـ API
  Future<void> fetchMyAds({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      safeNotifyListeners();
    }

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('User is not authenticated.');
      }
      
      // جلب صور فئات الوظائف مرة واحدة لاستخدامها في شاشة الإدارة
      try {
        _jobCategoryImages = await _jobsRepository.getJobCategoryImages(token: token);
      } catch (e) {
        // إذا فشل الجلب، دع الخريطة فارغة وسيتم استخدام صورة الإعلان الافتراضية
        _jobCategoryImages = {};
      }

      // Pass token to repository to avoid 401 Unauthorized
      final response = await _myAdsRepository.getMyAds(token: token);
      _allAds = response.ads;
      
      // إعادة تطبيق الفلتر الحالي
      filterAdsByStatus(_selectedStatus);
      
    } catch (e) {
      _error = e.toString();
      print("Error fetching my ads: $e");
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      safeNotifyListeners();
    }
  }
  
  // دالة لبدء التحديث التلقائي
  void startAutoRefresh() {
    if (_isAutoRefreshEnabled) return;
    
    _isAutoRefreshEnabled = true;
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchMyAds(showLoading: false); // تحديث بدون إظهار مؤشر التحميل
    });
  }
  
  // دالة لإيقاف التحديث التلقائي
  void stopAutoRefresh() {
    _isAutoRefreshEnabled = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
  
  @override
  void dispose() {
    _disposed = true;
    stopAutoRefresh();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
  
  // دالة لفلترة الإعلانات بناءً على الحالة
  void filterAdsByStatus(String status) {
    _selectedStatus = status;
    
    if (status == 'All') {
      _filteredAds = _allAds;
    } else {
      // قم بتصفية القائمة الأصلية
      _filteredAds = _allAds.where((ad) => ad.status == status).toList();
    }
    
    safeNotifyListeners(); // لإعلام الواجهة بالتغييرات
  }
  
  // دالة لتنسيق السعر بفواصل كل 3 أرقام وإضافة فاصلتين عشريتين
  String formatPrice(String price) {
    // إزالة أي أحرف غير رقمية
    String cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleanPrice.isEmpty) return price;
    
    try {
      // تحويل السعر إلى رقم عشري
      double priceValue = double.parse(cleanPrice);
      
      // إذا كان الرقم كبير جداً (مثل 200000 بدلاً من 2000)، قسّمه على 100
      // هذا قد يحدث إذا كان السعر يأتي بالسنتات أو بصيغة خاطئة
      if (priceValue > 100000 && priceValue % 100 == 0) {
        priceValue = priceValue / 100;
      }
      
      // تنسيق الرقم بفواصل كل 3 أرقام وفاصلتين عشريتين
      NumberFormat formatter = NumberFormat('#,##0.00', 'en_US');
      return formatter.format(priceValue);
    } catch (e) {
      // في حالة حدوث خطأ، إرجاع السعر الأصلي
      return price;
    }
  }
  
  // دالة لإنشاء عنوان الإعلان بصيغة Make - Model - Trim
  String createAdTitle(MyAdModel ad) {
    List<String> titleParts = [];
    
    if (ad.make != null && ad.make!.isNotEmpty) {
      titleParts.add(ad.make!);
    }
    
    if (ad.model != null && ad.model!.isNotEmpty) {
      titleParts.add(ad.model!);
    }
    
    if (ad.trim != null && ad.trim!.isNotEmpty) {
      titleParts.add(ad.trim!);
    }
    
    // إذا لم تكن هناك بيانات Make/Model/Trim، استخدم العنوان الأصلي بعد تنقيته من السنة
    if (titleParts.isEmpty) {
      // إزالة السنة (أي رقم من 4 خانات) من العنوان الأصلي
      String cleanedTitle = ad.title.replaceAll(RegExp(r'\b\d{4}\b'), '').trim();
      // إزالة أي مسافات أو شرطات متتالية
      cleanedTitle = cleanedTitle.replaceAll(RegExp(r'[\s\-]+'), ' ').trim();
      return cleanedTitle.isEmpty ? ad.title : cleanedTitle;
    }
    
    return titleParts.join(' - ');
  }


    // +++ أضف هذه الحالات الجديدة +++
  bool _isActivatingOffer = false;
  String? _activationError;
  int? _activatingAdId; // لتحديد أي إعلان يتم تفعيله

  bool get isActivatingOffer => _isActivatingOffer;
  String? get activationError => _activationError;
  int? get activatingAdId => _activatingAdId;


  // ... (بقية الدوال تبقى كما هي)


  // +++ أضف هذه الدالة الجديدة +++
  Future<bool> activateOffer({
    required int adId,
    required String categorySlug,
    required int days,
  }) async {
    _isActivatingOffer = true;
    _activationError = null;
    _activatingAdId = adId; // حدد الإعلان الحالي
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _activationError = 'Authentication token not found. Please login again.';
        return false;
      }

      // تطبيع قيمة الـ slug لإزالة الالتباس بين الشرطات والشرطات السفلية وحالات الأحرف
      String _normalizeCategorySlug(String slug) {
        final s = slug.toLowerCase().trim();
        if (s.contains('car-sales') || s.contains('car_sales')) return 'car_sales';
        if (s.contains('car-rent') || s.contains('car_rent')) return 'car_rent';
        // استخدم الشرطة الوسطى للفئة "خدمات السيارات" وفق ما تستخدمه واجهات العروض
        if (s.contains('car-services') || s.contains('car_services')) return 'car_services';
        if (s.contains('restaurant')) return 'restaurant';
        if (s.contains('real-estate') || s.contains('real_estate')) return 'real-estate';
        if (s.contains('electronics') || s.contains('electronic')) return 'electronics';
        // Jobs category: backend expects singular 'job' for activation
        if (s.contains('jobs') || s.contains('job') || s.contains('jop')) return 'Jobs';
        if (s.contains('other-services') || s.contains('other_services')) return 'other_services';
        return s;
      }
      final normalizedSlug = _normalizeCategorySlug(categorySlug);
      
      print('=== ACTIVATING OFFER DEBUG ===');
      print('Ad ID: $adId');
      print('Category Slug: $normalizedSlug');
      print('Days: $days');
      print('Token: ${token.substring(0, 20)}...');
      print('=============================');
      
      await _myAdsRepository.activateOffer(
        token: token,
        adId: adId,
        categorySlug: normalizedSlug,
        days: days,
      );
      
      print('=== OFFER ACTIVATION SUCCESS ===');
      print('Ad $adId activated successfully');
      print('===============================');
      
      // بعد النجاح، يمكنك إعادة تحميل الإعلانات لتحديث حالتها
      await fetchMyAds();
      return true;

    } catch (e) {
      // معالجة أفضل لرسائل الخطأ
      String errorMessage = e.toString();
      final lower = errorMessage.toLowerCase();
      
      // إذا كان الخطأ يحتوي على معلومات عن category_slug غير صحيح
      if (lower.contains('category_slug') || lower.contains('invalid')) {
        _activationError = 'فئة الإعلان غير صحيحة. يرجى المحاولة مرة أخرى.';
      } else if (lower.contains('full') || lower.contains('max')) {
        _activationError = 'صندوق العروض ممتلئ حالياً. يرجى المحاولة لاحقاً.';
      } else if (lower.contains('already')) {
        // رسالة عربية + إنجليزية كما طلب المستخدم
        _activationError = 'هذا الإعلان موجود بالفعل في صندوق العروض.\nThis ad is already in the Offers Box.';
      } else if (lower.contains('unauthorized') || lower.contains('403')) {
        _activationError = 'ليس لديك صلاحية لتفعيل هذا الإعلان.';
      } else if (lower.contains('not found') || lower.contains('404')) {
        _activationError = 'الإعلان غير موجود.';
      } else {
        _activationError = 'حدث خطأ أثناء تفعيل الإعلان. يرجى المحاولة مرة أخرى.';
      }
      
      print('=== OFFER ACTIVATION ERROR ===');
      print('Original Error: $e');
      print('User-friendly Error: $_activationError');
      print('=============================');
      return false;
    } finally {
      _isActivatingOffer = false;
      _activatingAdId = null; // أعد تعيين ID الإعلان
      notifyListeners();
    }
  }

  // دالة حذف إعلان بحسب الفئة
  Future<bool> deleteAd({
    required MyAdModel ad,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _error = 'Authentication token not found. Please login again.';
        safeNotifyListeners();
        return false;
      }

      await _myAdsRepository.deleteAd(token: token, id: ad.id, category: ad.category);

      // إزالة الإعلان محلياً من القوائم وإبلاغ الواجهة
      _allAds.removeWhere((a) => a.id == ad.id);
      _filteredAds.removeWhere((a) => a.id == ad.id);
      safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      safeNotifyListeners();
      return false;
    }
  }

  // تنفيذ طلب "make-rank-one" لجعل إعلان المستخدم في المرتبة الأولى
  Future<bool> makeRankOne({required MyAdModel ad}) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _error = 'Authentication token not found. Please login again.';
        safeNotifyListeners();
        return false;
      }

      // تطبيع اسم الفئة ليتوافق مع قيم الباك إند المطلوبة
      String _normalizeCategory(String category, String slug) {
        final c = category.toLowerCase().trim();
        final s = slug.toLowerCase().trim();
        if (c.contains('car') && c.contains('rent')) return 'Car Rent';
        if (c.contains('car') && (c.contains('sale') || c.contains('sales'))) return 'Cars Sales';
        if (c.contains('car') && c.contains('service')) return 'Car Services';
        if (c.contains('electronics') || s.contains('electronic')) return 'Electronics';
        if (c.contains('other') && c.contains('service')) return 'Other Services';
        if (c.contains('restaurant') || s.contains('restaurant')) return 'restaurant';
        if (c.contains('job') || c.contains('jop') || s.contains('job')) return 'Jop';
        if (c.contains('real') && (c.contains('estate') || c.contains('state') || s.contains('real'))) return 'Real State';
        return category; // افتراضيًا أرسل القيمة كما هي
      }

      final normalizedCategory = _normalizeCategory(ad.category, ad.categorySlug);

      await _myAdsRepository.makeRankOne(
        token: token,
        category: normalizedCategory,
        adId: ad.id,
      );

      // إعادة تحميل قائمة الإعلانات لتحديث الحالة بعد النجاح
      await fetchMyAds();
      return true;
    } catch (e) {
      _error = e.toString();
      safeNotifyListeners();
      return false;
    }
  }
}