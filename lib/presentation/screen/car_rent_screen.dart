// lib/presentation/screens/car_rent_screen.dart

import 'dart:math';

import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:advertising_app/presentation/widget/unified_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/data/car_rent_dummy_data.dart'; // For dummy data
import 'package:advertising_app/presentation/providers/car_rent_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'dart:async';
import 'package:advertising_app/data/repository/smart_search_repository.dart';
import 'package:advertising_app/data/model/smart_search_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class BestAdvertiserCarRentItemAdapter implements FavoriteItemInterface {
  final BestAdvertiserAd _ad;
  BestAdvertiserCarRentItemAdapter(this._ad);

  @override
  String get contact => _ad.advertiserName;

  @override
  String get details => _ad.title ?? '';

  @override
  List<String> get images => [
        ImageUrlHelper.getMainImageUrl(_ad.mainImage),
        ..._ad.images
      ].where((img) => img.isNotEmpty).toList();

  @override
  String get line1 =>
      'Day Rent: ${_ad.dayRent ?? ''}  Month Rent: ${_ad.monthRent ?? ''}'.trim();

  @override
  String get price => _ad.price;

  @override
  String get location =>
      '${_ad.emirate ?? ''} ${_ad.district ?? ''} ${_ad.area ?? ''}'.trim();

  @override
  String get title =>
      '${_ad.make} ${_ad.model} ${_ad.trim ?? ''} ${_ad.year}'.trim();

  @override
  String get date => '';

  @override
  bool get isPremium => false;

  @override
  AdPriority get priority => AdPriority.free;

  @override
  int get id => _ad.id;

  @override
  String get category => 'Car Rent';

  @override
  String get addCategory => 'Car Rent';
}

class CarRentScreen extends StatefulWidget {
  const CarRentScreen({super.key});

  @override
  State<CarRentScreen> createState() => _CarRentScreenState();
}

class _CarRentScreenState extends State<CarRentScreen> with FavoritesHelper {
  int _selectedIndex = 4;

  String? _selectedMake;
  String? _selectedModel;

  // Smart search state (same pattern as CarSales)
  final TextEditingController _smartSearchController = TextEditingController();
  Timer? _smartDebounce;
  late final SmartSearchRepository _smartRepo;
  SmartSearchResponse? _smartSearchResponse;
  List<SmartSearchItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Ensure favorite IDs are loaded so icons reflect saved favorites
    loadFavoriteIds();
    // Initialize smart search repository and listener
    _smartRepo = SmartSearchRepository(ApiService());
    _smartSearchController.addListener(_onSmartSearchChanged);
    // Use addPostFrameCallback to safely call provider after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final info = context.read<CarRentInfoProvider>();
      // Public GET requests: no token required
      info.fetchAllData();
      info.fetchTopDealerAds();
      info.fetchBestAdvertiserAds();
    });
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
            // ++ Wrap the body with Consumer to listen to changes in CarRentInfoProvider
            body: Consumer<CarRentInfoProvider>(
                builder: (context, infoProvider, child) {
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
                                      textAlign: TextAlign.start,
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
                        ])),
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
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: min(180.h, (_suggestions.length * 48.h)),
                                child: ListView.separated(
                                  itemCount: _suggestions.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withOpacity(0.4)),
                                  itemBuilder: (context, index) {
                                    final item = _suggestions[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.search, color: KPrimaryColor, size: 18.sp),
                                      title: Text(
                                        '${S.of(context).category} ${item.itemType}',
                                        style: TextStyle(color: KTextColor, fontSize: 13.sp, fontWeight: FontWeight.w500),
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
                            ],
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
                          setState(() => _selectedIndex = index);
                        },
                        onCategoryPressed: (selectedCategory) {
                          final route = categoryRoutes[selectedCategory];
                          if (route != null) context.push(route);
                        },
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                      child: Column(
                        children: [
                          Row(children: [
                            Icon(Icons.star, color: Colors.amber, size: 20.sp),
                            SizedBox(width: 6.w),
                            Text(s.discover_deals,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp,
                                    color: KTextColor))
                          ]),
                          SizedBox(height: 4.h),
                          // ++ Use data from infoProvider and show loading state
                          UnifiedDropdown<String>(
                            title: s.choose_make,
                            selectedValue: _selectedMake,
                            items: infoProvider.makeNames,
                            isLoading: infoProvider.isLoading,
                            onConfirm: (selection) async {
                              setState(() {
                                _selectedMake = selection;
                                _selectedModel = null; // Reset model when make changes
                              });

                              // Fetch models for the selected make
                              if (selection != null) {
                                try {
                                  if (selection == 'All') {
                                    // Fetch all models when "All" is selected
                                    await infoProvider.fetchAllModels();
                                  } else {
                                    final makeObject = infoProvider.makes
                                        .firstWhere((m) => m.name == selection);
                                    await infoProvider.fetchModelsForMake(makeObject);
                                  }
                                } catch (e) {
                                  debugPrint("Make object not found for $selection");
                                }
                              }
                            },
                          ),
                          SizedBox(height: 3.h),
                          // ++ Use data from infoProvider and show loading state
                          UnifiedDropdown<String>(
                            title: s.choose_model,
                            selectedValue: _selectedModel,
                            items: infoProvider.modelNames, // Model list will be empty until a make is chosen and data is fetched
                            isLoading: infoProvider.isLoading,
                            onConfirm: (selection) => setState(() => _selectedModel = selection),
                          ),
                          SizedBox(height: 4.h),
                          UnifiedSearchButton(
                            onPressed: () {
                              // Validation: Check if make is selected (but allow "All")
                              if (_selectedMake == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.please_select_make ??
                                        s.please_select_model ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              // Pass filters to the search screen
                              final filters = <String, dynamic>{};

                              // If make is selected and not "All", add make filter
                              if (_selectedMake != null &&
                                  _selectedMake != 'All') {
                                filters['make'] = _selectedMake;
                              }

                              // If model is selected and not "All", add model filter
                              if (_selectedModel != null &&
                                  _selectedModel != 'All') {
                                filters['model'] = _selectedModel;
                              }

                              context.push('/car_rent_search',
                                  extra: filters);

                              setState(() {
                                _selectedMake = null;
                                _selectedModel = null;
                              });
                            },
                          ),
                          SizedBox(height: 7.h),
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
                            child: GestureDetector(
                              onTap: () => context.push('/carrentofferbox'),
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
                                    SvgPicture.asset(
                                        'assets/icons/cardolar.svg',
                                        height: 25.sp,
                                        width: 24.sp),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                        child: Text(s.click_for_deals,
                                            textAlign: TextAlign.start,
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
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp,
                                    color: KTextColor))
                          ]),
                          SizedBox(height: 1.h),
                          // ++ Section for top dealers using real data
                          // _buildTopDealersSection(infoProvider, s),
                          // SizedBox(height: 8.h),
                          // ++ Section for best advertisers using real data
                          _buildBestAdvertisersSection(infoProvider, s),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ));
  }

  // This widget uses real top dealers data from the provider
  Widget _buildTopDealersSection(CarRentInfoProvider infoProvider, S s) {
    if (infoProvider.isLoadingTopDealers) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: CircularProgressIndicator(color: KPrimaryColor),
        ),
      );
    }

    if (infoProvider.topDealersError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: Text(
            'Error loading top dealers: ${infoProvider.topDealersError}',
            style: TextStyle(color: Colors.red, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (infoProvider.topDealerAds.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: Text(
            'No top dealers available',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoProvider.topDealerAds.map((dealer) {
        return Column(children: [
          Padding(
            padding:
                EdgeInsetsDirectional.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dealer.name,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: KTextColor,
                  ),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    context.push("/all_ad_car_sales");
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
              itemCount: min(dealer.ads.length, 15),
              padding: EdgeInsetsDirectional.symmetric(horizontal: 5.w),
              itemBuilder: (context, index) {
                final ad = dealer.ads[index];
                return Padding(
                    padding: EdgeInsetsDirectional.only(end: 4.w),
                    child: GestureDetector(
                      onTap: () {
                        context.push('/car_rent_details_screen', extra: ad);
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
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: CachedNetworkImage(
                                    imageUrl: ImageUrlHelper.getMainImageUrl(
                                        ad.mainImage ?? ''),
                                    height: 94.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) {
                                      print(
                                          '🖼️ CachedNetworkImage - Loading image: $url');
                                      return Container(
                                        height: 94.h,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: KPrimaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                    errorWidget: (context, url, error) {
                                      print(
                                          '❌ CachedNetworkImage ERROR - URL: $url');
                                      print(
                                          '❌ CachedNetworkImage ERROR - Error: $error');
                                      print(
                                          '❌ CachedNetworkImage ERROR - Raw mainImage: ${ad.mainImage}');
                                      return Image.asset(
                                          'assets/images/Audi S5 TSFIjpeg.jpeg',
                                          fit: BoxFit.cover);
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: buildFavoriteIcon(
                                    BestAdvertiserCarRentItemAdapter(ad),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '${NumberFormatter.formatPrice(ad.price)} ?? N/A',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5.sp,
                                      ),
                                    ),
                                    Text(
                                      "${ad.make} ${ad.model} ${ad.trim}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5.sp,
                                        color: KTextColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "${ad.year ?? 'N/A'}",
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            color: const Color.fromRGBO(
                                                165, 164, 162, 1),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          "${ad.emirate} ",
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            color: const Color.fromRGBO(
                                                165, 164, 162, 1),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ));
              },
            ),
          ),
        ]);
      }).toList(),
    );
  }

  // This widget uses real best advertisers data from the provider
  Widget _buildBestAdvertisersSection(CarRentInfoProvider infoProvider, S s) {
    if (infoProvider.isLoadingBestAdvertisers) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: CircularProgressIndicator(color: KPrimaryColor),
        ),
      );
    }

    if (infoProvider.bestAdvertisersError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: Text(
            'Error loading best advertisers: ${infoProvider.bestAdvertisersError}',
            style: TextStyle(color: Colors.red, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (infoProvider.bestAdvertiserAds.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: Text(
            'No best advertisers available',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoProvider.bestAdvertiserAds
          .map((advertiser) {
            // فلترة الإعلانات للحصول على إعلانات car_rent فقط
            final carRentAds = advertiser.ads.where((ad) {
              final category = ad.category?.toLowerCase();
              return category == 'car_rent' ||
                  category == 'carrent' ||
                  category == 'car rent';
            }).toList();

            if (carRentAds.isEmpty) return SizedBox.shrink();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 8.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        advertiser.name,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: KTextColor,
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: () {
                           final advertiserId = advertiser.id.toString();
                        debugPrint('Navigating to all ads with advertiser ID: $advertiserId');
                        context.push('/all_ad_car_sales/$advertiserId');
                    
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
                    itemCount: min(carRentAds.length, 15),
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 5.w),
                    itemBuilder: (context, index) {
                      final ad = carRentAds[index];

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
                                offset: Offset(0, 2.h),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: CachedNetworkImage(
                                      imageUrl: ImageUrlHelper.getMainImageUrl(
                                          ad.mainImage ?? ''),
                                      height: 94.h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) {
                                        print(
                                            '🖼️ CachedNetworkImage - Loading image: $url');
                                        return Container(
                                          height: 94.h,
                                          width: double.infinity,
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: KPrimaryColor,
                                            ),
                                          ),
                                        );
                                      },
                                      errorWidget: (context, url, error) {
                                        print(
                                            '❌ CachedNetworkImage ERROR - URL: $url');
                                        print(
                                            '❌ CachedNetworkImage ERROR - Error: $error');
                                        print(
                                            '❌ CachedNetworkImage ERROR - Raw mainImage: ${ad.mainImage}');
                                        return Image.asset(
                                            'assets/images/Audi S5 TSFIjpeg.jpeg',
                                            fit: BoxFit.cover);
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                  child: buildFavoriteIcon(
                                    BestAdvertiserCarRentItemAdapter(ad),
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
                                        "${NumberFormatter.formatPrice(ad.price)}",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5.sp,
                                        ),
                                      ),
                                      Text(
                                        "${ad?.make ?? ''} ${ad?.model ?? ''} ${ad?.trim ?? ''}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5.sp,
                                          color: KTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "${ad?.year ?? 'N/A'}",
                                            style: TextStyle(
                                              fontSize: 11.5.sp,
                                              color: const Color.fromRGBO(
                                                  165, 164, 162, 1),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            "${ad?.emirate ?? ''} ",
                                            style: TextStyle(
                                              fontSize: 11.5.sp,
                                              color: const Color.fromRGBO(
                                                  165, 164, 162, 1),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
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
                )
              ],
            );
          })
          .where((widget) => widget is! SizedBox)
          .toList(),
    );
  }
}
