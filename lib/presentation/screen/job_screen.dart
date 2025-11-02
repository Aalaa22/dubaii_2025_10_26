import 'dart:math';
import 'package:advertising_app/presentation/providers/job_ad_provider.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/presentation/providers/job_info_provider.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:advertising_app/presentation/widget/unified_dropdown.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/best_advertiser_adapters.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> with FavoritesHelper<JobScreen> {
  int _selectedIndex = 3;

  // +++ تحويل المتغيرات لدعم الاختيار الفردي +++
  String? _selectedEmirate;
  String? _selectedCategoryType;

  @override
  void initState() {
    super.initState();
    // Fetch job ads when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load favorites cache
      loadFavoriteIds();
      final provider = context.read<JobAdProvider>();
      provider.fetchAds();
      provider.fetchBestAdvertisers();
      provider.fetchAllJobScreenData();
      // جلب صور الفئات من مزود معلومات الوظائف
      context.read<JobInfoProvider>().fetchJobAdValues();
    });
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
                            decoration: InputDecoration(
                              hintText: s.smart_search,
                              hintStyle: TextStyle(
                                  color: const Color.fromRGBO(129, 126, 126, 1),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500),
                              prefixIcon: Icon(
                                Icons.search,
                                color: borderColor,
                                size: 25.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide:
                                    BorderSide(color: borderColor, width: 1.5),
                              ),
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
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(
                            s.discover_best_job,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: KTextColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Consumer<JobAdProvider>(
                        builder: (context, provider, _) {
                          final emirateItems = [
                            'All',
                            ...provider.emirateNames
                          ];
                          return UnifiedDropdown(
                            title: s.emirate,
                            selectedValue: _selectedEmirate,
                            items: emirateItems,
                            onConfirm: (selection) =>
                                setState(() => _selectedEmirate = selection),
                            isLoading: provider.isEmiratesLoading,
                          );
                        },
                      ),
                      SizedBox(height: 3.h),
                      Consumer<JobAdProvider>(
                        builder: (context, provider, _) {
                          final categoryTypeItems = [
                            'All',
                            ...provider.categoryTypes
                          ];
                          return UnifiedDropdown(
                            title: s.category_type,
                            selectedValue: _selectedCategoryType,
                            items: categoryTypeItems,
                            onConfirm: (selection) => setState(
                                () => _selectedCategoryType = selection),
                            isLoading: provider.isCategoryTypesLoading,
                          );
                        },
                      ),
                      SizedBox(height: 4.h),
                      UnifiedSearchButton(
                        onPressed: () {
                          // Validation: يتطلب اختيار الإمارة ونوع الفئة (يسمح بـ All)
                          if (_selectedEmirate == null ||
                              _selectedCategoryType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("please select required fields")),
                            );
                            return;
                          }

                          // حفظ الفلاتر في الـ Provider قبل الانتقال
                          final provider = context.read<JobAdProvider>();
                          provider.updateSelectedEmirate(_selectedEmirate);
                          provider.updateSelectedCategoryType(
                              _selectedCategoryType);

                          context.push('/job_search');
                        },
                        text: s.search,
                      ),
                      SizedBox(height: 7.h),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                        child: GestureDetector(
                          onTap: () => context.push('/jobofferbox'),
                          child: Container(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
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
                                    s.click_for_deals_job,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: KTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Icon(Icons.arrow_forward_ios,
                                    size: 22.sp, color: KTextColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          SizedBox(width: 4.w),
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 4.w),
                          Text(
                            s.top_premium_dealers,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: KTextColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Consumer<JobAdProvider>(
                        builder: (context, provider, _) {
                          if (provider.isBestAdvertisersLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (provider.bestAdvertisersError != null) {
                            return Center(
                              child: Text(
                                'Error: ${provider.bestAdvertisersError}',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 14.sp),
                              ),
                            );
                          }

                          if (provider.bestAdvertisers.isEmpty) {
                            return Center(
                              child: Text(
                                s.noResultsFound,
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14.sp),
                              ),
                            );
                          }

                          // بناء الأقسام من البيانات الفعلية
                          return Column(
                            children:
                                provider.bestAdvertisers.map((advertiser) {
                              // فلترة إعلانات الوظائف فقط
                              final jobAds = advertiser.ads.where((ad) {
                                final category =
                                    ad.category?.toLowerCase() ?? '';
                                return category.contains('job');
                              }).toList();

                              if (jobAds.isEmpty)
                                return const SizedBox.shrink();

                              return Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 8.h),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            advertiser.name,
                                            style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w600,
                                                color: KTextColor),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            final advertiserId =
                                                advertiser.id.toString();
                                            debugPrint(
                                                'Navigating to all ads with advertiser ID: $advertiserId');
                                            context.push(
                                                '/all_ad_car_sales/$advertiserId');
                                          },
                                          child: Text(
                                            s.see_all_ads,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              decoration:
                                                  TextDecoration.underline,
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
                                      itemCount: min(jobAds.length, 20),
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5.w),
                                      itemBuilder: (context, index) {
                                        final ad = jobAds[index];
                                        // استخدام صور الفئات من JobAdProvider بدلًا من صورة وهمية
                                        final jobsProvider =
                                            Provider.of<JobAdProvider>(context,
                                                listen: false);
                                        final imagePath = jobsProvider
                                                .categoryImages['job_offer'] ??
                                            jobsProvider
                                                .categoryImages['job_seeker'] ??
                                            '';
                                        final imageUrl =
                                            ImageUrlHelper.getFullImageUrl(
                                                imagePath);
                                        // نص السعر/الراتب ليُستخدم لاحقًا في عناصر الواجهة
                                        final priceText =
                                            (ad.priceRange ?? ad.salary ?? '')
                                                .trim();

                                        return Padding(
                                          padding: EdgeInsetsDirectional.only(
                                              end: index == jobAds.length - 1
                                                  ? 0
                                                  : 4.w),
                                          child: Container(
                                            width: 145,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.15),
                                                    blurRadius: 5.r,
                                                    offset: Offset(0, 2.h)),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.r),
                                                      child: imageUrl.isNotEmpty
                                                          ? CachedNetworkImage(
                                                              imageUrl:
                                                                  imageUrl,
                                                              height: 94.h,
                                                              width: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                              placeholder: (context,
                                                                      url) =>
                                                                  const Center(
                                                                child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                              ),
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  const SizedBox
                                                                      .shrink(),
                                                            )
                                                          : const Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2),
                                                            ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: buildFavoriteIcon(
                                                        BestAdvertiserJobItemAdapter(ad),
                                                        onAddToFavorite: () {},
                                                        onRemoveFromFavorite: null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 6.w),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        // عرض الراتب/نطاق السعر بشكل آمن
                                                        if (priceText
                                                            .isNotEmpty)
                                                          Text(
                                                            "${NumberFormatter.formatPrice(priceText)}",
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize:
                                                                    11.5.sp),
                                                          ),
                                                        Text(
                                                          ad.job_name ??
                                                              'No title',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 11.5.sp,
                                                              color:
                                                                  KTextColor),
                                                        ),
                                                        Text(
                                                          '${ad.emirate ?? ''} ${ad.district ?? ''}'
                                                              .trim(),
                                                          style: TextStyle(
                                                              fontSize: 11.5.sp,
                                                              color: const Color
                                                                  .fromRGBO(165,
                                                                  164, 162, 1),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
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
