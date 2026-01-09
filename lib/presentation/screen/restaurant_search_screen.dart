import 'dart:math';

import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:advertising_app/presentation/providers/restaurant_ad_provider.dart';
import 'package:advertising_app/presentation/providers/restaurants_info_provider.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);


class RestaurantSearchScreen extends StatefulWidget {
  final Map<String, dynamic>? filters;
  const RestaurantSearchScreen({super.key, this.filters});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingFilterBar = false;
  double _lastScrollOffset = 0;
  
  // +++ تم تحديث المتغيرات لتناسب الأنواع الجديدة للحقول +++
  List<String> _selectedDistricts = [];
  List<String> _selectedCategories = [];
  String? _priceFrom, _priceTo;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    
    // Initialize filters from widget parameters
    if (widget.filters != null) {
      // Handle single values from restaurants_screen
      final district = widget.filters!['district'] as String?;
      final category = widget.filters!['category'] as String?;
      final keyword = widget.filters!['keyword'] as String?;
      
      if (district != null && district != 'All') {
        _selectedDistricts = [district];
      }
      if (category != null && category != 'All') {
        _selectedCategories = [category];
      }
      
      // Also handle arrays if they exist
      _selectedDistricts.addAll(List<String>.from(widget.filters!['districts'] ?? []));
      _selectedCategories.addAll(List<String>.from(widget.filters!['categories'] ?? []));

      // Apply keyword locally via provider
      if (keyword != null && keyword.trim().isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final provider = Provider.of<RestaurantAdProvider>(context, listen: false);
          provider.updateKeyword(keyword);
        });
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RestaurantAdProvider>(context, listen: false);
      
      // تطبيق الفلاتر إذا تم تمريرها
      if (widget.filters != null) {
        final emirate = widget.filters!['emirate'] as String?;
        final district = widget.filters!['district'] as String?;
        final category = widget.filters!['category'] as String?;
        final keyword = widget.filters!['keyword'] as String?;

         provider.applyFilters(
          emirate: emirate != 'All' ? emirate : null,
          district: district != 'All' ? district : null,
          category: category != 'All' ? category : null,
          keyword: keyword,
        );
      } else {
        provider.applyAndFetchAds();
      }
    });
  }

  // طباعة سبب فشل واتساب وإطلاقه مع فحص الرقم والرابط
  Future<void> _launchWhatsAppWithDebug(String rawNumber) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // سجّل كل خطوة في الطرفية
      print('🔎 WhatsApp Tap - rawNumber: "$rawNumber"');

      final String number = rawNumber.trim();
      print('   ➤ trimmed: "$number" (isEmpty=${number.isEmpty})');

      // تحقق من الرقم
      if (number.isEmpty || number == 'null' || number == 'nullnow') {
        print('   ✖ الرقم غير متوفر أو يحمل قيمة غير صالحة (null/nullnow)');
        messenger.showSnackBar(const SnackBar(content: Text('رقم الواتساب غير متوفر')));
        return;
      }

      // تنظيف الرقم: إزالة أي محارف غير الأرقام و+
      final String sanitized = number.replaceAll(RegExp(r"[^0-9+]+"), '');
      print('   ➤ sanitized: "$sanitized"');

      // فحص كود الدولة بشكل عام (في الإمارات عادة 971)
      final bool maybeMissingCountryCode = sanitized.startsWith('0') || sanitized.startsWith('05');
      if (maybeMissingCountryCode) {
        print('   ⚠ قد يكون الرقم بدون كود دولة (يفضل +971)');
      }

      final String urlString = PhoneNumberFormatter.getWhatsAppUrl(sanitized);
      final Uri uri = Uri.parse(urlString);
      print('   ➤ url: $urlString');

      // تحقق أولاً من إمكانية الفتح
      final bool can = await canLaunchUrl(uri);
      print('   ➤ canLaunchUrl: $can');
      if (!can) {
        print('   ✖ تعذّر فتح واتساب عبر الرابط أعلاه');
        messenger.showSnackBar(SnackBar(
          content: Text(
            'تعذّر فتح واتساب. سبب محتمل: التطبيق غير مثبت أو الرابط غير صالح\n'
            'الرقم: $sanitized${maybeMissingCountryCode ? ' (تحذير: يبدو بدون كود دولة، جرّب إضافة 971)' : ''}\n'
            'الرابط: $urlString',
          ),
        ));
        return;
      }

      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      print('   ➤ launchUrl result: $launched');
      if (!launched) {
        print('   ✖ فشل إطلاق واتساب بالرابط');
        messenger.showSnackBar(SnackBar(
          content: Text('فشل فتح واتساب بالرابط: $urlString'),
        ));
      } else {
        print('   ✅ تم فتح واتساب بنجاح');
      }
    } catch (e) {
      print('   ❌ خطأ أثناء محاولة فتح واتساب: $e');
      messenger.showSnackBar(SnackBar(content: Text('خطأ اثناء فتح واتساب: $e')));
    }
  }

  // تنظيف نص الموقع لإزالة علامة /
  String _cleanLocation(String location) {
    // إزالة أي / واستبدالها بمسافة واحدة فقط
    String cleaned = location.replaceAll(RegExp(r"\s*/\s*"), ' ');
    // إزالة أي فواصل قد تكون موجودة
    cleaned = cleaned.replaceAll(',', ' ');
    // ضغط المسافات المتعددة إلى مسافة واحدة ثم قص الأطراف
    cleaned = cleaned.replaceAll(RegExp(r"\s+"), ' ').trim();
    return cleaned;
  }

    @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }


 void _handleScroll() {
    final currentOffset = _scrollController.offset;
    if (currentOffset <= 200) {
      if (_showFloatingFilterBar) {
        setState(() => _showFloatingFilterBar = false);
      }
      _lastScrollOffset = currentOffset; 
      return;
    }
    
    if (currentOffset < _lastScrollOffset) {
      if (!_showFloatingFilterBar) {
        setState(() => _showFloatingFilterBar = true);
      }
    } 
    else if (currentOffset > _lastScrollOffset) {
      if (_showFloatingFilterBar) {
        setState(() => _showFloatingFilterBar = false);
      }
    }
    _lastScrollOffset = currentOffset;
  }
  
  // +++ دالة بناء صف الفلاتر المحدثة +++
  Widget _buildFiltersRow() {
    return Container(
      height: 32.h,
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/filter.svg',
              width: 25.w, height: 25.h),
          SizedBox(width: 4.w),
          Flexible(
            flex: 3,
            child: Consumer<RestaurantsInfoProvider>(
              builder: (context, infoProvider, child) {
                List<String> districts = ['All'];
                 if (infoProvider.emirateDisplayNames.isNotEmpty) {
                   // Get districts for the first emirate as default
                   final firstEmirate = infoProvider.emirateDisplayNames.first;
                   districts.addAll(infoProvider.getDistrictsForEmirate(firstEmirate));
                 }
                
                return _buildGenericMultiSelectField<String>(
                   context,
                   S.of(context)!.district,
                   _selectedDistricts,
                   districts,
                   (selection) {
                     setState(() => _selectedDistricts = selection);
                     // Apply filters when district changes
                     final provider = Provider.of<RestaurantAdProvider>(context, listen: false);
                     provider.updateSelectedDistricts(selection);
                   },
                   displayNamer: (district) => district,
                   isFilter: true,
                   isLoading: infoProvider.isLoading,
                 );
              },
            ),
          ),
          SizedBox(width: 1.w),
          Flexible(
            flex: 3, 
             child: Consumer<RestaurantAdProvider>(
              builder: (context, provider, child) {
                return _buildRangePickerField(
                  context, title: S.of(context)!.price, fromValue: provider.priceFrom, toValue: provider.priceTo, unit: "AED", isFilter: true,
                  onTap: () async {
                     final result = await _showRangePicker(context, title: S.of(context)!.price, initialFrom: provider.priceFrom, initialTo: provider.priceTo, unit: "AED");
                      if (result != null) {
                        provider.updatePriceRange(result['from'], result['to']);
                      }
                  }
                );
              },
            ),
          ),
          SizedBox(width: 1.w),
          Flexible(
            flex: 3,
            child: Consumer<RestaurantsInfoProvider>(
              builder: (context, infoProvider, child) {
                List<String> categories = ['All'];
                 if (infoProvider.categoryDisplayNames.isNotEmpty) {
                   categories.addAll(infoProvider.categoryDisplayNames);
                 }
                
                return _buildGenericMultiSelectField<String>(
                   context,
                   S.of(context)!.category,
                   _selectedCategories,
                   categories,
                   (selection) {
                     setState(() => _selectedCategories = selection);
                     // Apply filters when category changes
                     final provider = Provider.of<RestaurantAdProvider>(context, listen: false);
                     provider.updateSelectedCategories(selection);
                   },
                   displayNamer: (category) => category,
                   isFilter: true,
                   isLoading: infoProvider.isLoading,
                 );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    final locale = Localizations.localeOf(context).languageCode;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // مسح جميع الفلاتر قبل الرجوع
          context.read<RestaurantAdProvider>().clearAllFilters();
          // مسح الاختيارات في صفحة المطاعم
          context.read<RestaurantsInfoProvider>().clearSelections();
          context.pop();
        }
      },
      child: Consumer<RestaurantAdProvider>(
        builder: (context, provider, child) {
          final premiumStarAds = provider.restaurantAds.where((j) => j.priority == AdPriority.PremiumStar).toList();
          final premiumAds = provider.restaurantAds.where((j) => j.priority == AdPriority.premium).toList();
          final featuredAds = provider.restaurantAds.where((j) => j.priority == AdPriority.featured).toList();
          final freeAds = provider.restaurantAds.where((j) => j.priority == AdPriority.free).toList();
          final totalAds = provider.restaurantAds.length;

          return Directionality(
            textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
              child: Stack(
                children: [
                  if (provider.isLoadingAds)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.loadAdsError != null)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('خطأ في تحميل البيانات: ${provider.loadAdsError}'),
                          ElevatedButton(
                            onPressed: () => provider.applyAndFetchAds(),
                            child: Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  else
                    SingleChildScrollView(
                      key: const PageStorageKey('restaurant_scroll'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // مسح جميع الفلاتر قبل الرجوع
                                    context.read<RestaurantAdProvider>().clearAllFilters();
                                    // مسح الاختيارات في صفحة المطاعم
                                    context.read<RestaurantsInfoProvider>().clearSelections();
                                    context.pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
                                        Transform.translate(
                                          offset: Offset(-3.w, 0),
                                          child: Text( S.of(context)!.back,
                                            style: TextStyle( fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Center(
                                  child: Text( S.of(context)!.restaurants,
                                    style: TextStyle( fontWeight: FontWeight.w600, fontSize: 24.sp, color: KTextColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: _buildFiltersRow(),
                          ),
                          SizedBox(height:4.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                bool isSmallScreen = MediaQuery.of(context).size.width <= 370;
                                return Row(
                                  children: [
                                    Text(
                                      '${S.of(context)!.ad} $totalAds',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: KTextColor,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 35.w : 30.w),
                                    Expanded(
                                      child: Container(
                                        height: 37.h,
                                        padding: EdgeInsetsDirectional.symmetric( horizontal: isSmallScreen ? 8.w : 12.w),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFF08C2C9)),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset( 'assets/icons/locationicon.svg', width: 18.w, height: 18.h),
                                            SizedBox(width: isSmallScreen ? 8.w : 15.w),
                                            Expanded(
                                              child: Text( S.of(context)!.sort, overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 12.sp),
                                              ),
                                            ),
                                            SizedBox(
                                              width: isSmallScreen ? 35.w : 32.w,
                                              child: Transform.scale(
                                                scale: isSmallScreen ? 0.8 : .9,
                                                child: Switch(
                                                  value: false, onChanged: null, activeColor: Colors.white, activeTrackColor: const Color(0xFF08C2C9),
                                                  inactiveThumbColor: isSmallScreen ? Colors.white : Colors.grey,
                                                  inactiveTrackColor: Colors.grey[300],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // عندما تكون نتيجة الفلترة بالسعر 0، اعرض رسالة توضيحية بالإنجليزية
                          if (totalAds == 0 &&
                              (((provider.priceFrom?.isNotEmpty ?? false) ||
                                (provider.priceTo?.isNotEmpty ?? false))))
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 18.w),
                              child: Center(
                                child: Text(
                                  "No ads in this price range",
                                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          _buildAdList(S.of(context)!.priority_first_premium, premiumStarAds),
                          _buildAdList(S.of(context)!.priority_premium, premiumAds),
                          _buildAdList(S.of(context)!.priority_featured, featuredAds),
                          _buildAdList(S.of(context)!.priority_free, freeAds),
                        ],
                      ),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFloatingFilterBar ? 0 : -160.h,
                    left: 0,
                    right: 0,
                    child: Material(
                       elevation: 6,
                       color: Colors.white,
                      child: Container(
                         padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                         decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                         child: Column(
                           children: [
                             GestureDetector(
                                onTap: () {
                                  // مسح جميع الفلاتر قبل الرجوع
                                  context.read<RestaurantAdProvider>().clearAllFilters();
                                  // مسح الاختيارات في صفحة المطاعم
                                  context.read<RestaurantsInfoProvider>().clearSelections();
                                  context.pop();
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
                                    Transform.translate(
                                      offset: Offset(-3.w, 0),
                                      child: Text(S.of(context)!.back, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              _buildFiltersRow(),
                              SizedBox(height:4.h),
                               LayoutBuilder(
                                 builder: (context, constraints) {
                                  bool isSmallScreen = MediaQuery.of(context).size.width <= 370;
                                   return Row(
                                     children: [
                                       Text('${S.of(context)!.ad} $totalAds', style: TextStyle(fontSize: 12.sp, color: KTextColor, fontWeight: FontWeight.w400)),
                                       SizedBox(width: isSmallScreen ? 35.w : 30.w),
                                       Expanded(
                                         child: Container(
                                           height: 37.h,
                                           padding: EdgeInsetsDirectional.symmetric(horizontal: isSmallScreen ? 8.w : 12.w),
                                           decoration: BoxDecoration(border: Border.all(color: const Color(0xFF08C2C9)), borderRadius: BorderRadius.circular(8.r)),
                                           child: Row(
                                             children: [
                                               SvgPicture.asset('assets/icons/locationicon.svg', width: 18.w, height: 18.h),
                                               SizedBox(width: isSmallScreen ? 12.w : 15.w),
                                               Expanded(
                                                 child: Text(S.of(context)!.sort, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 12.sp)),
                                               ),
                                               SizedBox(
                                                 width: isSmallScreen ? 35.w : 32.w,
                                                 child: Transform.scale(
                                                   scale: isSmallScreen ? 0.8 : .9,
                                                   child: Switch(
                                                     value: false, onChanged: null, activeColor: Colors.white, activeTrackColor: const Color(0xFF08C2C9),
                                                     inactiveThumbColor: isSmallScreen ? Colors.white : Colors.grey, inactiveTrackColor: Colors.grey[300],
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                       ),
                                     ],
                                   );
                                 },
                               ),
                           ],
                         ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    ));
  }

  Widget _buildAdList(String title, List<FavoriteItemInterface> items) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        ...items.map((item) => _buildCard(item)).toList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18.sp, fontWeight: FontWeight.bold, color: KTextColor),
      ),
    );
  }

  Widget _buildCard(FavoriteItemInterface item) {
    return GestureDetector(
      onTap: () {
        context.push('/restaurant_details', extra: {'id': item.id});
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SearchCard(
          showLine1: false, 
          item: _LocationCleanedAdapter(item, _cleanLocation), 
          showDelete: false, 
          onAddToFavorite: () {
            // زر المفضلة بدون وظيفة حالياً
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إضافة الإعلان للمفضلة')),
            );
          },
          onDelete: () { 
            // يمكن إضافة منطق حذف من API هنا إذا لزم الأمر
          },
          // تمرير الأزرار المخصصة مع الوظائف
          customActionButtons: [
            _buildActionIcon(FontAwesomeIcons.whatsapp, onTap: () {
              // التحقق من نوع البيانات أولاً
              if (item is RestaurantAdItem) {
                final whatsappNumber = item.whatsapp;
                print('🟢 WhatsApp Icon tapped for itemId=${item.id}');
                print('   item.whatsapp: "${item.whatsapp}"');
                if (whatsappNumber.isNotEmpty && whatsappNumber != 'nullnow' && whatsappNumber != 'null') {
                  // طبّق نفس آلية صفحة تفاصيل المطعم: ابنِ رابط واتساب ثم استخدم _launchUrl
                  final whatsappUrl = PhoneNumberFormatter.getWhatsAppUrl(whatsappNumber);
                  print('   ▶ using details-screen mechanism, url: $whatsappUrl');
                  _launchUrl(whatsappUrl);
                } else {
                  print('   ✖ الشرط منع الإطلاق لأن القيمة فارغة/غير صالحة');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("رقم الواتساب غير متوفر")),
                  );
                }
              } else {
                print('   ✖ عنصر البطاقة ليس RestaurantAdItem، النوع: ${item.runtimeType}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("رقم الواتساب غير متوفر")),
                );
              }
            }),
            const SizedBox(width: 5),
            _buildActionIcon(Icons.phone, onTap: () {
              // التحقق من نوع البيانات أولاً
              if (item is RestaurantAdItem) {
                final phoneNumber = item.phoneNumber;
                if (phoneNumber.isNotEmpty && phoneNumber != 'nullnow' && phoneNumber != 'null') {
                  final url = PhoneNumberFormatter.getTelUrl(phoneNumber);
                  _launchUrl(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Phone number not available")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Phone number not available")),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 35.h,
        width: 62.w,
        decoration: BoxDecoration(
          color: const Color(0xFF01547E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // دالة فتح الروابط
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
}

// عنصر مكيّف لتنظيف الموقع وإزالة علامة /
class _LocationCleanedAdapter implements FavoriteItemInterface {
  final FavoriteItemInterface _base;
  final String Function(String) _cleaner;
  _LocationCleanedAdapter(this._base, this._cleaner);

  @override
  String get title => _base.title;
  @override
  String get location => _cleaner(_base.location);
  @override
  String get price => _base.price;
  @override
  String get line1 => _base.line1;
  @override
  String get details => _base.details;
  @override
  String get date => _base.date;
  @override
  String get contact => _base.contact;
  @override
  bool get isPremium => _base.isPremium;
  @override
  List<String> get images => _base.images;
  @override
  AdPriority get priority => _base.priority;
  @override
  String get category => _base.category; // Pass through the category
  
  @override
  String get addCategory => _base.addCategory; // Pass through the addCategory
  @override
  get id => _base.id;
}

// Helper functions for filters
Widget _buildGenericMultiSelectField<T>(BuildContext context, String title, List<T> selectedValues, List<T> allItems, Function(List<T>) onConfirm, {required String Function(T) displayNamer, bool isLoading = false, bool isFilter = true}) {
  String displayText = isLoading ? "loading" : selectedValues.isEmpty ? title : selectedValues.map(displayNamer).join(', ');
  return GestureDetector(
    onTap: isLoading ? null : () async {
      final result = await showModalBottomSheet<List<T>>(context: context, isScrollControlled: true, builder: (context) => _GenericMultiSelectBottomSheet(title: title, items: allItems, initialSelection: selectedValues, displayNamer: displayNamer));
      if (result != null) onConfirm(result);
    },
    child: Container(
        height: isFilter ? 35 : 48, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 8), 
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
        child: Text(displayText, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 9.5), overflow: TextOverflow.ellipsis, maxLines: 1)
    ),
  );
}

Widget _buildRangePickerField(BuildContext context, {required String title, String? fromValue, String? toValue, required String unit, required VoidCallback onTap, bool isFilter = false}) {
    final s = S.of(context);
    String displayText;
      displayText = (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) 
          ? title
          : '${fromValue ?? s.from} - ${toValue ?? s.to} ${unit}'.trim();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(!isFilter) Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
        if(!isFilter) const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: isFilter ? 34 : 48, 
            width: double.infinity, 
            padding: const EdgeInsets.symmetric(horizontal: 8), 
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Text(displayText, style: TextStyle(
              fontWeight: (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) ? FontWeight.w500 : FontWeight.w500,
              color: (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) ? KTextColor : KTextColor,
              fontSize: 9.5), 
              overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ),
      ],
    );
  }

Future<Map<String, String?>?> _showRangePicker(BuildContext context, {required String title, String? initialFrom, String? initialTo, required String unit}) {
    return showModalBottomSheet<Map<String, String?>?>(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _RangeSelectionBottomSheet(title: title, initialFrom: initialFrom, initialTo: initialTo, unit: unit),
    );
}

class _GenericMultiSelectBottomSheet<T> extends StatefulWidget {
  final String title; final List<T> items; final List<T> initialSelection; final String Function(T) displayNamer;
  const _GenericMultiSelectBottomSheet({Key? key, required this.title, required this.items, required this.initialSelection, required this.displayNamer}) : super(key: key);
  @override _GenericMultiSelectBottomSheetState<T> createState() => _GenericMultiSelectBottomSheetState<T>();
}
class _GenericMultiSelectBottomSheetState<T> extends State<_GenericMultiSelectBottomSheet<T>> {
  late List<T> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];
  
  @override
  void initState() { super.initState(); _selectedItems = List.from(widget.initialSelection); _filteredItems = List.from(widget.items); _searchController.addListener(_filterItems); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  void _filterItems() { final query = _searchController.text.toLowerCase(); setState(() { _filteredItems = widget.items.where((item) => widget.displayNamer(item).toLowerCase().contains(query)).toList(); }); }
  void _onItemTapped(T item) { setState(() { if(_selectedItems.contains(item)) { _selectedItems.remove(item); } else { _selectedItems.add(item); } }); }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedItems.clear();
                    });
                  },
                  child: Text(s.reset, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _searchController, decoration: InputDecoration(hintText: s.search, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)))),
            const SizedBox(height: 8), const Divider(),
            Expanded(
              child: _filteredItems.isEmpty ? Center(child: Text(s.noResultsFound)) : ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return CheckboxListTile(title: Text(widget.displayNamer(item)), value: _selectedItems.contains(item), activeColor: KPrimaryColor, controlAffinity: ListTileControlAffinity.leading, onChanged: (_) => _onItemTapped(item));
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedItems),
                style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(s.apply, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ... (باقي الكود ودوال المساعدة واللوحات السفلية تبقى كما هي)

Widget _buildMultiSelectField(BuildContext context, String title, List<String> selectedValues, List<String> allItems, Function(List<String>) onConfirm, {bool isFilter = false}) {
    final s = S.of(context);
    String displayText = selectedValues.isEmpty ? title : selectedValues.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         if(!isFilter) Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
         if(!isFilter) const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<List<String>>(
              context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (context) => _MultiSelectBottomSheet(title: title, items: allItems, initialSelection: selectedValues),
            );
            if (result != null) { onConfirm(result); }
          },
          child: Container(
            height: isFilter ? 35 : 48,
            width: double.infinity, 
            padding: const EdgeInsets.symmetric(horizontal: 8), 
            alignment: Alignment.center, 
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Text(
              displayText,
              style: TextStyle(
                fontWeight: selectedValues.isEmpty ? FontWeight.w500 : FontWeight.w500,
                color: selectedValues.isEmpty ? KTextColor : KTextColor,
                fontSize: 9.5
              ),
              overflow: TextOverflow.ellipsis, maxLines: 1,
            ),
          ),
        ),
      ],
    );
}

class _MultiSelectBottomSheet extends StatefulWidget {
  final String title; final List<String> items; final List<String> initialSelection;
  const _MultiSelectBottomSheet({Key? key, required this.title, required this.items, required this.initialSelection}) : super(key: key);
  @override
  _MultiSelectBottomSheetState createState() => _MultiSelectBottomSheetState();
}
class _MultiSelectBottomSheetState extends State<_MultiSelectBottomSheet> {
  late final List<String> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelection);
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList();
    });
  }
  void _onItemTapped(String item) {
    setState(() {
      if (_selectedItems.contains(item)) { _selectedItems.remove(item); } 
      else { _selectedItems.add(item); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          side: MaterialStateBorderSide.resolveWith(
            (_) => BorderSide(width: 1.0, color: borderColor),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _searchController,
                  style: TextStyle(color: KTextColor), 
                  decoration: InputDecoration(
                    hintText: s.search, prefixIcon: Icon(Icons.search, color: KTextColor),
                    hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 8), const Divider(),
                Expanded(
                  child: _filteredItems.isEmpty 
                    ? Center(child: Text(s.noResultsFound, style: TextStyle(color: KTextColor)))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return CheckboxListTile(
                            title: Text(item, style: TextStyle(color: KTextColor)),
                            value: _selectedItems.contains(item),
                            activeColor: KPrimaryColor,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) => _onItemTapped(item),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedItems),
                    child: Text(s.apply),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: KPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeSelectionBottomSheet extends StatefulWidget {
  final String title; final String? initialFrom; final String? initialTo; final String unit;
  const _RangeSelectionBottomSheet({Key? key, required this.title, this.initialFrom, this.initialTo, required this.unit}) : super(key: key);
  @override
  __RangeSelectionBottomSheetState createState() => __RangeSelectionBottomSheetState();
}
class __RangeSelectionBottomSheetState extends State<_RangeSelectionBottomSheet> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialFrom);
    _toController = TextEditingController(text: widget.initialTo);
  }
  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    Widget buildTextField(String hint, String suffix, TextEditingController controller) {
      return TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          suffixIcon: suffix.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(suffix, style: TextStyle(color: KTextColor, fontWeight: FontWeight.bold, fontSize: 12)))
              : null,
          suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fillColor: Colors.white,
          filled: true,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
            TextButton(
              onPressed: () { _fromController.clear(); _toController.clear(); setState(() {}); }, 
              child: Text(s.reset, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.sp))),
          ]),
          SizedBox(height: 16.h),
          Row(children: [
            Expanded(child: buildTextField(s.from, widget.unit, _fromController)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(s.to, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14))),
            Expanded(child: buildTextField(s.to, widget.unit, _toController)),
          ]),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'from': _fromController.text, 'to': _toController.text}),
              child: Text(s.apply, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}