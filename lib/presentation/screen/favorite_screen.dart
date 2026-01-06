import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/favorites_response_model.dart';
import 'package:advertising_app/data/repository/favorites_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/repository/jobs_repository.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/user_ads_model.dart';
import 'package:advertising_app/data/model/user_ad_adapters.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:advertising_app/presentation/widget/custom_search2_card.dart';
import 'package:advertising_app/presentation/widget/custome_search_job.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int selectedCategory = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final FavoritesRepository _favoritesRepository;
  late final JobsRepository _jobsRepository;
  Map<String, String> _jobCategoryImages = {};

  // قائمة تحتوي على بيانات كل التصنيفات من API
  List<List<FavoriteItemInterface>> allData = [];
  bool isLoading = true;
  String? errorMessage;
  bool isUnauthenticated = false;

  @override
  void initState() {
    super.initState();
    _favoritesRepository = FavoritesRepository(ApiService());
    _jobsRepository = JobsRepository(ApiService());
    _loadFavoritesData();
    _loadJobCategoryImages();
  }

  // Debug: اطبع تفاصيل العنصر (Adapter) والقيم الخام من UserAd عند توفرها (مطابقة لطريقة AllAddScreen)
  void _debugPrintAdapter(String categoryKey, FavoriteItemInterface item) {
    try {
      final dynamic idDyn = item.id;
      final idStr = idDyn != null ? idDyn.toString() : 'null';
      final imgs = item.images;
      debugPrint('----- Ad Debug [$categoryKey] -----');
      debugPrint(
          'id=$idStr title="${item.title}" price="${item.price}" location="${item.location}"');
      debugPrint(
          'date="${item.date}" contact="${item.contact}" premium=${item.isPremium}');
      debugPrint(
          'category="${item.category}" addCategory="${item.addCategory}"');
      debugPrint('line1="${item.line1}" details="${item.details}"');
      debugPrint(
          'imagesCount=${imgs.length} firstImage="${imgs.isNotEmpty ? imgs.first : 'none'}"');

      // محول أساسي للوصول إلى UserAd الخام إذا كان العنصر ملفوف داخل FavoriteAdapterItem
      final base = (item is FavoriteAdapterItem) ? item.adapted : item;

      if (base is CarSalesAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'CarSales raw -> make="${ad.make}" model="${ad.model}" trim="${ad.trim}" year="${ad.year}"');
        debugPrint(
            'CarSales raw -> km="${ad.km}" specs="${ad.specs}" price="${ad.price}"');
        debugPrint(
            'CarSales raw -> emirate="${ad.emirate}" area="${ad.area}" planType="${ad.planType}"');
      } else if (base is CarRentAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'CarRent raw -> make="${ad.make}" model="${ad.model}" year="${ad.year}"');
        debugPrint(
            'CarRent raw -> dayRent="${ad.dayRent}" monthRent="${ad.monthRent}" price="${ad.price}"');
        debugPrint(
            'CarRent raw -> location="${ad.location}" planType="${ad.planType}"');
      } else if (base is CarServiceAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'CarService raw -> serviceType="${ad.serviceType}" serviceName="${ad.serviceName}"');
        debugPrint(
            'CarService raw -> title="${ad.title}" price="${ad.price}" location="${ad.location}"');
      } else if (base is RealEstateAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'RealEstate raw -> property_type="${ad.property_type}" contract_type="${ad.contract_type}"');
        debugPrint(
            'RealEstate raw -> emirate="${ad.emirate}" district="${ad.district}" area="${ad.area}"');
        debugPrint('RealEstate raw -> price="${ad.price}" title="${ad.title}"');
      } else if (base is ElectronicsAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'Electronics raw -> product_name="${ad.product_name}" section_type="${ad.section_type}"');
        debugPrint(
            'Electronics raw -> emirate="${ad.emirate}" district="${ad.district}" area="${ad.area}"');
        debugPrint(
            'Electronics raw -> price="${ad.price}" title="${ad.title}"');
      } else if (base is JobAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'Jobs raw -> job_name="${ad.job_name}" salary="${ad.salary}"');
        debugPrint(
            'Jobs raw -> contract_type="${ad.contract_type}" section_type="${ad.section_type}"');
        debugPrint(
            'Jobs raw -> location="${ad.emirate} ${ad.district} ${ad.area}"');
      } else if (base is RestaurantAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'Restaurant raw -> title="${ad.title}" category="${ad.category}"');
        debugPrint(
            'Restaurant raw -> price="${ad.price}" location="${ad.location}"');
      } else if (base is OtherServiceAdAdapter) {
        final ad = base.userAd;
        debugPrint(
            'OtherService raw -> serviceType="${ad.serviceType}" serviceName="${ad.serviceName}"');
        debugPrint(
            'OtherService raw -> title="${ad.title}" price="${ad.price}" location="${ad.location}"');
      }
    } catch (e) {
      debugPrint('Debug print failed: $e');
    }
  }

  // Debug: اطبع كافة عناصر القسم المحدد عند تغييره (مطابقة لطريقة AllAddScreen)
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
    final items = (allData.isNotEmpty && index < allData.length)
        ? allData[index]
        : const <FavoriteItemInterface>[];
    debugPrint(
        '=== Printing ${items.length} items for section "$key" (index=$index) ===');
    for (final item in items) {
      _debugPrintAdapter(key, item);
    }
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

  /// تحميل بيانات المفضلة من API
  Future<void> _loadFavoritesData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        isUnauthenticated = false;
      });

      // الحصول على user ID من AuthProvider
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      // التحقق من وجود user ID
      if (userId == null) {
        setState(() {
          isLoading = false;
          isUnauthenticated = true;
        });
        return;
      }

      // استدعاء API للحصول على المفضلة باستخدام user ID للمستخدمين المسجلين فقط
      final favoritesResponse =
          await _favoritesRepository.getFavorites(userId: userId);

      // طباعة تشخيصية لفهم البيانات المرجعة
      debugPrint('🔍 Favorites Response Status: ${favoritesResponse.status}');
      debugPrint(
          '🔍 Car Rent items count: ${favoritesResponse.data.carRent.length}');
      debugPrint(
          '🔍 Car Sales items count: ${favoritesResponse.data.carSales.length}');
      debugPrint(
          '🔍 Restaurant items count: ${favoritesResponse.data.restaurant.length}');
      debugPrint(
          '🔍 Electronics items count: ${favoritesResponse.data.electronics.length}');
      debugPrint('🔍 Jobs items count: ${favoritesResponse.data.jobs.length}');
      debugPrint(
          '🔍 Real Estate items count: ${favoritesResponse.data.realEstate.length}');
      debugPrint(
          '🔍 Car Services items count: ${favoritesResponse.data.carServices.length}');
      debugPrint(
          '🔍 Other Services items count: ${favoritesResponse.data.otherServices.length}');

      // استخدام الطريقة المساعدة من FavoritesData للحصول على البيانات مرتبة حسب التصنيفات
      // ثم تحويل كل عنصر FavoriteItem إلى Adapter عبر UserAdAdapterFactory
      final organizedData = favoritesResponse.data.getAllItemsByCategory();
      allData = organizedData.map((categoryList) {
        return categoryList.map<FavoriteItemInterface>((favItem) {
          try {
            final userAd = _convertFavoriteAdToUserAd(favItem.ad);
            final adapter = UserAdAdapterFactory.createAdapter(userAd);
            return FavoriteAdapterItem(
              favoriteId: favItem.favoriteId,
              original: favItem,
              adapted: adapter,
            );
          } catch (e) {
            // في حال فشل التحويل لأي سبب، نُعيد العنصر الأصلي لضمان عدم كسر الشاشة
            debugPrint(
                'Adapter conversion failed for favorite ${favItem.favoriteId}: $e');
            return favItem;
          }
        }).toList();
      }).toList();

      // تخزين معرفات الإعلانات المفضلة محليًا لضمان لون أيقونة القلب (أحمر) في الكروت
      await _cacheFavoriteIdsForHearts();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        // تحسين رسالة الخطأ بناءً على نوع الخطأ
        if (e.toString().contains('Unauthenticated') ||
            e.toString().contains('401')) {
          errorMessage = null; // لا نعرض رسالة خطأ، بل رسالة ودية
          isUnauthenticated = true;
        } else {
          errorMessage = S.of(context)!.favoritesLoadFailed(e.toString());
          isUnauthenticated = false;
        }
      });
      debugPrint('Error loading favorites: $e');
    }
  }

  /// حفظ معرفات الإعلانات المفضلة في التخزين لعرض القلب باللون الأحمر داخل كروت البحث
  Future<void> _cacheFavoriteIdsForHearts() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      if (userId == null) return;

      final ids = <int>[];
      for (final categoryList in allData) {
        for (final item in categoryList) {
          if (item is FavoriteAdapterItem) {
            ids.add(item.original.ad.id);
          } else if (item is FavoriteItem) {
            ids.add(item.ad.id);
          } else {
            // محاولة استخراج المعرّف من واجهة العنصر
            final parsed = int.tryParse(item.id.toString());
            if (parsed != null) ids.add(parsed);
          }
        }
      }
      final idsString = ids.join(',');
      await _storage.write(key: 'favorite_ids_$userId', value: idsString);
    } catch (e) {
      debugPrint('Failed to cache favorite IDs: $e');
    }
  }

  /// حذف عنصر من المفضلة
  Future<void> _removeFromFavorites(
      int favoriteId, int categoryIndex, int itemIndex) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await _favoritesRepository.removeFromFavorites(
        favoriteId: favoriteId,
        token: token,
      );

      // إزالة العنصر من القائمة المحلية
      setState(() {
        allData[categoryIndex].removeAt(itemIndex);
      });

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)!.favoriteRemovedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)!.favoriteRemoveFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    // قائمة التصنيفات النصية
    final List<String> categories = [
      S.of(context)!.carsales, // index 0
      S.of(context)!.realestate, // index 1
      S.of(context)!.electronics, // index 2
      S.of(context)!.jobs, // index 3
      S.of(context)!.carrent, // index 4
      S.of(context)!.carservices, // index 5
      S.of(context)!.restaurants, // index 6
      S.of(context)!.otherservices // index 7
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(height: 60),
            Text(
              S.of(context)!.favorites,
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
                  // Debug: عند تغيير القسم، اطبع عناصر القسم المحدد كما في AllAddScreen
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
              onPressed: _loadFavoritesData,
              child: Text(S.of(context)!.retry),
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

    // إذا كان المستخدم غير مصادق عليه أو ضيف، عرض رسالة تسجيل الدخول
    if (isUnauthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              S.of(context)!.loginRequiredTitle,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              S.of(context)!.loginRequiredDescription,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.login_outlined,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push("/login"),
                    child: Text(
                      S.of(context)!.loginAction,
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // إذا كانت القائمة فارغة (ولكن المستخدم مصادق عليه)، عرض الرسالة العربية العادية
    if (selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              S.of(context)!.favoritesEmptySection,
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
    // دالة موحّدة للحذف مع خيار تأكيد قبل التنفيذ
    Future<void> _doDelete({required bool askConfirm}) async {
      if (askConfirm) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(
                S.of(context)!.removeFromFavoritesTitle,
                style: TextStyle(
                    color: Color(0xFF001E5B),
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              content: Text(
                S.of(context)!.removeFromFavoritesMessage,
                style: TextStyle(color: Color(0xFF001E5B), fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(S.of(context)!.cancel),
                  style:
                      TextButton.styleFrom(foregroundColor: Color(0xFF001E5B)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(1, 84, 126, 1),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(S.of(context)!.remove,
                      style: TextStyle(
                        color: Colors.white,
                      )),
                ),
              ],
            );
          },
        );
        if (confirmed != true) return;
      }

      // الحصول على معرّف المستخدم
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context)!.pleaseLoginFirst)),
          );
        }
        return;
      }

      // استخراج معرّف الإعلان والفئة
      int? adId;
      String? rawCategory;
      if (item is FavoriteAdapterItem) {
        adId = item.original.ad.id;
        rawCategory = item.original.ad.addCategory;
      } else if (item is FavoriteItem) {
        adId = item.ad.id;
        rawCategory = item.ad.addCategory;
      } else {
        adId = int.tryParse(item.id.toString());
        rawCategory = item.addCategory;
      }

      if (adId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context)!.adIdNotAvailable)),
          );
        }
        return;
      }

      final categorySlug = _originalFavoriteSlugForDelete(
          rawCategory, item.category, item.addCategory);
      final token = await _storage.read(key: 'auth_token');

      // تنفيذ الحذف من الخادم لكلا المسارين: سلة المهملات (مع تأكيد) والقلب (بدون تأكيد داخلي)
      try {
        await _favoritesRepository.removeFromFavoritesByUser(
          userId: userId,
          adId: adId,
          categorySlug: categorySlug,
          token: token,
        );

        setState(() {
          allData[selectedCategory].removeAt(index);
        });

        await _cacheFavoriteIdsForHearts();
        await _loadFavoritesData(); // تحديث الصفحة بالكامل بعد الحذف

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context)!.favoriteRemovedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // في حال رجع الخادم 404 أو "Favorite not found"، نعتبره نجاحًا محليًا ونزيل العنصر
        final msg = e.toString().toLowerCase();
        final isNotFoundLike = msg.contains('favorite not found') ||
            (msg.contains('api endpoint not found') && msg.contains('/api/favorites/')) ||
            msg.contains('404');
        if (isNotFoundLike) {
          setState(() {
            allData[selectedCategory].removeAt(index);
          });
          await _cacheFavoriteIdsForHearts();
          // يمكن تخطي إعادة التحميل الكامل لتسريع التجربة، لكن نُبقيها لضمان التزامن
          await _loadFavoritesData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context)!.favoriteRemovedSuccess),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context)!.favoriteRemoveFailed(e.toString())),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    // مساران: قلب المفضلة (بدون تأكيد داخلي لأن القلب نفسه يعرض التأكيد) وأيقونة الحذف (مع تأكيد)
    VoidCallback onDeleteNoConfirm = () {
      _doDelete(askConfirm: false);
    };
    VoidCallback onDeleteConfirm = () {
      _doDelete(askConfirm: true);
    };

    // ويدجت مخصص لأيقونة الحذف بجانب سطر الموقع
    final Widget deleteTrailing = SizedBox(
      width: 44.w,
      height: 44.h,
      child: IconButton(
        onPressed: onDeleteConfirm,
        icon: SvgPicture.asset(
          'assets/icons/deleted.svg',
          width: 23.w,
          height: 28.h,
        ),
      ),
    );

    switch (selectedCategory) {
      case 0: // carsales
        return SearchCard(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true, // تفعيل الحذف عبر أيقونة القلب بنفس الحوار
          showLine1: true,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
      case 4: // carrent
        // مطابقة طريقة عرض Day/Month Rent كما في AllAddScreen
        TextSpan? line1Span;
        try {
          String? dayRent;
          String? monthRent;
          if (item is CarRentAdAdapter) {
            dayRent = item.userAd.dayRent;
            monthRent = item.userAd.monthRent;
          } else if (item is FavoriteAdapterItem &&
              item.adapted is CarRentAdAdapter) {
            final adapted = (item.adapted as CarRentAdAdapter);
            dayRent = adapted.userAd.dayRent;
            monthRent = adapted.userAd.monthRent;
          }
          line1Span = TextSpan(children: [
            WidgetSpan(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLabelWithValue(S.of(context)!.dayRent, dayRent),
                  const SizedBox(width: 16),
                  _buildLabelWithValue(S.of(context)!.monthRent, monthRent),
                ],
              ),
            ),
          ]);
        } catch (_) {}

        return SearchCard(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customLine1Span: line1Span,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
      case 5: // carservices
        return SearchCard(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
      case 1: // realestate
        return SearchCard(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
      case 2: // electronics
        return SearchCard2(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
      case 3: // jobs
        // تطبيق نفس تخصيص الصورة والسطر السفلي كما في AllAddScreen
        String? customImageUrl;
        Widget? bottomWidget;

        try {
          String? categoryType;
          String? contactInfo;
          if (item is JobAdAdapter) {
            categoryType = item.userAd.category_type;
            contactInfo = item.userAd.contactInfo;
          } else if (item is FavoriteAdapterItem &&
              item.adapted is JobAdAdapter) {
            categoryType = (item.adapted as JobAdAdapter).userAd.category_type;
            contactInfo = (item.adapted as JobAdAdapter).userAd.contactInfo;
          }

          final isOffer = (categoryType ?? '').toLowerCase().contains('offer');
          final key = isOffer ? 'job_offer' : 'job_seeker';
          final imagePath = _jobCategoryImages[key];
          if (imagePath != null && imagePath.isNotEmpty) {
            final url = ImageUrlHelper.getFullImageUrl(imagePath);
            if (url.isNotEmpty) customImageUrl = url;
          }

          // عرض contact_info كنصّ خام تحت اسم المعلن تمامًا كما في AllAddScreen
          if (contactInfo != null && contactInfo.trim().isNotEmpty && contactInfo.toLowerCase() != 'null') {
            bottomWidget = Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                "Contact : ${contactInfo}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF001E5B),
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
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customActionButtons: const [], // نخفي أزرار الاتصال في الوظائف
          customLocationTrailing: deleteTrailing,
          customImageUrl: customImageUrl,
          customBottomWidget: bottomWidget,
        );
      case 6: // restaurants
        return SearchCard(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
      case 7: // other services
        return SearchCard(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
      default:
        return SearchCard(
          item: item,
          onDelete: onDeleteNoConfirm,
          showDelete: true,
          showLine1: true,
          customActionButtons: _buildActionButtons(item),
          customLocationTrailing: deleteTrailing,
        );
    }
  }

  // مطابقة لطريقة العرض في AllAddScreen
  Widget _buildLabelWithValue(String label, String? value) {
    final isNullOrEmpty =
        value == null || value.isEmpty || value.toLowerCase() == 'null';
    final displayValue =
        isNullOrEmpty ? "$label: null" : value.split('.').first;

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
              color: isNullOrEmpty
                  ? Colors.grey
                  : const Color.fromRGBO(0, 30, 90, 1),
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

  String _getWhatsAppNumber(FavoriteItemInterface item) {
    try {
      if (item is FavoriteAdapterItem) {
        return item.original.ad.whatsappNumber;
      } else if (item is FavoriteItem) {
        return item.ad.whatsappNumber;
      }
    } catch (_) {}
    return '';
  }

  String _getPhoneNumber(FavoriteItemInterface item) {
    try {
      if (item is FavoriteAdapterItem) {
        return item.original.ad.phoneNumber;
      } else if (item is FavoriteItem) {
        return item.ad.phoneNumber;
      }
    } catch (_) {}
    return '';
  }

  // بناء نص معلومات التواصل للوظائف لعرضه كسطر سفلي
  String _getJobContactInfo(FavoriteItemInterface item) {
    final whatsapp = _getWhatsAppNumber(item).trim();
    final phone = _getPhoneNumber(item).trim();
    final parts = <String>[];
    if (whatsapp.isNotEmpty && whatsapp.toLowerCase() != 'null' && whatsapp.toLowerCase() != 'nullnow') {
      parts.add(S.of(context)!.whatsappLabel(whatsapp));
    }
    if (phone.isNotEmpty && phone.toLowerCase() != 'null' && phone.toLowerCase() != 'nullnow') {
      parts.add(S.of(context)!.phoneLabel(phone));
    }
    return parts.join(' | ');
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context)!.couldNotLaunch(urlString))),
        );
      }
    }
  }

  Widget _buildWhatsAppButton(FavoriteItemInterface item) {
    return Container(
      width: 62.w,
      height: 35.h,
      decoration: BoxDecoration(
          color: const Color(0xFF01547E),
          borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        onPressed: () {
          final whatsapp = _getWhatsAppNumber(item).trim();
          if (whatsapp.isNotEmpty &&
              whatsapp != 'null' &&
              whatsapp != 'nullnow') {
            try {
              final url = PhoneNumberFormatter.getWhatsAppUrl(whatsapp);
              _launchUrl(url);
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context)!.whatsappInvalid)),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context)!.whatsappNotAvailable)),
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
      decoration: BoxDecoration(
          color: const Color(0xFF01547E),
          borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        onPressed: () {
          final phone = _getPhoneNumber(item).trim();
          if (phone.isNotEmpty && phone != 'null' && phone != 'nullnow') {
            try {
              final url = PhoneNumberFormatter.getTelUrl(phone);
              _launchUrl(url);
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context)!.phoneInvalid)),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context)!.phoneNotAvailable)),
            );
          }
        },
        icon: const Icon(
          Icons.call,
          color: Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// توحيد الـ slug المطلوب لواجهة حذف المفضلة (DELETE) لضمان التوافق
String _normalizeFavoriteApiSlug(String category) {
  final c = category.toLowerCase().trim().replaceAll('-', '_');
  switch (c) {
    case 'car_services':
    case 'car service':
    case 'carservices':
    case 'car_service':
      return 'car_services';
    case 'restaurants':
    case 'restaurant':
      return 'restaurant';
    case 'real estate':
    case 'real_state':
    case 'realestate':
      return 'real_estate';
    case 'car rent':
    case 'carrent':
      return 'car_rent';
    case 'car sales':
    case 'cars sales':
    case 'carsales':
    case 'cars':
      return 'car_sales';
    case 'electronics':
      return 'electronics';
    case 'jobs':
    case 'job':
    case 'jop':
      return 'jobs';
    case 'other services':
    case 'otherservices':
    case 'other_service':
      return 'other_services';
    default:
      return c.replaceAll(' ', '_');
  }
}

/// إرجاع الـ slug الأصلي كما يخزنه السيرفر في المفضلة (صيغة العرض)
/// الهدف: تجنب 404 بسبب اختلاف الصيغة بين "Cars Sales" و "car_sales".
String _originalFavoriteSlugForDelete(
    String? rawCategory, String category, String addCategory) {
  final raw = (rawCategory ?? '').trim();
  if (raw.isNotEmpty) return raw; // استخدم القيمة الأصلية القادمة من API

  // إذا لم تكن متوفرة، اعتمد على الفئة الموجودة مع تحويل إلى صيغة العرض المتوقعة من السيرفر
  final c = (addCategory.isNotEmpty ? addCategory : category)
      .toLowerCase()
      .trim()
      .replaceAll('-', '_');
  switch (c) {
    case 'car_sales':
    case 'carsales':
    case 'cars':
    case 'car sales':
    case 'cars sales':
      return 'Cars Sales';
    case 'car_services':
    case 'car service':
    case 'carservices':
    case 'car_service':
      return 'Car Services';
    case 'real_estate':
    case 'real state':
    case 'realestate':
      return 'Real Estate';
    case 'car_rent':
    case 'car rent':
    case 'carrent':
      return 'Car Rent';
    case 'electronics':
      return 'Electronics';
    case 'jobs':
    case 'job':
    case 'jop':
      return 'Jobs';
    case 'other_services':
    case 'otherservices':
    case 'other service':
      return 'Other Services';
    case 'restaurant':
    case 'restaurants':
      return 'Restaurants';
    default:
      // افتراضي: حوّل الشرطات السفلية إلى مسافات وكبّر الحروف الأولى
      final spaced = c.replaceAll('_', ' ').trim();
      if (spaced.isEmpty) return 'Other Services';
      return spaced
          .split(' ')
          .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
          .join(' ');
  }
}

/// عنصر مغلّف يدمج بيانات المفضلة الأصلية مع العنصر المحوّل عبر الـ Adapter
class FavoriteAdapterItem implements FavoriteItemInterface {
  final int favoriteId;
  final FavoriteItem original;
  final FavoriteItemInterface adapted;

  FavoriteAdapterItem({
    required this.favoriteId,
    required this.original,
    required this.adapted,
  });

  // تفويض خصائص الواجهة إلى العنصر المحوّل لعرض القيم الموحّدة
  @override
  String get title => adapted.title;
  @override
  String get location => adapted.location;
  @override
  String get price => adapted.price;
  @override
  String get line1 => adapted.line1;
  @override
  String get details => adapted.details;
  @override
  String get date => adapted.date;
  @override
  String get contact => adapted.contact;
  @override
  bool get isPremium => adapted.isPremium;
  @override
  List<String> get images => adapted.images;
  @override
  AdPriority get priority => adapted.priority;
  @override
  dynamic get id => adapted.id;
  @override
  String get category => adapted.category;
  @override
  String get addCategory => adapted.addCategory;
}

/// تحويل بيانات المفضلة AdData إلى UserAd لاستخدامها مع الـ Adapter Factory
UserAd _convertFavoriteAdToUserAd(AdData ad) {
  final normalizedCategory = _normalizeCategory(ad.addCategory);
  final map = <String, dynamic>{
    'id': ad.id,
    'user_id': ad.userId,
    'title': ad.title,
    'description': ad.description,
    'emirate': ad.emirate,
    'district': ad.district,
    'area': ad.area,
    'price': ad.price?.toString() ?? '',
    'price_range': ad.priceRange,
    'category': ad.category?.toString() ?? normalizedCategory,
    'main_image': ad.mainImage,
    'thumbnail_images': ad.thumbnailImages,
    'advertiser_name': ad.advertiserName,
    'whatsapp_number': ad.whatsappNumber,
    'phone_number': ad.phoneNumber,
    'contact_info': _composeContactInfoFromAd(ad),
    'address': ad.address,
    'add_category': normalizedCategory,
    'add_status': ad.addStatus,
    'admin_approved': ad.adminApproved,
    'views': ad.views,
    'rank': ad.rank,
    'plan_type': ad.planType,
    'plan_days': ad.planDays,
    'plan_expires_at': ad.planExpiresAt,
    'active_offers_box_status': ad.activeOffersBoxStatus,
    'active_offers_box_days': ad.activeOffersBoxDays,
    'active_offers_box_expires_at': ad.activeOffersBoxExpiresAt,
    'created_at': ad.createdAt,
    'latitude': ad.latitude,
    'longitude': ad.longitude,
    'main_image_url': ad.mainImageUrl,
    'thumbnail_images_urls': ad.thumbnailImagesUrls,
    'status': ad.status,
    'section': ad.section,
    // خصائص إضافية محتملة لبعض الفئات، نمررها إن وجدت
    'service_type': ad.serviceType,
    'service_name': ad.serviceName,
    'location': ad.location ?? '${ad.emirate} ${ad.district} ${ad.area}'.trim(),
    // مفاتيح إضافية لسيارات (إن وُجدت في استجابة المفضلة)
    'km': ad.km ?? '',
    'specs': ad.specs ?? '',
    'make': ad.make,
    'model': ad.model,
    'trim': ad.trim,
    'year': ad.year,
    'car_type': ad.carType,
    'trans_type': ad.transType,
    'fuel_type': ad.fuelType,
    'color': ad.color,
    'interior_color': ad.interiorColor,
    'seats_no': ad.seatsNo,
    // مفاتيح أخرى عامة أو غير مستخدمة هنا
    'category_type': ad.categoryType,
    'section_type': ad.sectionType,
    'product_name': ad.productName,
    'contract_type': ad.contractType,
    'property_type': ad.propertyType,
    'job_name': ad.jobName,
    'salary': ad.salary,
    'day_rent': ad.dayRent,
    'month_rent': ad.monthRent,
    'active_offers_box_rank': null,
  };
  return UserAd.fromJson(map);
}

/// تركيب نص معلومات التواصل مباشرةً من بيانات المفضلة
String _composeContactInfoFromAd(AdData ad) {
  final whatsapp = (ad.whatsappNumber ?? '').trim();
  final phone = (ad.phoneNumber ?? '').trim();
  final parts = <String>[];
  if (whatsapp.isNotEmpty && whatsapp.toLowerCase() != 'null' && whatsapp.toLowerCase() != 'nullnow') {
    parts.add('WhatsApp: $whatsapp');
  }
  if (phone.isNotEmpty && phone.toLowerCase() != 'null' && phone.toLowerCase() != 'nullnow') {
    parts.add('Phone: $phone');
  }
  return parts.join(' | ');
}

/// توحيد أسماء الفئات لتتوافق مع الـ Adapter Factory
String _normalizeCategory(String category) {
  final c = category.toLowerCase().trim();
  switch (c) {
    case 'carsales':
    case 'car sales':
    case 'cars sales':
    case 'cars':
      return 'car_sales';
    case 'real state':
    case 'real estate':
    case 'realestate':
      return 'real_estate';
    case 'electronics':
      return 'electronics';
    case 'jobs':
    case 'job':
    case 'jop':
      return 'jobs';
    case 'car rent':
    case 'carrent':
      return 'car_rent';
    case 'car services':
    case 'carservices':
    case 'car service':
      return 'car_service';
    case 'restaurant':
    case 'restaurants':
      return 'restaurants';
    case 'other services':
    case 'otherservices':
      return 'other_services';
    default:
      return c;
  }
}
