import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/other_services_ad_provider.dart';
import 'package:advertising_app/presentation/providers/other_services_info_provider.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:advertising_app/presentation/widget/unified_dropdown.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/model/best_advertiser_adapters.dart';
import 'dart:async';
import 'package:advertising_app/data/repository/smart_search_repository.dart';
import 'package:advertising_app/data/model/smart_search_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class OtherServiceScreen extends StatefulWidget {
  const OtherServiceScreen({super.key});

  @override
  State<OtherServiceScreen> createState() => _OtherServiceScreenState();
}

class _OtherServiceScreenState extends State<OtherServiceScreen>
    with FavoritesHelper<OtherServiceScreen> {
  int _selectedIndex = 7;

  // +++ اختيارات فردية مع خيار All +++
  String? _selectedEmirate;
  String? _selectedSectionType;

  // Smart search state (same pattern as CarSales)
  final TextEditingController _smartSearchController = TextEditingController();
  Timer? _smartDebounce;
  late final SmartSearchRepository _smartRepo;
  SmartSearchResponse? _smartSearchResponse;
  List<SmartSearchItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Fetch other services ads when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OtherServicesAdProvider>().fetchAds();
      // جلب بيانات الفلاتر (الإمارات و الأقسام) من المصدر الحقيقي
      context.read<OtherServicesInfoProvider>().fetchAllData();
      loadFavoriteIds();
    });
    // Initialize smart search repository and listener
    _smartRepo = SmartSearchRepository(ApiService());
    _smartSearchController.addListener(_onSmartSearchChanged);
  }

  @override
  void dispose() {
    _smartDebounce?.cancel();
    _smartSearchController.dispose();
    super.dispose();
  }

  void _onSmartSearchChanged() {
    final text = _smartSearchController.text.trim();
    _smartDebounce?.cancel();
    _smartDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (text.isEmpty) {
        setState(() {
          _suggestions = [];
          _smartSearchResponse = null;
        });
        return;
      }
      final resp = await _smartRepo.smartSearch(text);
      if (!mounted) return;
      setState(() {
        _smartSearchResponse = resp;
        _suggestions = resp.results;
      });
    });
  }

  Future<void> _performSmartSearch(String keyword) async {
    final resp = await _smartRepo.smartSearch(keyword);
    if (!mounted) return;
    setState(() {
      _smartSearchResponse = resp;
      _suggestions = resp.results;
    });
    // Navigate to smart search results page
    await context.push('/smart_search', extra: resp);
  }

  List<String> get categories => [
        S.of(context).carsales,
        S.of(context).realestate,
        S.of(context).electronics,
        S.of(context).jobs,
        S.of(context).carrent,
        S.of(context).carservices,
        S.of(context).restaurants,
        S.of(context).otherservices,
      ];

  Map<String, String> get categoryRoutes => {
        S.of(context).carsales: "/home",
        S.of(context).realestate: "/realEstate",
        S.of(context).electronics: "/electronics",
        S.of(context).jobs: "/jobs",
        S.of(context).carrent: "/car_rent",
        S.of(context).carservices: "/carServices",
        S.of(context).restaurants: "/restaurants",
        S.of(context).otherservices: "/otherServices",
      };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: CustomBottomNav(currentIndex: 0),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: TextField(
                            style: TextStyle(
                              color: KTextColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            controller: _smartSearchController,
                            onSubmitted: (value) {
                              final text = value.trim();
                              if (text.isNotEmpty) {
                                _performSmartSearch(text);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: s.smart_search,
                              hintStyle: TextStyle(
                                  color: const Color.fromRGBO(129, 126, 126, 1),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500),
                              //prefixIcon: Icon(Icons.search, color: borderColor, size: 25.sp),
                              prefixIcon: IconButton(
                                icon: Icon(Icons.search, color: borderColor, size: 22.sp),
                                onPressed: () {
                                  final text = _smartSearchController.text.trim();
                                  if (text.isNotEmpty) {
                                    _performSmartSearch(text);
                                  }
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: borderColor, width: 1.5)),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 0.h,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: borderColor,
                          size: 35.sp,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                // Suggestions list below smart search (same pattern as CarSales)
                if (_suggestions.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: borderColor.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              '${S.of(context).category} ${item.itemType}',
                              style: TextStyle(color: KTextColor, fontSize: 13.sp),
                            ),
                            trailing: Text(
                              '${(Localizations.localeOf(context).languageCode == 'ar' ? 'إجمالي الإعلانات' : 'Total Ads')} ${item.totalAds}',
                              style: TextStyle(color: KPrimaryColor, fontSize: 12.sp, fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              final current = _smartSearchResponse;
                              if (current != null) {
                                context.push('/smart_search', extra: current);
                              } else {
                                final text = _smartSearchController.text.trim();
                                if (text.isNotEmpty) {
                                  _performSmartSearch(text);
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                  child: CustomCategoryGrid(
                    categories: categories,
                    selectedIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    onCategoryPressed: (selectedCategory) {
                      final route = categoryRoutes[selectedCategory];
                      if (route != null) {
                        context.push(route);
                      } else {
                        print('Route not found for $selectedCategory');
                      }
                    },
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                  child: Column(
                    children: [
                      // قسم عروض الخدمات اليومية والفلاتر كما كان سابقاً
                      Row(
                        children: [
                          SizedBox(width: 4.w),
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(
                            s.discover_service_offers,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: KTextColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      Consumer<OtherServicesInfoProvider>(
                        builder: (context, info, _) {
                          final emirateItems = ['All', ...info.emirateDisplayNames];
                          return UnifiedDropdown(
                            title: s.emirate,
                            selectedValue: _selectedEmirate,
                            items: emirateItems,
                            onConfirm: (selection) => setState(() => _selectedEmirate = selection),
                            isLoading: info.isLoading,
                          );
                        },
                      ),

                      SizedBox(height: 3.h),

                      Consumer<OtherServicesInfoProvider>(
                        builder: (context, info, _) {
                          final sectionItems = ['All', ...info.sectionTypes];
                          return UnifiedDropdown(
                            title: s.section_type,
                            selectedValue: _selectedSectionType,
                            items: sectionItems,
                            onConfirm: (selection) => setState(() => _selectedSectionType = selection),
                            isLoading: info.isLoading,
                          );
                        },
                      ),

                      SizedBox(height: 4.h),

                      UnifiedSearchButton(
                        onPressed: () {
                          if (_selectedEmirate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.please_select_emirate)),
                            );
                            return;
                          }
                          if (_selectedSectionType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.please_select_section_type)),
                            );
                            return;
                          }
                          // لا ترسل قيمة All إلى الراوتر/الـ API
                          final Map<String, String> extras = {};
                          final emirateVal = _selectedEmirate?.trim();
                          final sectionVal = _selectedSectionType?.trim();
                          if (emirateVal != null && emirateVal.toLowerCase() != 'all') {
                            extras['emirate'] = emirateVal;
                          }
                          if (sectionVal != null && sectionVal.toLowerCase() != 'all') {
                            extras['section_type'] = sectionVal; // استخدم المفتاح المتوافق مع الـ API
                          }
                          context.push('/other_service_search', extra: extras);
                        },
                      ),

                      SizedBox(height: 7.h),

                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                        child: GestureDetector(
                          onTap: () => context.push('/other_service_offer_box'),
                          child: Container(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                            height: 68.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.click_daily_servir_offers,
                                    style: TextStyle(fontSize: 13.sp, color: KTextColor, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Icon(Icons.arrow_forward_ios, size: 22.sp, color: KTextColor),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.h),

                      // بداية قسم Top Premium Dealers المُعدل فقط
                      Row(
                        children: [
                          SizedBox(width: 4.w),
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 4.w),
                          Text(s.top_premium_dealers, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor)),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      // استخدام بيانات أفضل الوكلاء من OtherServicesInfoProvider
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: context.read<OtherServicesInfoProvider>().getBestDealers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: TextStyle(color: Colors.red, fontSize: 14.sp),
                              ),
                            );
                          }
                          final dealers = snapshot.data ?? [];
                          if (dealers.isEmpty) {
                            return Center(
                              child: Text(
                                'No premium dealers found',
                                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                              ),
                            );
                          }
                          return Column(
                            children: dealers.map((dealer) {
                              final advertiserName = dealer['advertiser_name']?.toString() ?? dealer['name']?.toString() ?? 'Unknown Advertiser';
                              final rawId = dealer['advertiser_id'] ?? dealer['id'] ?? dealer['user_id'] ?? 0;
                              final advertiserId = int.tryParse(rawId.toString()) ?? 0;
                              final latestAds = (dealer['latest_ads'] is List)
                                  ? List<Map<String, dynamic>>.from(dealer['latest_ads'])
                                  : <Map<String, dynamic>>[];

                              // لا نعرض القسم إذا لم يكن لديه إعلانات
                              if (latestAds.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          advertiserName,
                                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: KTextColor),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            final idStr = advertiserId.toString();
                                            debugPrint('Navigating to all ads with advertiser ID: $idStr');
                                            if (idStr == '0') {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('لا يمكن عرض إعلانات هذا المعلن حالياً')),
                                              );
                                              return;
                                            }
                                            context.push('/all_ad_car_sales/$idStr');
                                          },
                                          child: Text(
                                            s.see_all_ads,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              decoration: TextDecoration.underline,
                                              decorationColor: borderColor,
                                              color: borderColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 175,
                                    width: double.infinity,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: min(latestAds.length, 20),
                                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                                      itemBuilder: (context, index) {
                                        final ad = latestAds[index];
                                        final price = ad['price']?.toString() ?? '';
                                        final serviceName = ad['service_name']?.toString() ?? ad['title']?.toString() ?? 'No title';
                                        final emirate = ad['emirate']?.toString() ?? '';
                                        final district = ad['district']?.toString() ?? '';
                                        final mainImage = ad['main_image']?.toString() ?? ad['image']?.toString() ??
                                            ((ad['images'] is List && (ad['images'] as List).isNotEmpty) ? (ad['images'] as List).first.toString() : '');
                                        final imageUrl = ImageUrlHelper.getMainImageUrl(mainImage);

                                        return Padding(
                                          padding: EdgeInsetsDirectional.only(end: index == latestAds.length - 1 ? 0 : 4.w),
                                          child: GestureDetector(
                                             onTap: () {
       // context.push('/other_service-details/${ad.id}');
      },
                                            child: Container(
                                              width: 145,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(4.r),
                                                border: Border.all(color: Colors.grey.shade300),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.withOpacity(0.15),
                                                    blurRadius: 5.r,
                                                    offset: Offset(0, 2.h),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(4.r),
                                                        child: imageUrl.isNotEmpty
                                                            ? CachedNetworkImage(
                                                                imageUrl: imageUrl,
                                                                height: 94.h,
                                                                width: double.infinity,
                                                                fit: BoxFit.cover,
                                                                placeholder: (context, url) => Container(
                                                                  color: Colors.grey[300],
                                                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                                ),
                                                                errorWidget: (context, url, error) => Container(
                                                                  height: 94.h,
                                                                  width: double.infinity,
                                                                  color: Colors.grey.shade200,
                                                                  child: Icon(
                                                                    Icons.miscellaneous_services,
                                                                    color: Colors.grey.shade400,
                                                                    size: 40,
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                height: 94.h,
                                                                width: double.infinity,
                                                                color: Colors.grey.shade200,
                                                                child: Icon(
                                                                  Icons.miscellaneous_services,
                                                                  color: Colors.grey.shade400,
                                                                  size: 40,
                                                                ),
                                                              ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        right: 8,
                                                        child: buildFavoriteIcon(
                                                          BestAdvertiserOtherServiceItemAdapter(
                                                            BestAdvertiserAd.fromJson(
                                                              ad,
                                                              advertiserId: advertiserId,
                                                              advertiserName: advertiserName,
                                                            ),
                                                          ),
                                                          onAddToFavorite: () {},
                                                          onRemoveFromFavorite: null,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          Text(
                                                            "${NumberFormatter.formatPrice(price)}",
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 11.5.sp,
                                                            ),
                                                          ),
                                                          Text(
                                                            serviceName,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 11.5.sp,
                                                              color: KTextColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${emirate} ${district}'.trim(),
                                                            style: TextStyle(
                                                              fontSize: 11.5.sp,
                                                              color: const Color.fromRGBO(165, 164, 162, 1),
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                    ],
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