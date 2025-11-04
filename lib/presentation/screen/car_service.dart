// lib/presentation/screens/car_service.dart

import 'package:advertising_app/presentation/providers/car_services_info_provider.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import '../widget/unified_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/best_advertiser_adapters.dart';
import 'dart:async';
import 'package:advertising_app/data/repository/smart_search_repository.dart';
import 'package:advertising_app/data/model/smart_search_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class CarService extends StatefulWidget {
  const CarService({super.key});

  @override
  State<CarService> createState() => _CarServiceState();
}

class _CarServiceState extends State<CarService>
    with FavoritesHelper<CarService> {
  int _selectedIndex = 5;

  // Smart search state (same pattern as CarSales)
  final TextEditingController _smartSearchController = TextEditingController();
  Timer? _smartDebounce;
  late final SmartSearchRepository _smartRepo;
  SmartSearchResponse? _smartSearchResponse;
  List<SmartSearchItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // مسح الفلاتر القديمة عند الدخول للصفحة لضمان بداية جديدة
      final provider = context.read<CarServicesInfoProvider>();
      provider.clearFilters();
      await provider.fetchLandingPageData();
      await loadFavoriteIds();
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
        S.of(context).otherservices
      ];
  Map<String, String> get categoryRoutes => {
        S.of(context).carsales: "/home",
        S.of(context).realestate: "/realEstate",
        S.of(context).electronics: "/electronics",
        S.of(context).jobs: "/jobs",
        S.of(context).carrent: "/car_rent",
        S.of(context).carservices: "/carServices",
        S.of(context).restaurants: "/restaurants",
        S.of(context).otherservices: "/otherServices"
      };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark));

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: CustomBottomNav(currentIndex: 0),
          body: Consumer<CarServicesInfoProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                      child: Row(children: [
                        Expanded(
                            child: SizedBox(
                                height: 35.h,
                                child: TextField(
                                    style: TextStyle(
                                        color: KTextColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500),
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
                                            color: const Color.fromRGBO(
                                                129, 126, 126, 1),
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500),
                                        //prefixIcon: Icon(Icons.search,
                                        //    color: borderColor, size: 25.sp),
                                        prefixIcon: IconButton(
                                            icon: Icon(Icons.search, color: borderColor, size: 22.sp),
                                            onPressed: () {
                                              final text = _smartSearchController.text.trim();
                                              if (text.isNotEmpty) {
                                                _performSmartSearch(text);
                                              }
                                            },
                                        ),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            borderSide:
                                                BorderSide(color: borderColor)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            borderSide: BorderSide(
                                                color: borderColor,
                                                width: 1.5)),
                                        filled: true,
                                        fillColor: Colors.white,
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 8.w, vertical: 0.h))))),
                        IconButton(
                            icon: Icon(Icons.notifications_none,
                                color: borderColor, size: 35.sp),
                            onPressed: () {}),
                      ]),
                    ),
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
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 10.w),
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
                              if (route != null) context.push(route);
                            })),
                    SizedBox(height: 2.h),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                      child: Column(
                        children: [
                          Row(children: [
                            Icon(Icons.star, color: Colors.amber, size: 20.sp),
                            SizedBox(width: 6.w),
                            Text(s.discover_car_service,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    color: KTextColor))
                          ]),
                          SizedBox(height: 4.h),
                          UnifiedDropdown<String>(
                            title: s.emirate,
                            selectedValue: provider.selectedEmirate,
                            items: provider.emirateDisplayNames,
                            onConfirm: (selection) =>
                                provider.updateSelectedEmirate(selection),
                            isLoading: provider.isLoadingFilters,
                          ),
                          SizedBox(height: 3.h),
                          UnifiedDropdown<String>(
                            title: s.serviceType,
                            selectedValue: provider.selectedServiceType,
                            items: provider.serviceTypeDisplayNames,
                            onConfirm: (selection) =>
                                provider.updateSelectedServiceType(selection),
                            isLoading: provider.isLoadingFilters,
                          ),
                          SizedBox(height: 4.h),
                          UnifiedSearchButton(
                            onPressed: () {
                              // التحقق من اختيار الإمارة ونوع الخدمة
                              if (provider.selectedEmirate == null ||
                                  provider.selectedEmirate!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.please_select_emirate),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              if (provider.selectedServiceType == null ||
                                  provider.selectedServiceType!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.please_select_service_type),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final filters = provider.getFormattedFilters();

                              // إرسال الفلاتر إلى صفحة البحث
                              context
                                  .push('/car_service_search', extra: filters)
                                  .then((_) {
                                // مسح الفلاتر عند العودة من صفحة البحث
                                provider.clearFilters();
                              });
                            },
                          ),
                          SizedBox(height: 7.h),
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
                            child: GestureDetector(
                                onTap: () =>
                                    context.push('/carservicetofferbox'),
                                child: Container(
                                    padding: EdgeInsetsDirectional.symmetric(
                                        horizontal: 8.w),
                                    height: 68.h,
                                    decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [
                                          Color(0xFFE4F8F6),
                                          Color(0xFFC9F8FE)
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(8.r)),
                                    child: Row(children: [
                                      SvgPicture.asset(
                                          'assets/icons/cardolar.svg',
                                          height: 25.sp,
                                          width: 24.sp),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                          child: Text(
                                              s.click_for_deals_car_service,
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: KTextColor,
                                                  fontWeight:
                                                      FontWeight.w500))),
                                      SizedBox(width: 12.w),
                                      Icon(Icons.arrow_forward_ios,
                                          size: 22.sp, color: KTextColor)
                                    ]))),
                          ),
                          SizedBox(height: 5.h),
                          Row(children: [
                            SizedBox(width: 4.w),
                            Icon(Icons.star, color: Colors.amber, size: 20.sp),
                            SizedBox(width: 4.w),
                            Text(s.top_premium_dealers,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp,
                                    color: KTextColor))
                          ]),
                          SizedBox(height: 1.h),
                          _buildTopDealersSection(provider),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopDealersSection(CarServicesInfoProvider provider) {
    if (provider.isLoadingTopGarages && provider.topGarages.isEmpty) {
      return const Center(heightFactor: 5, child: CircularProgressIndicator());
    }
    if (provider.topGaragesError != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(provider.topGaragesError!)));
    }

    final garagesWithAds =
        provider.topGarages.where((g) => g.ads.isNotEmpty).toList();
    if (garagesWithAds.isEmpty) return const SizedBox.shrink();

    return Column(
      children: garagesWithAds.map((garage) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 16.w, vertical: 8.h),
              child: Row(children: [
                Text(garage.name,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: KTextColor)),
                const Spacer(),
                InkWell(
                    onTap: () {
                      final advertiserId = garage.id.toString();
                      debugPrint(
                          'Navigating to all ads with advertiser ID: $advertiserId');
                      context.push('/all_ad_car_sales/$advertiserId');
                    },
                    child: Text(S.of(context).see_all_ads,
                        style: TextStyle(
                            fontSize: 14.sp,
                            decoration: TextDecoration.underline,
                            decorationColor: borderColor,
                            color: borderColor,
                            fontWeight: FontWeight.w500))),
              ]),
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: garage.ads.length,
                padding: EdgeInsetsDirectional.only(end: 8.w),
                itemBuilder: (context, index) {
                  final ad = garage.ads[index];
                  return GestureDetector(
                    onTap: () {
                      // context.push('/car_service_details', extra: ad);
                    },
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: 8.w),
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
                                  offset: Offset(0, 2.h))
                            ]),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: CachedNetworkImage(
                                        imageUrl:
                                            ImageUrlHelper.getMainImageUrl(
                                                ad.mainImage ?? ''),
                                        height: 94.h,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                                color: Colors.grey[300],
                                                child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))),
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                                'assets/images/car.jpg',
                                                fit: BoxFit.cover))),
                                  Positioned(
                                  top: 8,
                                  right: 8,
                                  child: buildFavoriteIcon(
                                    BestAdvertiserCarServiceItemAdapter(ad),
                                    onAddToFavorite: () {},
                                    onRemoveFromFavorite: null,
                                  ),
                                ),
                              ]),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                          "${NumberFormatter.formatPrice(ad.price)}",
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.5.sp)),
                                      Text(ad.serviceName ?? '',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.5.sp,
                                              color: KTextColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                          "${ad.emirate ?? ''} ${ad.district ?? ''}",
                                          style: TextStyle(
                                              fontSize: 11.5.sp,
                                              color: const Color.fromRGBO(
                                                  165, 164, 162, 1),
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
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
  }
}
