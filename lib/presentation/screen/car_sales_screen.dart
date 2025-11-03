import 'dart:math';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/data/repository/smart_search_repository.dart';
import 'package:advertising_app/data/model/smart_search_model.dart';
import 'package:advertising_app/presentation/widget/smart_search_card.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'dart:async';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import '../widget/unified_dropdown.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/best_advertiser_adapters.dart';

// تعريف الثوابت
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with FavoritesHelper<HomeScreen> {
  int _selectedIndex = 0;
  bool _showValidationError = false;
  String _validationMessage = "";
  final TextEditingController _smartSearchController = TextEditingController();
  Timer? _smartDebounce;
  late final SmartSearchRepository _smartRepo;
  SmartSearchResponse? _smartSearchResponse;
  List<SmartSearchItem> _suggestions = [];

  // initState merged below

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always refresh data when dependencies change
    _refreshData();
  }

  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CarAdProvider>(context, listen: false);
      provider.fetchMakes();
      provider.fetchTopDealerAds(forceRefresh: true);
    });
  }

  bool _localeIsAr(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');
  }

  @override
  void initState() {
    super.initState();
    // Load existing favorite ids
    loadFavoriteIds();
    _refreshData();
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

  List<CarModel> _getModelsWithAllAndOther(CarAdProvider provider) {
    List<CarModel> modelsWithOptions = [];

    // إضافة خيار "All"
    modelsWithOptions.add(CarModel(id: -1, name: "All", makeId: -1));

    // إضافة النماذج الحقيقية
    modelsWithOptions.addAll(provider.models);

    // إضافة خيار "Other"
    modelsWithOptions.add(CarModel(id: -2, name: "Other", makeId: -2));

    return modelsWithOptions;
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
        S.of(context).otherservices: "/otherServices",
      };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);
    final carAdProvider = context.watch<CarAdProvider>();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark));

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
                                          color:
                                              Color.fromRGBO(129, 126, 126, 1),
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500),
                                      //prefixIcon: Icon(Icons.search,
                                        //  color: borderColor, size: 25.sp),
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
                                              color: borderColor, width: 1.5)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 0.h))))),
                      IconButton(
                          icon: Icon(Icons.notifications_none,
                              color: borderColor, size: 35.sp),
                          onPressed: () {}),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  // Suggestions list below smart search
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
                                '${_localeIsAr(context) ? 'إجمالي الإعلانات' : 'Total Ads'} ${item.totalAds}',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(s.discover_best_cars_deals,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                  color: KTextColor))
                        ]),
                        SizedBox(height: 4.h),
                        UnifiedDropdown<MakeModel>(
                          title: s.choose_make,
                          selectedValue: carAdProvider.selectedMake,
                          items: carAdProvider.makes,
                          onConfirm: (selection) {
                            carAdProvider.updateSelectedMake(selection);
                            setState(() {
                              _showValidationError = false;
                            });
                          },
                          displayNamer: (make) => make.name,
                          isLoading: carAdProvider.isLoadingMakes,
                        ),
                        if (_showValidationError)
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 4.0, left: 10.0),
                              child: Text(_validationMessage,
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12.sp))),
                        SizedBox(height: 3.h),
                        UnifiedDropdown<CarModel>(
                          title: s.choose_model,
                          selectedValue: carAdProvider.selectedModel,
                          items: _getModelsWithAllAndOther(carAdProvider),
                          onConfirm: (selection) {
                            carAdProvider.updateSelectedModel(selection);
                            setState(() {
                              _showValidationError = false;
                            });
                          },
                          displayNamer: (model) => model.name,
                          isLoading: carAdProvider.isLoadingModels,
                        ),
                        SizedBox(height: 4.h),
                        UnifiedSearchButton(
                          onPressed: () {
                            String validation =
                                carAdProvider.getSearchValidationMessage(s);
                            if (validation.isEmpty) {
                              setState(() {
                                _showValidationError = false;
                              });
                              Map<String, String> filters = {};
                              final selectedMake = carAdProvider.selectedMake;
                              final selectedModel = carAdProvider.selectedModel;

                              if (selectedMake != null) {
                                if (selectedMake.id == -2) {
                                  // إذا اختار "Other" في الماركة
                                  filters['make'] = "Other";
                                } else if (selectedMake.id > 0) {
                                  // إذا اختار ماركة حقيقية (ليس "All")
                                  filters['make'] = selectedMake.name;

                                  // إضافة الموديل فقط إذا لم يكن "All" أو null
                                  if (selectedModel != null &&
                                      selectedModel.id != -1 && // ليس "All"
                                      selectedModel.name != "All") {
                                    filters['model'] = selectedModel.name;
                                  }
                                  // إذا كان الموديل "All" أو null، لا نضيف فلتر الموديل
                                  // وبالتالي سيظهر جميع موديلات الماركة المختارة
                                }
                              }
                              context.push('/cars-sales',
                                  extra: filters.isEmpty ? null : filters);
                            } else {
                              setState(() {
                                _validationMessage = validation;
                                _showValidationError = true;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 5.h),
                        Padding(
                          padding:
                              EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                          child: GestureDetector(
                            onTap: () => context.push('/offer_box'),
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
                                  SvgPicture.asset('assets/icons/cardolar.svg',
                                      height: 25.sp, width: 24.sp),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                      child: Text(
                                          s.click_for_amazing_daily_cars_deals,
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
                        SizedBox(height: 10.h),
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
                        _buildTopDealersSection(carAdProvider),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildTopDealersSection(CarAdProvider provider) {
    final s = S.of(context);
    if (provider.isLoadingTopDealers && provider.topDealerAds.isEmpty)
      return const Center(heightFactor: 5, child: CircularProgressIndicator());

    if (provider.topDealersError != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(provider.topDealersError!)));
    }

    final dealersWithAds =
        provider.topDealerAds.where((dealer) => dealer.ads.isNotEmpty).toList();
    if (dealersWithAds.isEmpty) return const SizedBox.shrink();

    return Column(
      children: dealersWithAds.map((dealer) {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                // ننتقل إلى صفحة تفاصيل السيارة باستخدام الـ ID
                //     context.push('/car-details/$dealer.id}');
              },
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                    horizontal: 16.w, vertical: 8.h),
                child: Row(children: [
                  Text(dealer.name,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: KTextColor)),
                  const Spacer(),
                  InkWell(
                      onTap: () {
                        // تمرير معرف المعلن عند النقر على "عرض كل الإعلانات"
                        final advertiserId = dealer.id.toString();
                        debugPrint(
                            'Navigating to all ads with advertiser ID: $advertiserId');
                        context.push('/all_ad_car_sales/$advertiserId');
                      },
                      child: Text(s.see_all_ads,
                          style: TextStyle(
                              fontSize: 14.sp,
                              decoration: TextDecoration.underline,
                              decorationColor: borderColor,
                              color: borderColor,
                              fontWeight: FontWeight.w500))),
                ]),
              ),
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dealer.ads.length,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                itemBuilder: (context, index) {
                  final car = dealer.ads[index];
                  final cardTitle =
                      "${car.make} ${car.model} ${car.trim ?? ''}".trim();
                  return GestureDetector(
                    onTap: () => context.push('/car-details/${car.id}'),
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: 4),
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
                          children: [
                            Stack(children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: CachedNetworkImage(
                                    imageUrl: ImageUrlHelper.getFullImageUrl(
                                        car.mainImage),
                                    height: (94).h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))),
                                    errorWidget: (context, url, error) =>
                                        Image.asset('assets/images/car.jpg',
                                            fit: BoxFit.cover),
                                  )),

                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: buildFavoriteIcon(
                                      BestAdvertiserCarSalesItemAdapter(car),
                                      onAddToFavorite: () {},
                                    ),
                                  ),
                            ]),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                        "${NumberFormatter.formatPrice(car.price)} ",
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11.5.sp)),
                                    Text(cardTitle,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11.5.sp,
                                            color: KTextColor),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    Row(
                                      children: [
                                        Text(car.year,
                                            style: TextStyle(
                                                fontSize: 11.5.sp,
                                                color: const Color.fromRGBO(
                                                    165, 164, 162, 1),
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(width: 8.w),
                                        Text(
                                            "${NumberFormatter.formatKilometers(car.km)}",
                                            style: TextStyle(
                                                fontSize: 11.5.sp,
                                                color: const Color.fromRGBO(
                                                    165, 164, 162, 1),
                                                fontWeight: FontWeight.w600)),
                                      ],
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
  }
}
