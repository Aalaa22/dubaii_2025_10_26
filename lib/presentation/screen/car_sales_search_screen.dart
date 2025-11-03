import 'dart:async';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/car_ad_model.dart';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/data/web_services/location_service.dart';
// import 'package:geolocator/geolocator.dart'; // Temporarily disabled
import 'package:geocoding/geocoding.dart';

import 'package:advertising_app/utils/phone_number_formatter.dart';

// تعريف الثوابت
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = const Color.fromRGBO(8, 194, 201, 1);

class CarSalesScreen extends StatefulWidget {
  final Map<String, String>? initialFilters;
  const CarSalesScreen({super.key, this.initialFilters});

  @override
  State<CarSalesScreen> createState() => _CarSalesScreenState();
}

class _CarSalesScreenState extends State<CarSalesScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingFilterBar = false;
  double _lastScrollOffset = 0.0;
  Timer? _debounce;
  bool _isMapSortActive = false;
  final LocationService _locationService = LocationService();
  // Position? _currentPosition; // Temporarily disabled
  bool _isGettingLocation = false;
  // Map<String, Position> _adLocationCache = {}; // Temporarily disabled

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CarAdProvider>()
          .applyAndFetchAds(initialFilters: widget.initialFilters);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleScroll() {
    final currentOffset = _scrollController.offset;
    if (currentOffset <= 200) {
      if (_showFloatingFilterBar)
        setState(() => _showFloatingFilterBar = false);
      _lastScrollOffset = currentOffset;
      return;
    }
    if (currentOffset < _lastScrollOffset - 50) {
      if (!_showFloatingFilterBar)
        setState(() => _showFloatingFilterBar = true);
    } else if (currentOffset > _lastScrollOffset + 10) {
      if (_showFloatingFilterBar)
        setState(() => _showFloatingFilterBar = false);
    }
    _lastScrollOffset = currentOffset;
  }

  void _applyAndSearchWithDebounce() {
    final provider = context.read<CarAdProvider>();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      provider.applyAndFetchAds();
    });
  }

  // Future<void> _launchUrl(String urlString) async {
  //   final Uri url = Uri.parse(urlString);
  //   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Could not launch $urlString')),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark));
    final s = S.of(context);

    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            // مسح جميع الفلاتر قبل الرجوع
            context.read<CarAdProvider>().clearAllFilters();
            context.pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Consumer<CarAdProvider>(
              builder: (context, provider, child) {
                // ترتيب الإعلانات من الأحدث للأقدم
                final allAds = List<CarAdModel>.from(provider.carAds);
                allAds.sort((a, b) {
                  if (a.createdAt == null && b.createdAt == null) return 0;
                  if (a.createdAt == null) return 1;
                  if (b.createdAt == null) return -1;
                  return DateTime.parse(b.createdAt!)
                      .compareTo(DateTime.parse(a.createdAt!));
                });
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async => provider.applyAndFetchAds(
                          initialFilters: widget.initialFilters),
                      child: SingleChildScrollView(
                        key: const PageStorageKey('car_sales_scroll'),
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
                                      context
                                          .read<CarAdProvider>()
                                          .clearAllFilters();
                                      context.pop();
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_back_ios,
                                            color: KTextColor, size: 17.sp),
                                        Transform.translate(
                                          offset: Offset(-3.w, 0),
                                          child: Text(s.back,
                                              style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: KTextColor)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Center(
                                    child: Text(
                                      s.carsales,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 24.sp,
                                        color: KTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18.w),
                              child: _buildFiltersRow(s, provider),
                            ),
                            SizedBox(height: 4.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18.w),
                              child: _buildSortBar(s, allAds.length),
                            ),
                            SizedBox(height: 5.h),
                            // تقسيم الإعلانات حسب الأولوية
                            ...(() {
                              final premiumStarAds = allAds
                                  .where((ad) =>
                                      AdCardItemAdapter(ad).priority ==
                                      AdPriority.PremiumStar)
                                  .toList();
                              final premiumAds = allAds
                                  .where((ad) =>
                                      AdCardItemAdapter(ad).priority ==
                                      AdPriority.premium)
                                  .toList();
                              final featuredAds = allAds
                                  .where((ad) =>
                                      AdCardItemAdapter(ad).priority ==
                                      AdPriority.featured)
                                  .toList();
                              final freeAds = allAds
                                  .where((ad) =>
                                      AdCardItemAdapter(ad).priority ==
                                      AdPriority.free)
                                  .toList();

                              List<Widget> widgets = [];

                              if (premiumStarAds.isNotEmpty) {
                                widgets.add(_buildSectionTitle(
                                    s.priority_first_premium));
                                widgets.addAll(
                                    premiumStarAds.map(_buildCard).toList());
                              }

                              if (premiumAds.isNotEmpty) {
                                widgets.add(
                                    _buildSectionTitle(s.priority_premium));
                                widgets.addAll(
                                    premiumAds.map(_buildCard).toList());
                              }

                              if (featuredAds.isNotEmpty) {
                                widgets.add(
                                    _buildSectionTitle(s.priority_featured));
                                widgets.addAll(
                                    featuredAds.map(_buildCard).toList());
                              }

                              if (freeAds.isNotEmpty) {
                                widgets
                                    .add(_buildSectionTitle(s.priority_free));
                                widgets
                                    .addAll(freeAds.map(_buildCard).toList());
                              }

                              return widgets;
                            })(),
                            if (provider.isLoadingAds && allAds.isEmpty)
                              const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              )),
                            if (provider.loadAdsError != null && allAds.isEmpty)
                              Center(
                                  child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text("Error: ${provider.loadAdsError}"),
                              )),
                            if (allAds.isEmpty &&
                                !provider.isLoadingAds &&
                                provider.loadAdsError == null)
                              Center(
                                  child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text("No ads found."),
                              )),
                          ],
                        ),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 18.w, vertical: 10.h),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300))),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // مسح جميع الفلاتر قبل الرجوع
                                  context
                                      .read<CarAdProvider>()
                                      .clearAllFilters();
                                  context.pop();
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_back_ios,
                                        color: KTextColor, size: 17.sp),
                                    Transform.translate(
                                      offset: Offset(-3.w, 0),
                                      child: Text(s.back,
                                          style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                              color: KTextColor)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              _buildFiltersRow(s, provider),
                              SizedBox(height: 4.h),
                              _buildSortBar(s, allAds.length),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ));
  }

  Widget _buildSortBar(S s, int totalAds) {
    bool isSmallScreen = MediaQuery.of(context).size.width <= 370;
    return Row(
      children: [
        Text('${S.of(context).ad} $totalAds',
            style: TextStyle(
                fontSize: 12.sp,
                color: KTextColor,
                fontWeight: FontWeight.w400)),
        SizedBox(width: isSmallScreen ? 35.w : 30.w),
        Expanded(
          child: Container(
            height: 37.h,
            padding: EdgeInsetsDirectional.symmetric(
                horizontal: isSmallScreen ? 8.w : 12.w),
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF08C2C9)),
                borderRadius: BorderRadius.circular(8.r)),
            child: Row(
              children: [
                SvgPicture.asset('assets/icons/locationicon.svg',
                    width: 18.w, height: 18.h),
                SizedBox(width: isSmallScreen ? 12.w : 15.w),
                Expanded(
                    child: Text(s.sort,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: KTextColor,
                            fontSize: 12.sp))),
                SizedBox(
                  width: isSmallScreen ? 35.w : 32.w,
                  child: Transform.scale(
                    scale: isSmallScreen ? 0.8 : .9,
                    child: Switch(
                        value: _isMapSortActive,
                        onChanged: (val) =>
                            setState(() => _isMapSortActive = val),
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF08C2C9),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // +++ دالة فتح الروابط +++
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  // Widget _buildCard(CarAdModel item) {
  //   return GestureDetector(
  //     onTap: () => context.push('/car-details/${item.id}'),
  //     child: Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: SearchCard(
  //           item: AdCardItemAdapter(item),
  //           showDelete: false,
  //           onAddToFavorite: () {},
  //           onDelete: () {},
  //           // +++ هنا نقوم بتمرير الأزرار المخصصة +++
  //           customActionButtons: [
  //             _buildActionIcon(FontAwesomeIcons.whatsapp, onTap: () {
  //               if (item.whatsapp != null && item.whatsapp!.isNotEmpty) {
  //                 final url = PhoneNumberFormatter.getWhatsAppUrl(item.whatsapp!);
  //                 _launchUrl(url);
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("WhatsApp number not available")));
  //               }
  //             }),
  //             const SizedBox(width: 5),
  //             _buildActionIcon(Icons.phone, onTap: () {
  //               final url = PhoneNumberFormatter.getTelUrl(item.phoneNumber);
  //               _launchUrl(url);
  //             }),
  //           ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildActionIcon(IconData icon, {required VoidCallback onTap}) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       height: 35.h,
  //       width: 62.w,
  //       decoration: BoxDecoration(color: const Color(0xFF01547E), borderRadius: BorderRadius.circular(8)),
  //       child: Center(
  //         child: Icon(icon, color: Colors.white, size: 22),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: KTextColor,
        ),
      ),
    );
  }

  Widget _buildCard(CarAdModel item) {
    if (kDebugMode) {
      // print("Building card for Ad: ${item.title} - Plan Type: ${item.planType}");
    }

    return GestureDetector(
      onTap: () => context.push('/car-details/${item.id}'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SearchCard(
          item: AdCardItemAdapter(item),
          showDelete: false,
          onAddToFavorite: () {
            // زر المفضلة بدون وظيفة حالياً
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إضافة الإعلان للمفضلة')),
            );
          },
          onDelete: () {},
          // تمرير الأزرار المخصصة مع الوظائف
          customActionButtons: [
            _buildActionIcon(FontAwesomeIcons.whatsapp, onTap: () {
              if (item.whatsapp != null && item.whatsapp!.isNotEmpty) {
                final url = PhoneNumberFormatter.getWhatsAppUrl(item.whatsapp!);
                _launchUrl(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("WhatsApp number not available")));
              }
            }),
            const SizedBox(width: 5),
            _buildActionIcon(Icons.phone, onTap: () {
              final url = PhoneNumberFormatter.getTelUrl(item.phoneNumber);
              _launchUrl(url);
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
            borderRadius: BorderRadius.circular(8)),
        child: Center(child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }

  Widget _buildFiltersRow(S s, CarAdProvider provider) {
    return SizedBox(
      height: 35.h,
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/filter.svg',
              width: 25.w, height: 25.h),
          SizedBox(width: 4.w),
          Flexible(
              flex: 3,
              child: _buildGenericMultiSelectField<TrimModel>(
                  context,
                  s.trim,
                  provider.selectedTrims,
                  provider.trims,
                  (selection) => provider.updateSelectedTrims(selection),
                  displayNamer: (trim) => trim.name,
                  isLoading: provider.isLoadingTrims,
                  isFilter: true)),
          SizedBox(width: 1.w),
          Flexible(
              flex: 3,
              child: _buildRangePickerField(context,
                  title: s.year,
                  fromValue: provider.yearFrom,
                  toValue: provider.yearTo,
                  unit: "",
                  isFilter: true, onTap: () async {
                final r = await _showRangePicker(context,
                    title: s.year,
                    initialFrom: provider.yearFrom,
                    initialTo: provider.yearTo,
                    unit: "");
                if (r != null) {
                  provider.updateYearRange(r['from'], r['to']);
                }
              })),
          SizedBox(width: 1.w),
          Flexible(
              flex: 3,
              child: _buildRangePickerField(context,
                  title: s.km,
                  fromValue: provider.kmFrom,
                  toValue: provider.kmTo,
                  unit: "KM",
                  isFilter: true, onTap: () async {
                final r = await _showRangePicker(context,
                    title: s.km,
                    initialFrom: provider.kmFrom,
                    initialTo: provider.kmTo,
                    unit: "KM");
                if (r != null) {
                  provider.updateKmRange(r['from'], r['to']);
                }
              })),
          SizedBox(width: 1.w),
          Flexible(
              flex: 3,
              child: _buildRangePickerField(context,
                  title: s.price,
                  fromValue: provider.priceFrom,
                  toValue: provider.priceTo,
                  unit: "AED",
                  isFilter: true, onTap: () async {
                final r = await _showRangePicker(context,
                    title: s.price,
                    initialFrom: provider.priceFrom,
                    initialTo: provider.priceTo,
                    unit: "AED");
                if (r != null) {
                  provider.updatePriceRange(r['from'], r['to']);
                }
              })),
        ],
      ),
    );
  }
}

// class AdCardItemAdapter implements FavoriteItemInterface {
//   final CarAdModel _ad;
//   AdCardItemAdapter(this._ad);
//   @override String get contact => _ad.advertiserName;
//   @override String get details => _ad.title;
//   @override String get imageUrl => ImageUrlHelper.getMainImageUrl(_ad.mainImage);
//   @override List<String> get images => [ ImageUrlHelper.getMainImageUrl(_ad.mainImage), ...ImageUrlHelper.getThumbnailImageUrls(_ad.thumbnailImages) ].where((img) => img.isNotEmpty).toList();
//   @override String get line1 => "Year: ${_ad.year}  Km: ${NumberFormatter.formatNumber(_ad.km)}   Specs: ${_ad.specs ?? ''}" ;
//   @override String get line2 => _ad.title;
//   @override String get price => "${NumberFormatter.formatPrice(_ad.price)} AED";
//   @override String get location => _ad.emirate;
//   @override String get title => "${_ad.make} ${_ad.model} ${_ad.trim}";
//   @override String get date => _ad.createdAt?.split('T').first ?? '';
//   @override bool get isPremium => _ad.planType != null && _ad.planType!.toLowerCase() != 'free';
//   @override AdPriority get priority { if (_ad.planType != null && _ad.planType!.toLowerCase() != 'free') { return AdPriority.premium; } return AdPriority.free; }
// }

class AdCardItemAdapter implements FavoriteItemInterface {
  String get id => (_ad.id ?? '').toString();
  final CarAdModel _ad;
  AdCardItemAdapter(this._ad);
  @override
  String get contact => _ad.advertiserName;
  @override
  String get details => _ad.title;
  @override
  String get category => 'Cars Sales'; // Category for car sales
  
  @override
  String get addCategory => _ad.addCategory ?? 'Cars Sales'; // Use dynamic category from API or fallback
  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(_ad.mainImage);
  @override
  List<String> get images => [
        ImageUrlHelper.getMainImageUrl(_ad.mainImage),
        ...ImageUrlHelper.getThumbnailImageUrls(_ad.thumbnailImages)
      ].where((img) => img.isNotEmpty).toList();
  @override
  String get line1 =>
      "Year: ${_ad.year}  Km: ${NumberFormatter.formatNumber(_ad.km)}   Specs: ${_ad.specs ?? ''}";
  @override
  String get line2 => _ad.title;
  @override
  String get price => _ad.price;
  @override
  String get location => "${_ad.emirate}  ${_ad.area}";
  @override
  String get title => "${_ad.make} ${_ad.model} ${_ad.trim ?? ''}".trim();
  @override
  String get date => _ad.createdAt?.split('T').first ?? '';
  @override
  bool get isPremium {
    // الإعلان يعتبر Premium إذا كان planType موجودًا وقيمته ليست 'free'
    if (_ad.planType == null) return false;
    return _ad.planType!.toLowerCase() != 'free';
  }

  @override
  AdPriority get priority {
    if (_ad.planType == null || _ad.planType!.toLowerCase() == 'free') {
      return AdPriority.free;
    }
    if (_ad.planType!.toLowerCase() == 'premium_star') {
      return AdPriority.PremiumStar;
    }
    if (_ad.planType!.toLowerCase() == 'premium') {
      return AdPriority.premium;
    }
    if (_ad.planType!.toLowerCase().contains('featured')) {
      return AdPriority.featured;
    }
    // كقيمة افتراضية
    return AdPriority.free;
  }
}

Widget _buildGenericMultiSelectField<T>(BuildContext context, String title,
    List<T> selectedValues, List<T> allItems, Function(List<T>) onConfirm,
    {required String Function(T) displayNamer,
    bool isLoading = false,
    bool isFilter = true}) {
  String displayText = isLoading
      ? "loading"
      : selectedValues.isEmpty
          ? title
          : selectedValues.map(displayNamer).join(', ');
  return GestureDetector(
    onTap: isLoading
        ? null
        : () async {
            final result = await showModalBottomSheet<List<T>>(
                context: context,
                isScrollControlled: true,
                builder: (context) => _GenericMultiSelectBottomSheet(
                    title: title,
                    items: allItems,
                    initialSelection: selectedValues,
                    displayNamer: displayNamer));
            if (result != null) onConfirm(result);
          },
    child: Container(
        height: isFilter ? 35 : 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8)),
        child: Text(displayText,
            style: TextStyle(
                fontWeight: FontWeight.w500, color: KTextColor, fontSize: 9.5),
            overflow: TextOverflow.ellipsis,
            maxLines: 1)),
  );
}

Widget _buildRangePickerField(BuildContext context,
    {required String title,
    String? fromValue,
    String? toValue,
    required String unit,
    required VoidCallback onTap,
    bool isFilter = false}) {
  final s = S.of(context);
  String displayText = (fromValue == null || fromValue.isEmpty) &&
          (toValue == null || toValue.isEmpty)
      ? title
      : '${fromValue ?? s.from} - ${toValue ?? s.to} $unit'.trim();
  return GestureDetector(
      onTap: onTap,
      child: Container(
          height: isFilter ? 35 : 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8)),
          child: Text(displayText,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: KTextColor,
                  fontSize: 9.5),
              overflow: TextOverflow.ellipsis)));
}

Future<Map<String, String?>?> _showRangePicker(BuildContext context,
    {required String title,
    String? initialFrom,
    String? initialTo,
    required String unit}) {
  return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _RangeSelectionBottomSheet(
          title: title,
          initialFrom: initialFrom,
          initialTo: initialTo,
          unit: unit));
}

class _GenericMultiSelectBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> initialSelection;
  final String Function(T) displayNamer;
  const _GenericMultiSelectBottomSheet(
      {Key? key,
      required this.title,
      required this.items,
      required this.initialSelection,
      required this.displayNamer})
      : super(key: key);
  @override
  _GenericMultiSelectBottomSheetState<T> createState() =>
      _GenericMultiSelectBottomSheetState<T>();
}

class _GenericMultiSelectBottomSheetState<T>
    extends State<_GenericMultiSelectBottomSheet<T>> {
  late List<T> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

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
      _filteredItems = widget.items
          .where(
              (item) => widget.displayNamer(item).toLowerCase().contains(query))
          .toList();
    });
  }

  void _onItemTapped(T item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: KTextColor)),
              TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedItems.clear();
                    });
                  },
                  child: Text(s.reset,
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp))),
            ]),
            const SizedBox(height: 16),
            TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                    hintText: s.search,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor)))),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(child: Text(s.noResultsFound))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return CheckboxListTile(
                            title: Text(widget.displayNamer(item)),
                            value: _selectedItems.contains(item),
                            activeColor: KPrimaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) => _onItemTapped(item));
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedItems),
                style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text(s.apply,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RangeSelectionBottomSheet extends StatefulWidget {
  final String title;
  final String? initialFrom;
  final String? initialTo;
  final String unit;
  const _RangeSelectionBottomSheet(
      {required this.title,
      this.initialFrom,
      this.initialTo,
      required this.unit});
  @override
  __RangeSelectionBottomSheetState createState() =>
      __RangeSelectionBottomSheetState();
}

class __RangeSelectionBottomSheetState
    extends State<_RangeSelectionBottomSheet> {
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

    Widget buildTextField(
        String hint, String suffix, TextEditingController controller) {
      return Expanded(
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            suffixIcon: suffix.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(suffix,
                        style: const TextStyle(
                            color: KTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)))
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: KTextColor)),
            TextButton(
                onPressed: () {
                  _fromController.clear();
                  _toController.clear();
                  setState(() {});
                },
                child: Text(s.reset,
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp))),
          ]),
          SizedBox(height: 16.h),
          Row(children: [
            buildTextField(s.from, widget.unit, _fromController),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(s.to,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: KTextColor,
                        fontSize: 14))),
            buildTextField(s.to, widget.unit, _toController),
          ]),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context,
                  {'from': _fromController.text, 'to': _toController.text}),
              style: ElevatedButton.styleFrom(
                  backgroundColor: KPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: Text(s.apply,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
