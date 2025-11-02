import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/user_ad_adapters.dart';
import 'package:advertising_app/data/model/user_ads_model.dart';
import 'package:advertising_app/data/repository/user_ads_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/repository/jobs_repository.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/screen/all_ad_adapter.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:advertising_app/presentation/widget/custom_search2_card.dart';
import 'package:advertising_app/presentation/widget/custome_search_job.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);

class AllAddScreen extends StatefulWidget {
  final String? advertiserId;

  const AllAddScreen({super.key, this.advertiserId});

  @override
  State<AllAddScreen> createState() => _AllAddScreenState();
}

class _AllAddScreenState extends State<AllAddScreen> {
  int selectedCategory = 0;
  bool isLoading = true;
  String? errorMessage;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final UserAdsRepository _userAdsRepository;
  late final JobsRepository _jobsRepository;
  Map<String, String> _jobCategoryImages = {};

  // قوائم البيانات لكل تصنيف
  final List<List<FavoriteItemInterface>> allData = [
    [], // car sales - index 0
    [], // real estate - index 1
    [], // electronics - index 2
    [], // jobs - index 3
    [], // car rent - index 4
    [], // car services - index 5
    [], // restaurants - index 6
    [], // other services - index 7
  ];

  @override
  void initState() {
    super.initState();
    _userAdsRepository = UserAdsRepository(ApiService());
    _jobsRepository = JobsRepository(ApiService());
    _loadJobCategoryImages();
    _loadUserAdsData();
  }

  Future<void> _loadJobCategoryImages() async {
    try {
      final images = await _jobsRepository.getJobCategoryImages();
      if (mounted) {
        setState(() {
          _jobCategoryImages = images;
        });
      }
    } catch (e) {
      debugPrint('Failed to load job category images: $e');
    }
  }

  Future<void> _loadUserAdsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // الحصول على معرف المستخدم المعلن
      final advertiserId = await _getAdvertiserId();
      if (advertiserId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'لم يتم العثور على معرف المستخدم';
        });
        return;
      }

      // طباعة الـ endpoint مع الـ userId الفعلي في الترمنال
      debugPrint('Endpoint used: /api/user-ads/$advertiserId');

      // جلب إعلانات المستخدم من API
      final userAdsResponse = await _userAdsRepository.getUserAds(advertiserId);

      // تصنيف الإعلانات حسب الفئات
      final categorizedAds = _categorizeAds(userAdsResponse.ads);

      setState(() {
        allData[0] = categorizedAds['car_sales'] ?? [];
        allData[1] = categorizedAds['real_estate'] ?? [];
        allData[2] = categorizedAds['electronics'] ?? [];
        allData[3] = categorizedAds['jobs'] ?? [];
        allData[4] = categorizedAds['car_rent'] ?? [];
        allData[5] = categorizedAds['car_services'] ?? [];
        allData[6] = categorizedAds['restaurant'] ?? [];
        allData[7] = categorizedAds['other_services'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'حدث خطأ أثناء تحميل البيانات: ${e.toString()}';
      });
      debugPrint('Error loading user ads: $e');
    }
  }

  Future<String?> _getAdvertiserId() async {
    // استخدام معرف المعلن من widget parameter إذا كان متاحًا
    if (widget.advertiserId != null) {
      // التحقق من أن معرف المعلن ليس '0' قبل استخدامه
      if (widget.advertiserId != '0') {
        debugPrint(
            'Using valid advertiser ID from widget parameter: ${widget.advertiserId}');
        return widget.advertiserId;
      } else {
        debugPrint('Received invalid advertiser ID (0) from widget parameter');
        // في حالة استلام معرف '0'، نستخدم معرف المستخدم من التخزين
      }
    }

    // استخدام معرف المستخدم من الـ storage كخيار أخير
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null && userId.isNotEmpty) {
        debugPrint('Using user ID from storage: $userId');
        return userId;
      }
    } catch (e) {
      debugPrint('Error getting user ID from storage: $e');
    }

    // إذا لم يتم العثور على معرف المستخدم، استخدم قيمة افتراضية
    debugPrint('Warning: No user ID found in storage, using fallback value');
    return '0';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkRouteParameters();
  }

  void _checkRouteParameters() {
    try {
      // استخدام معرف المعلن من الـ route parameter
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      if (routeArgs is String && routeArgs.isNotEmpty) {
        debugPrint('Using advertiser ID from route arguments: $routeArgs');
        // إعادة تحميل البيانات باستخدام معرف المعلن من الـ route
        _loadUserAdsData();
      }
    } catch (e) {
      debugPrint('Error checking route parameters: $e');
    }
  }

  // Debug: اطبع تفاصيل العنصر (Adapter) والقيم الخام من UserAd عند توفرها
  void _debugPrintAdapter(String categoryKey, FavoriteItemInterface item) {
    try {
      final dynamic idDyn = item.id;
      final idStr = idDyn != null ? idDyn.toString() : 'null';
      final imgs = item.images;
      debugPrint('----- Ad Debug [$categoryKey] -----');
      debugPrint('id=$idStr title="${item.title}" price="${item.price}" location="${item.location}"');
      debugPrint('date="${item.date}" contact="${item.contact}" premium=${item.isPremium}');
      debugPrint('category="${item.category}" addCategory="${item.addCategory}"');
      debugPrint('line1="${item.line1}" details="${item.details}"');
      debugPrint('imagesCount=${imgs.length} firstImage="${imgs.isNotEmpty ? imgs.first : 'none'}"');

      // طباعة خصائص مخصصة حسب نوع الـ Adapter للوصول إلى قيم UserAd الخام
      if (item is CarSalesAdAdapter) {
        final ad = item.userAd;
        debugPrint('CarSales raw -> make="${ad.make}" model="${ad.model}" trim="${ad.trim}" year="${ad.year}"');
        debugPrint('CarSales raw -> km="${ad.km}" specs="${ad.specs}" price="${ad.price}"');
        debugPrint('CarSales raw -> emirate="${ad.emirate}" area="${ad.area}" planType="${ad.planType}"');
      } else if (item is CarRentAdAdapter) {
        final ad = item.userAd;
        debugPrint('CarRent raw -> make="${ad.make}" model="${ad.model}" year="${ad.year}"');
        debugPrint('CarRent raw -> dayRent="${ad.dayRent}" monthRent="${ad.monthRent}" price="${ad.price}"');
        debugPrint('CarRent raw -> location="${ad.location}" planType="${ad.planType}"');
      } else if (item is CarServiceAdAdapter) {
        final ad = item.userAd;
        debugPrint('CarService raw -> serviceType="${ad.serviceType}" serviceName="${ad.serviceName}"');
        debugPrint('CarService raw -> title="${ad.title}" price="${ad.price}" location="${ad.location}"');
      } else if (item is RealEstateAdAdapter) {
        final ad = item.userAd;
        debugPrint('RealEstate raw -> property_type="${ad.property_type}" contract_type="${ad.contract_type}"');
        debugPrint('RealEstate raw -> emirate="${ad.emirate}" district="${ad.district}" area="${ad.area}"');
        debugPrint('RealEstate raw -> price="${ad.price}" title="${ad.title}"');
      } else if (item is ElectronicsAdAdapter) {
        final ad = item.userAd;
        debugPrint('Electronics raw -> product_name="${ad.product_name}" section_type="${ad.section_type}"');
        debugPrint('Electronics raw -> emirate="${ad.emirate}" district="${ad.district}" area="${ad.area}"');
        debugPrint('Electronics raw -> price="${ad.price}" title="${ad.title}"');
      } else if (item is JobAdAdapter) {
        final ad = item.userAd;
        debugPrint('Jobs raw -> job_name="${ad.job_name}" salary="${ad.salary}"');
        debugPrint('Jobs raw -> contract_type="${ad.contract_type}" section_type="${ad.section_type}"');
        debugPrint('Jobs raw -> location="${ad.emirate} ${ad.district} ${ad.area}"');
      } else if (item is RestaurantAdAdapter) {
        final ad = item.userAd;
        debugPrint('Restaurant raw -> title="${ad.title}" category="${ad.category}"');
        debugPrint('Restaurant raw -> price="${ad.price}" location="${ad.location}"');
      } else if (item is OtherServiceAdAdapter) {
        final ad = item.userAd;
        debugPrint('OtherService raw -> serviceType="${ad.serviceType}" serviceName="${ad.serviceName}"');
        debugPrint('OtherService raw -> title="${ad.title}" price="${ad.price}" location="${ad.location}"');
      }
    } catch (e) {
      debugPrint('Debug print failed: $e');
    }
  }

  // Debug: اطبع كافة عناصر القسم المحدد عند تغييره
  void _logSelectedCategoryItems(int index) {
    final keys = [
      'car_sales',
      'real_estate',
      'electronics',
      'jobs',
      'car_rent',
      'car_services',
      'restaurant',
      'other_services',
    ];
    final key = (index >= 0 && index < keys.length) ? keys[index] : 'unknown';
    final items = (allData.isNotEmpty && index < allData.length) ? allData[index] : const <FavoriteItemInterface>[];
    debugPrint('=== Printing ${items.length} items for section "$key" (index=$index) ===');
    for (final item in items) {
      _debugPrintAdapter(key, item);
    }
  }

  Map<String, List<FavoriteItemInterface>> _categorizeAds(List<UserAd> ads) {
    final Map<String, List<FavoriteItemInterface>> categorizedAds = {
      'car_sales': [],
      'real_estate': [],
      'electronics': [],
      'jobs': [],
      'car_rent': [],
      'car_services': [],
      'restaurant': [],
      'other_services': [],
    };

    for (final ad in ads) {
      final category = ad.addCategory.toLowerCase();
      // طباعة القيمة الفعلية للفئة للتشخيص
      debugPrint(
          'Processing ad category: "$category" - Raw value: "${ad.addCategory}"');

      // استخدام المحولات المخصصة لكل فئة
      FavoriteItemInterface adapter;

      // تحسين التعرف على فئة السيارات
      if (category.contains('car') &&
          (category.contains('sale') || category.contains('sales'))) {
        adapter = CarSalesAdAdapter(ad);
        categorizedAds['car_sales']!.add(adapter);
        debugPrint('Added to car_sales with CarSalesAdAdapter');
        _debugPrintAdapter('car_sales', adapter);
      }
      // تحسين التعرف على فئة العقارات
      else if (category.contains('real') ||
          category.contains('estate') ||
          category.contains('property') ||
          category.contains('عقار')) {
        adapter = RealEstateAdAdapter(ad);
        categorizedAds['real_estate']!.add(adapter);
        debugPrint('Added to real_estate with RealEstateAdAdapter');
        _debugPrintAdapter('real_estate', adapter);
      } else if (category.contains('electronic')) {
        adapter = ElectronicsAdAdapter(ad);
        categorizedAds['electronics']!.add(adapter);
        debugPrint('Added to electronics with ElectronicsAdAdapter');
        _debugPrintAdapter('electronics', adapter);
      }
      // تحسين التعرف على فئة الوظائف - إضافة دعم لصيغة "Jop"
      else if (category == 'jobs' ||
          category == 'job' ||
          category == 'jop' ||
          category == 'وظائف' ||
          category == 'وظيفة' ||
          category.contains('job') ||
          category.contains('jop') ||
          category.contains('وظيفة') ||
          category.contains('وظائف') ||
          category.contains('career') ||
          category.contains('employment') ||
          ad.addCategory == 'Jobs' ||
          ad.addCategory == 'JOB' ||
          ad.addCategory == 'JOBS' ||
          ad.addCategory == 'Jop') {
        adapter = JobAdAdapter(ad);
        categorizedAds['jobs']!.add(adapter);
        debugPrint(
            'Added to jobs with JobAdAdapter - Match condition: ${ad.addCategory}');
        _debugPrintAdapter('jobs', adapter);
      } else if ((category.contains('car') || category.contains('auto')) &&
          category.contains('rent')) {
        adapter = CarRentAdAdapter(ad);
        categorizedAds['car_rent']!.add(adapter);
        debugPrint('Added to car_rent with CarRentAdAdapter');
        _debugPrintAdapter('car_rent', adapter);
      } else if ((category.contains('car') || category.contains('auto')) &&
          category.contains('service')) {
        adapter = CarServiceAdAdapter(ad);
        categorizedAds['car_services']!.add(adapter);
        debugPrint('Added to car_services with CarServiceAdAdapter');
        _debugPrintAdapter('car_services', adapter);
      } else if (category.contains('restaurant') || category.contains('food')) {
        adapter = RestaurantAdAdapter(ad);
        categorizedAds['restaurant']!.add(adapter);
        debugPrint('Added to restaurant with RestaurantAdAdapter');
        _debugPrintAdapter('restaurant', adapter);
      } else {
        adapter = OtherServiceAdAdapter(ad);
        categorizedAds['other_services']!.add(adapter);
        debugPrint('Added to other_services with OtherServiceAdAdapter');
        _debugPrintAdapter('other_services', adapter);
      }
    }

    // طباعة عدد الإعلانات في كل فئة للتشخيص
    categorizedAds.forEach((key, value) {
      debugPrint('Category $key has ${value.length} ads');
    });

    return categorizedAds;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    // قائمة التصنيفات النصية
    final List<String> categories = [
      S.of(context).carsales, // index 0
      S.of(context).realestate, // index 1
      S.of(context).electronics, // index 2
      S.of(context).jobs, // index 3
      S.of(context).carrent, // index 4
      S.of(context).carservices, // index 5
      S.of(context).restaurants, // index 6
      S.of(context).otherservices // index 7
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(height: 60),
            Text(
              S.of(context).see_all_ads,
              style: TextStyle(
                color: Color(0xFF001E5B),
                fontWeight: FontWeight.w500,
                fontSize: 24,
              ),
            ),
            SizedBox(height: 10),
            // شريط التصنيفات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: CustomCategoryGrid(
                categories: categories,
                selectedIndex: selectedCategory,
                onTap: (index) {
                  setState(() {
                    selectedCategory = index;
                  });
                  // Debug: عند تغيير القسم، اطبع عناصر القسم المحدد
                  _logSelectedCategoryItems(index);
                },
              ),
            ),
            // محتوى الشاشة الرئيسي
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserAdsData,
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    // اختيار قائمة البيانات الصحيحة بناءً على التصنيف المحدد
    final selectedItems =
        allData.isNotEmpty && selectedCategory < allData.length
            ? allData[selectedCategory]
            : <FavoriteItemInterface>[];

    // إذا كانت القائمة فارغة، عرض رسالة
    if (selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد إعلانات في هذا القسم',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
      itemCount: selectedItems.length,
      cacheExtent: 500.0,
      itemBuilder: (context, index) {
        final item = selectedItems[index];
        return _buildCategorySpecificCard(item, index);
      },
    );
  }

  Widget _buildCategorySpecificCard(FavoriteItemInterface item, int index) {
    switch (selectedCategory) {
      case 0: // car_sales
        return _buildCarSalesCard(item, index);
      case 4: // car_rent
        return _buildCarRentCard(item, index);
      case 5: // car_service
        return _buildCarServiceCard(item, index);
      case 1: // real_estate
        return _buildRealEstateCard(item, index);
      case 2: // electronics
        return _buildElectronicsCard(item, index);
      case 3: // jobs
        return _buildJobCard(item, index);
      case 6: // restaurants
        return _buildRestaurantCard(item, index);
      case 7: // other_services
        return _buildOtherServiceCard(item, index);
      default:
        return _buildGenericCard(item, index);
    }
  }

  Widget _buildCarSalesCard(FavoriteItemInterface item, int index) {
    return SearchCard(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
      customActionButtons: _buildActionButtons(item),
    );
  }

  Widget _buildCarRentCard(FavoriteItemInterface item, int index) {
    // عرض Day/Month Rent بنفس تنسيق car_rent_search_screen.dart#L274-277
    TextSpan? line1Span;
    try {
      String? dayRent;
      String? monthRent;
      if (item is CarRentAdAdapter) {
        dayRent = item.userAd.dayRent;
        monthRent = item.userAd.monthRent;
      }
      line1Span = TextSpan(children: [
        WidgetSpan(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLabelWithValue("Day Rent", dayRent),
              const SizedBox(width: 16),
              _buildLabelWithValue("Month Rent", monthRent),
            ],
          ),
        ),
      ]);
    } catch (_) {}

    return SearchCard(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
      customLine1Span: line1Span,
      customActionButtons: _buildActionButtons(item),
    );
  }

  Widget _buildCarServiceCard(FavoriteItemInterface item, int index) {
    return SearchCard(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
      customActionButtons: _buildActionButtons(item),
    );
  }

  Widget _buildRealEstateCard(FavoriteItemInterface item, int index) {
    return SearchCard(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
      customActionButtons: _buildActionButtons(item),
    );
  }

  Widget _buildElectronicsCard(FavoriteItemInterface item, int index) {
    return SearchCard2(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      customActionButtons: _buildActionButtons(item),
    );
  }

  Widget _buildJobCard(FavoriteItemInterface item, int index) {
    // إخفاء أزرار الاتصال لبطاقات الوظائف، وإضافة سطر contact_info أسفل جهة الاتصال
    // كما نحدد صورة الفئة بناءً على category_type
    String? customImageUrl;
    Widget? bottomWidget;

    try {
      // استخراج نوع الفئة من المحول الخاص بالوظائف
      String? categoryType;
      String? contactInfo;
      if (item is JobAdAdapter) {
        categoryType = item.userAd.category_type;
        contactInfo = item.userAd.contactInfo;
      }

      // تحديد مفتاح الصورة (job_offer أو job_seeker)
      final isOffer = (categoryType ?? '').toLowerCase().contains('offer');
      final key = isOffer ? 'job_offer' : 'job_seeker';
      final imagePath = _jobCategoryImages[key];
      if (imagePath != null && imagePath.isNotEmpty) {
        final url = ImageUrlHelper.getFullImageUrl(imagePath);
        if (url.isNotEmpty) {
          customImageUrl = url;
        }
      }

      // بناء ويدجت معلومات التواصل إذا كانت متوفرة
      if (contactInfo != null && contactInfo.trim().isNotEmpty) {
        bottomWidget = Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            "Contact : ${contactInfo}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              color: KTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Job card customization failed: $e');
    }

    return SearchCardJob(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
      customActionButtons: const [],
      customImageUrl: customImageUrl,
      customBottomWidget: bottomWidget,
    );
  }

  Widget _buildRestaurantCard(FavoriteItemInterface item, int index) {
    return SearchCard(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
      customActionButtons: _buildActionButtons(item),
    );
  }

  Widget _buildOtherServiceCard(FavoriteItemInterface item, int index) {
    return SearchCard(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
      customActionButtons: _buildActionButtons(item),
    );
  }

  Widget _buildGenericCard(FavoriteItemInterface item, int index) {
    return SearchCard(
      item: item,
      onDelete: () {
        setState(() {
          allData[selectedCategory].removeAt(index);
        });
      },
      showDelete: true,
      showLine1: true,
    );
  }

  // مطابقة لطريقة العرض في car_rent_search_screen.dart#L274-277
  Widget _buildLabelWithValue(String label, String? value) {
    final isNullOrEmpty = value == null || value.isEmpty || value.toLowerCase() == 'null';
    final displayValue = isNullOrEmpty ? "$label: null" : value.split('.').first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(0, 30, 90, 1),
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isNullOrEmpty ? Colors.grey : const Color.fromRGBO(0, 30, 90, 1),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(FavoriteItemInterface item) {
    return [
      _buildWhatsAppButton(item),
      SizedBox(width: 4.w),
      _buildCallButton(item),
    ];
  }

  // استخراج رقم الواتساب مباشرةً من بيانات الإعلان (بدون الاعتماد على contact)
  String _getWhatsAppNumber(FavoriteItemInterface item) {
    try {
      if (item is CarSalesAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
      if (item is CarRentAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
      if (item is CarServiceAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
      if (item is RealEstateAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
      if (item is ElectronicsAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
      if (item is JobAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
      if (item is RestaurantAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
      if (item is OtherServiceAdAdapter) {
        return item.userAd.whatsappNumber ?? '';
      }
    } catch (_) {}
    return '';
  }

  // استخراج رقم الهاتف مباشرةً من بيانات الإعلان (بدون الاعتماد على contact)
  String _getPhoneNumber(FavoriteItemInterface item) {
    try {
      if (item is CarSalesAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
      if (item is CarRentAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
      if (item is CarServiceAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
      if (item is RealEstateAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
      if (item is ElectronicsAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
      if (item is JobAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
      if (item is RestaurantAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
      if (item is OtherServiceAdAdapter) {
        return item.userAd.phoneNumber ?? '';
      }
    } catch (_) {}
    return '';
  }

  // دالة موحّدة لفتح الروابط مثل باقي الشاشات
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  Widget _buildWhatsAppButton(FavoriteItemInterface item) {
    return Container(
      width: 62.w,
      height: 35.h,
       decoration: BoxDecoration(color: const Color(0xFF01547E), borderRadius: BorderRadius.circular(8)),
     
      child: IconButton(
        onPressed: () {
          final whatsapp = _getWhatsAppNumber(item).trim();
          if (whatsapp.isNotEmpty && whatsapp != 'null' && whatsapp != 'nullnow') {
            final url = PhoneNumberFormatter.getWhatsAppUrl(whatsapp);
            _launchUrl(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رقم الواتساب غير متوفر')),
            );
          }
        },
        icon: FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.white,
          size: 20.sp,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCallButton(FavoriteItemInterface item) {
    return Container(
      width: 62.w,
      height: 35.h,
       decoration: BoxDecoration(color: const Color(0xFF01547E), borderRadius: BorderRadius.circular(8)),
      
      child: IconButton(
        onPressed: () {
          final phone = _getPhoneNumber(item).trim();
          if (phone.isNotEmpty && phone != 'null' && phone != 'nullnow') {
            final url = PhoneNumberFormatter.getTelUrl(phone);
            _launchUrl(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رقم الهاتف غير متوفر')),
            );
          }
        },
        icon: Icon(
          Icons.call,
          color: Colors.white,
          size: 20.sp,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _launchWhatsApp(String phoneNumber) async {
    try {
      final url = PhoneNumberFormatter.getWhatsAppUrl(phoneNumber);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لا يمكن فتح واتساب على هذا الجهاز")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("صيغة رقم الواتساب غير صالحة")),
      );
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = PhoneNumberFormatter.getTelUrl(phoneNumber);

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
