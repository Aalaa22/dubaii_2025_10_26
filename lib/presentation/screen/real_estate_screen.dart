// lib/presentation/screens/real_estate_screen.dart

import 'dart:math';
import 'package:advertising_app/data/real_estate_dummy_data.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:advertising_app/presentation/widget/unified_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/presentation/providers/real_estate_info_provider.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/best_advertiser_adapters.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key});

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> with FavoritesHelper<RealEstateScreen> {
  int _selectedIndex = 1;

  String? _selectedEmirate;
  String? _selectedDistrict;
  String? _selectedPropertyType;
  String? _selectedContractType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load favorites cache
      await loadFavoriteIds();
      // الاعتماد حصراً على auth_token (قد يكون null لبعض الـ APIs العامة)
      final storage = const FlutterSecureStorage();
      final authToken = await storage.read(key: 'auth_token');

      if (mounted) {
        // اجلب البيانات حتى لو لم يوجد توكن (بعض الـ APIs عامة)
        context.read<RealEstateInfoProvider>().fetchAllData(token: authToken);
      }
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

  List<String> _getDistrictsForSelectedEmirates() {
    final infoProvider = context.read<RealEstateInfoProvider>();
    List<String> districts = [];

    if (_selectedEmirate != null && _selectedEmirate != 'All') {
      districts.addAll(infoProvider.getDistrictsForEmirate(_selectedEmirate));
    } else if (_selectedEmirate == 'All') {
      // If 'All' is selected for emirate, show all districts from all emirates
      for (var emirateName in infoProvider.emirateDisplayNames) {
        districts.addAll(infoProvider.getDistrictsForEmirate(emirateName));
      }
      districts = districts.toSet().toList(); // Remove duplicates
    }

    // Add fallback dummy data if API data is empty
    if (districts.isEmpty) {
      districts = [
        'Dubai Marina',
        'Downtown Dubai',
        'Business Bay',
        'JBR',
        'Palm Jumeirah'
      ];
    }

    return districts;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: CustomBottomNav(currentIndex: 0),
          body: Consumer<RealEstateInfoProvider>(
            // ++ Use Consumer to get data
            builder: (context, infoProvider, child) {
              // Get districts based on selected emirate
              List<String> availableDistricts = ['All'];
              if (_selectedEmirate != null && _selectedEmirate != 'All') {
                availableDistricts.addAll(
                    infoProvider.getDistrictsForEmirate(_selectedEmirate));
              } else if (_selectedEmirate == 'All') {
                // If 'All' is selected for emirate, show all districts from all emirates
                for (var emirateName in infoProvider.emirateDisplayNames) {
                  availableDistricts
                      .addAll(infoProvider.getDistrictsForEmirate(emirateName));
                }
                availableDistricts =
                    availableDistricts.toSet().toList(); // Remove duplicates
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                      child: Row(
                        children: [
                          Expanded(
                              child: SizedBox(
                                  height: 35.h,
                                  child: TextField(
                                      decoration: InputDecoration(
                                          hintText: s.smart_search,
                                          hintStyle: TextStyle(
                                              color: const Color.fromRGBO(
                                                  129, 126, 126, 1),
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500),
                                          prefixIcon: Icon(Icons.search,
                                              color: borderColor, size: 25.sp),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              borderSide: BorderSide(
                                                  color: borderColor)),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              borderSide: BorderSide(
                                                  color: borderColor,
                                                  width: 1.5)),
                                          filled: true,
                                          fillColor: Colors.white,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0.h))))),
                          IconButton(
                              icon: Icon(Icons.notifications_none,
                                  color: borderColor, size: 35.sp),
                              onPressed: () {})
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                      child: CustomCategoryGrid(
                          categories: categories,
                          selectedIndex: _selectedIndex,
                          onTap: (index) =>
                              setState(() => _selectedIndex = index),
                          onCategoryPressed: (selectedCategory) {
                            final route = categoryRoutes[selectedCategory];
                            if (route != null) context.push(route);
                          }),
                    ),
                    SizedBox(height: 2.h),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                      child: Column(
                        children: [
                          Row(children: [
                            Icon(Icons.star, color: Colors.amber, size: 20.sp),
                            SizedBox(width: 6.w),
                            Text(s.discover_real_estate,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp,
                                    color: KTextColor))
                          ]),
                          SizedBox(height: 10.h),
                          UnifiedDropdown<String>(
                            title: s.emirate,
                            selectedValue: _selectedEmirate,
                            items: ['All', ...infoProvider.emirateDisplayNames],
                            onConfirm: (selection) => setState(() {
                              _selectedEmirate = selection;
                              _selectedDistrict =
                                  null; // Clear district when emirate changes
                            }),
                            isLoading: infoProvider.isLoading,
                          ),
                          SizedBox(height: 3.h),
                          UnifiedDropdown<String>(
                            title: s.district,
                            selectedValue: _selectedDistrict,
                            items: availableDistricts,
                            onConfirm: (selection) =>
                                setState(() => _selectedDistrict = selection),
                            isLoading: infoProvider.isLoading,
                          ),
                          SizedBox(height: 4.h),
                          UnifiedDropdown<String>(
                            title: s.property_type,
                            selectedValue: _selectedPropertyType,
                            items: ['All', ...infoProvider.propertyTypes],
                            onConfirm: (selection) => setState(
                                () => _selectedPropertyType = selection),
                            isLoading: infoProvider.isLoading,
                          ),
                          SizedBox(height: 3.h),
                          UnifiedDropdown<String>(
                            title: s.contract_type,
                            selectedValue: _selectedContractType,
                            items: ['All', ...infoProvider.contractTypes],
                            onConfirm: (selection) => setState(
                                () => _selectedContractType = selection),
                            isLoading: infoProvider.isLoading,
                          ),
                          SizedBox(height: 4.h),
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
                            child: UnifiedSearchButton(
                              text: s.search,
                              onPressed: () {
                                // Validation: Check if all fields are selected
                                if (_selectedEmirate == null ||
                                    _selectedDistrict == null ||
                                    _selectedPropertyType == null ||
                                    _selectedContractType == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "please_select_all_fields" ??
                                              'Please select all fields'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final filters = {
                                  'emirate': _selectedEmirate!,
                                  'district': _selectedDistrict!,
                                  'propertyType': _selectedPropertyType!,
                                  'contractType': _selectedContractType!,
                                };

                                // Clear selections after navigation
                                setState(() {
                                  _selectedEmirate = null;
                                  _selectedDistrict = null;
                                  _selectedPropertyType = null;
                                  _selectedContractType = null;
                                });

                                context.push('/real_estate_search',
                                    extra: filters);
                              },
                            ),
                          ),
                          SizedBox(height: 7.h),
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
                            child: GestureDetector(
                              onTap: () => context.push('/realestateofeerbox'),
                              child: Container(
                                  padding: EdgeInsetsDirectional.symmetric(
                                      horizontal: 8.w),
                                  height: 68.h,
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFFE4F8F6),
                                        Color(0xFFC9F8FE)
                                      ]),
                                      borderRadius: BorderRadius.circular(8.r)),
                                  child: Row(children: [
                                    SvgPicture.asset('assets/icons/home.svg',
                                        colorFilter: const ColorFilter.mode(
                                            KTextColor, BlendMode.srcIn),
                                        height: 18.sp,
                                        width: 18.sp),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                        child: Text(
                                            s.click_for_deals_real_estate,
                                            style: TextStyle(
                                                fontSize: 13.sp,
                                                color: KTextColor,
                                                fontWeight: FontWeight.w500))),
                                    SizedBox(width: 12.w),
                                    Icon(Icons.arrow_forward_ios,
                                        size: 22.sp, color: KTextColor)
                                  ])),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Row(children: [
                            SizedBox(width: 4.w),
                            Icon(Icons.star, color: Colors.amber, size: 20.sp),
                            SizedBox(width: 4.w),
                            Text(s.top_premium_dealers,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp,
                                    color: KTextColor))
                          ]),
                          SizedBox(height: 1.h),
                          // Real API Data Section
                          _buildBestAdvertisersSection(infoProvider, s),
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

  // Real API data widget for best advertisers
  Widget _buildBestAdvertisersSection(
      RealEstateInfoProvider infoProvider, S s) {
    final infoProvider = context.watch<RealEstateInfoProvider>();

    print('🏢 Building best advertisers section...');
    print('📊 Total advertisers: ${infoProvider.bestAdvertisers.length}');

    if (infoProvider.isLoadingBestAdvertisers) {
      print('⏳ Loading best advertisers...');
      return const Center(child: CircularProgressIndicator());
    }

    // Robust error handling: show clear panel when fetch fails and no data
    if (infoProvider.bestAdvertisersError != null &&
        infoProvider.bestAdvertisers.isEmpty) {
      if (kDebugMode) {
        debugPrint('BestAdvertisers error: '+ (infoProvider.bestAdvertisersError ?? 'unknown'));
        debugPrint('isLoading: '+ infoProvider.isLoadingBestAdvertisers.toString());
        debugPrint('count: '+ infoProvider.bestAdvertisers.length.toString());
      }
      final errorMessage = infoProvider.bestAdvertisersError ?? 'سبب غير معروف';
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        child: Card(
          color: const Color(0xFFFFF3F3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: BorderSide(color: Colors.red.shade300),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'تعذر تحميل أفضل المعلنين',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'السبب: '+ errorMessage,
                  style: TextStyle(fontSize: 13.sp, color: KTextColor),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await context
                            .read<RealEstateInfoProvider>()
                            .fetchBestAdvertisers(forceRefresh: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت محاولة إعادة التحميل')),
                        );
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                    SizedBox(width: 8.w),
                    OutlinedButton(
                      onPressed: () async {
                        final diag = 'isLoading='+ infoProvider.isLoadingBestAdvertisers.toString() +', count='+ infoProvider.bestAdvertisers.length.toString() +', error='+ (infoProvider.bestAdvertisersError ?? 'null');
                        await Clipboard.setData(ClipboardData(text: diag));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ التفاصيل')),
                        );
                      },
                      child: const Text('نسخ التفاصيل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (infoProvider.bestAdvertisers.isEmpty) {
      print('❌ No best advertisers found');
      return const SizedBox.shrink();
    }

    return Column(
      children: infoProvider.bestAdvertisers.map((advertiser) {
        print('🏢 Processing advertiser: ${advertiser.name}');
        print('📊 Total ads for ${advertiser.name}: ${advertiser.ads.length}');

        // Filter ads for real estate category (normalized variants)
        final realEstateAds = advertiser.ads.where((ad) {
          final raw = ad.category?.toLowerCase().trim();
          final normalized = (raw ?? '').replaceAll(RegExp(r'[\s_-]'), '');
          final isRealEstateNormalized = normalized == 'realestate' || normalized == 'realstate';
          final hasRealEstateFields = (ad.propertyType?.isNotEmpty == true) || (ad.contractType?.isNotEmpty == true);
          final isRealEstate = isRealEstateNormalized || hasRealEstateFields;
          print('🏷️ Ad "${ad.title}" raw category: "$raw" -> normalized: "$normalized"');
          print('✅ Is real estate: $isRealEstate');
          return isRealEstate;
        }).toList();

        print(
            '🏠 Real estate ads for ${advertiser.name}: ${realEstateAds.length}');

        if (realEstateAds.isEmpty) {
          print('❌ No real estate ads for ${advertiser.name}');
          return const SizedBox.shrink();
        }

        print(
            '✅ Showing ${realEstateAds.length} real estate ads for ${advertiser.name}');
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    advertiser.name.isNotEmpty
                        ? advertiser.name
                        : "Top Real Estate Dealer",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: KTextColor,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      // تمرير معرف المعلن عند النقر على "عرض كل الإعلانات"
                      final advertiserId = advertiser.id.toString();
                      debugPrint('Navigating to all ads for advertiser ID: $advertiserId');
                      context.push("/all_ad_car_sales/$advertiserId");
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
                itemCount: realEstateAds.length,
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                itemBuilder: (context, index) {
                  final ad = realEstateAds[index];
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: 4.w),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to real estate details screen with the ad ID
                        context.push('/real-details/${ad.id}');
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
                              offset: const Offset(0, 2),
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
                                    child: ad.mainImage.isNotEmpty
                                        ? Image.network(
                                            'https://dubaisale.app/storage/${ad.mainImage}',
                                            height: 94.h,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                height: 94.h,
                                                width: double.infinity,
                                                color: Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 40.sp,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            height: 94.h,
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                              size: 40.sp,
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: buildFavoriteIcon(
                                      BestAdvertiserRealEstateItemAdapter(ad),
                                      onAddToFavorite: () {},
                                      onRemoveFromFavorite: null,
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 6.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        '${NumberFormatter.formatPrice(ad.price)} ',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5.sp,
                                        ),
                                      ),
                                      Text(
                                        "${ad.propertyType}  ${ad.contractType}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5.sp,
                                          color: KTextColor,
                                        ),
                                      ),
                                      Text(
                                        '${ad.emirate ?? ''} ${ad.district ?? ''}'
                                            .trim(),
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          color: const Color.fromRGBO(
                                              165, 164, 162, 1),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
            SizedBox(height: 8.h),
          ],
        );
      }).toList(),
    );
  }

  // Dummy data widget as requested (kept for reference)
  Widget _buildTopDealersSectionDummy(S s) {
    return Column(
      children: List.generate(3, (sectionIndex) {
        return Column(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dubai Investment",
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: KTextColor)),
                      const Spacer(),
                      InkWell(
                          onTap: () {
                             context.push("/all_ad_car_sales");
                          },
                          child: Text(s.see_all_ads,
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  decoration: TextDecoration.underline,
                                  decorationColor: borderColor,
                                  color: borderColor,
                                  fontWeight: FontWeight.w500)))
                    ])),
            SizedBox(
              height: 175,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: min(RealEstateDummyData.length, 20),
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                itemBuilder: (context, index) {
                  final ad = RealEstateDummyData[index];
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: 4.w),
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
                                offset: const Offset(0, 2))
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(4.r),
                                child: Image.asset(ad.image,
                                    height: 94.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover)),
                            const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.favorite_border,
                                    color: Colors.grey))
                          ]),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(ad.price,
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5.sp)),
                                  Text(ad.propertyType ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5.sp,
                                          color: KTextColor)),
                                  Text(ad.location,
                                      style: TextStyle(
                                          fontSize: 11.5.sp,
                                          color: const Color.fromRGBO(
                                              165, 164, 162, 1),
                                          fontWeight: FontWeight.w600)),
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
      }),
    );
  }
}

// Helper method to format price with commas
String _formatPrice(String price) {
  // Remove any existing punctuation and non-numeric characters except digits
  String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');

  if (cleanPrice.isEmpty) return price;

  // Convert to integer and format with commas
  int priceInt = int.tryParse(cleanPrice) ?? 0;
  String formattedPrice = priceInt.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );

  return formattedPrice;
}
