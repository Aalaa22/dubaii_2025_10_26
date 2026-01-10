// lib/presentation/screens/car_service_search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/presentation/providers/car_services_provider.dart';
import 'package:advertising_app/presentation/providers/car_services_info_provider.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:advertising_app/utils/number_formatter.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

// Adapter لتحويل بيانات الموديل الحقيقي إلى الصيغة التي تفهمها SearchCard
class CarServiceAdCardAdapter implements FavoriteItemInterface {
  @override
  String get id => (_ad.id ?? '').toString();
  final CarServiceModel _ad;
  CarServiceAdCardAdapter(this._ad);

  @override
  String get contact => _ad.advertiserName;
  @override
  String get details => _ad.serviceType;
  @override
  String get category => 'Car Services'; // Category for car services
  
  @override String get addCategory => 'Car Services'; // Dynamic category for API
  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(_ad.mainImage ?? '');
  @override
  List<String> get images {
    List<String> allImages = [];

    // إضافة الصورة الرئيسية إذا كانت متوفرة
    if (_ad.mainImage != null && _ad.mainImage!.isNotEmpty) {
      allImages.add(ImageUrlHelper.getMainImageUrl(_ad.mainImage!));
    }

    // إضافة الصور المصغرة إذا كانت متوفرة
    if (_ad.thumbnailImages != null && _ad.thumbnailImages!.isNotEmpty) {
      allImages
          .addAll(ImageUrlHelper.getThumbnailImageUrls(_ad.thumbnailImages!));
    }

    // إزالة الصور الفارغة وإرجاع القائمة
    return allImages.where((img) => img.isNotEmpty).toList();
  }

  @override
  String get line1 => _ad.title;
  // @override
  // String get line2 => _ad.title;
  @override
  String get price => _ad.price;
  @override
  String get location => "${_ad.emirate} ${_ad.district} ${_ad.area} ";
  @override
  String get title => _ad.serviceName;
  @override
  String get date => _ad.createdAt?.split('T').first ?? '';
  //{
  //   try {
  //     String dateOnly;
  //     final dateTimeString = _ad.createdAt?.split('T').first ?? '';

  //     // Handle different date formats
  //     if (dateTimeString.contains('T')) {
  //       dateOnly = dateTimeString.split('T').first;
  //     } else if (dateTimeString.contains(' ')) {
  //       dateOnly = dateTimeString.split(' ').first;
  //     } else {
  //       dateOnly = dateTimeString;
  //     }

  //     // Reverse the date format from YYYY-MM-DD to DD-MM-YYYY
  //     if (dateOnly.contains('-') && dateOnly.length >= 10) {
  //       List<String> parts = dateOnly.split('-');
  //       if (parts.length == 3) {
  //         return '${parts[2]}-${parts[1]}-${parts[0]}';
  //       }
  //     }

  //     return dateOnly;
  //   } catch (e) {
  //     return _ad.createdAt?.split('T').first ?? '';
  //   }
  // }

  @override
  AdPriority get priority {
    final plan = _ad.planType?.toLowerCase();
    if (plan == null || plan == 'free') return AdPriority.free;
    if (plan.contains('premium_star')) return AdPriority.PremiumStar;
    if (plan.contains('premium')) return AdPriority.premium;
    if (plan.contains('featured')) return AdPriority.featured;
    return AdPriority.free;
  }

  @override
  bool get isPremium => priority != AdPriority.free;
}

class CarServiceSearchScreen extends StatefulWidget {
  final Map<String, String>? initialFilters;
  const CarServiceSearchScreen({super.key, this.initialFilters});

  @override
  State<CarServiceSearchScreen> createState() => _CarServiceSearchScreenState();
}

class _CarServiceSearchScreenState extends State<CarServiceSearchScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingFilterBar = false;
  double _lastScrollOffset = 0;
  Timer? _debounce;
  bool _sortByDateEnabled = false; // مفتاح الترتيب مغلق بشكل افتراضي

  List<String> _selectedServiceTypes = [];
  List<String> _selectedDistricts = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // التأكد من توفر بيانات الإمارات والمناطق
      final infoProvider = context.read<CarServicesInfoProvider>();
      if (infoProvider.emirateDisplayNames.isEmpty) {
        // جلب البيانات إذا لم تكن متوفرة (بيانات عامة لا تتطلب توكن)
        infoProvider.fetchLandingPageData();
      }

      // تحديث الإمارة المختارة في InfoProvider بناءً على الفلاتر الأولية
      if (widget.initialFilters != null &&
          widget.initialFilters!.containsKey('emirate')) {
        final emirate = widget.initialFilters!['emirate'];
        infoProvider.updateSelectedEmirate(emirate);
      }

      // تحديث نوع الخدمة المختار في InfoProvider بناءً على الفلاتر الأولية
      if (widget.initialFilters != null &&
          widget.initialFilters!.containsKey('service_type')) {
        final serviceType = widget.initialFilters!['service_type'];
        infoProvider.updateSelectedServiceType(serviceType);
      }

      // استخدام الفلاتر المرسلة عند جلب البيانات
      context
          .read<CarServicesProvider>()
          .applyAndFetchAds(initialFilters: widget.initialFilters);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _applyAndSearchWithDebounce() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _applyFiltersAndFetch();
    });
  }

  void _applyFiltersAndFetch() {
    Map<String, String> filters = {};

    // إضافة الفلاتر الأولية إن وجدت
    if (widget.initialFilters != null) {
      filters.addAll(widget.initialFilters!);
    }

    // إضافة فلاتر الإمارة ونوع الخدمة من CarServicesInfoProvider
    final infoProvider = context.read<CarServicesInfoProvider>();
    final formattedFilters = infoProvider.getFormattedFilters();
    filters.addAll(formattedFilters);

    // إضافة الفلاتر المحددة (تجاهل إذا كانت تتعارض مع الفلاتر الأولية)
    if (_selectedServiceTypes.isNotEmpty &&
        !filters.containsKey('service_name')) {
      filters['service_name'] = _selectedServiceTypes.join(',');
    }
    if (_selectedDistricts.isNotEmpty) {
      filters['district'] = _selectedDistricts.join(',');
    }
    // فلتر السعر يتم تطبيقه محلياً في CarServicesProvider

    context
        .read<CarServicesProvider>()
        .applyAndFetchAds(initialFilters: filters);
  }

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

  void _handleScroll() {
    final currentOffset = _scrollController.offset;
    if (currentOffset <= 200) {
      if (_showFloatingFilterBar) {
        setState(() => _showFloatingFilterBar = false);
      }
      _lastScrollOffset = currentOffset;
      return;
    }
    if (currentOffset < _lastScrollOffset - 50) {
      if (!_showFloatingFilterBar) {
        setState(() => _showFloatingFilterBar = true);
      }
    } else if (currentOffset > _lastScrollOffset + 10) {
      if (_showFloatingFilterBar) {
        setState(() => _showFloatingFilterBar = false);
      }
    }
    _lastScrollOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<CarServicesProvider>(
            builder: (context, provider, child) {
              final allAds = provider.ads;
              // الترتيب حسب تاريخ الإنشاء من الأحدث للأقدم (فقط إذا كان المفتاح مفعل)
              if (_sortByDateEnabled) {
                allAds.sort(
                    (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
              }

              final premiumStarAds = allAds
                  .where((ad) =>
                      CarServiceAdCardAdapter(ad).priority ==
                      AdPriority.PremiumStar)
                  .toList();
              final premiumAds = allAds
                  .where((ad) =>
                      CarServiceAdCardAdapter(ad).priority ==
                      AdPriority.premium)
                  .toList();
              final featuredAds = allAds
                  .where((ad) =>
                      CarServiceAdCardAdapter(ad).priority ==
                      AdPriority.featured)
                  .toList();
              final freeAds = allAds
                  .where((ad) =>
                      CarServiceAdCardAdapter(ad).priority == AdPriority.free)
                  .toList();

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async => provider.applyAndFetchAds(
                        initialFilters: widget.initialFilters),
                    child: SingleChildScrollView(
                      key: const PageStorageKey('car_service_search_scroll'),
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
                                  onTap: () => context.pop(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Row(children: [
                                      Icon(Icons.arrow_back_ios,
                                          color: KTextColor, size: 17.sp),
                                      Transform.translate(
                                          offset: Offset(-3.w, 0),
                                          child: Text(s!.back,
                                              style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: KTextColor))),
                                    ]),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Center(
                                    child: Text(s.carservices,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 24.sp,
                                            color: KTextColor))),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: _buildFiltersRow(s),
                          ),
                          SizedBox(height: 4.h),
                          _buildAdHeader(context, allAds.length),
                          SizedBox(height: 5.h),
                          if (provider.isLoading && allAds.isEmpty)
                            const Center(
                                child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator()))
                          else if (provider.error != null && allAds.isEmpty)
                            Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text('Error: ${provider.error}')))
                          else if (allAds.isEmpty && !provider.isLoading)
                            Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text("s.no_result_found")))
                          else ...[
                            _buildAdList(
                                s.priority_first_premium, premiumStarAds),
                            _buildAdList(s.priority_premium, premiumAds),
                            _buildAdList(s.priority_featured, featuredAds),
                            _buildAdList(s.priority_free, freeAds),
                          ]
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
                                  // Clear all search filters when going back
                                  _selectedServiceTypes.clear();
                                  _selectedDistricts.clear();
                                  _sortByDateEnabled = false;

                                  // Clear provider filters
                                  final infoProvider =
                                      Provider.of<CarServicesInfoProvider>(
                                          context,
                                          listen: false);
                                  infoProvider.updateSelectedEmirate(null);
                                  infoProvider.updateSelectedServiceType(null);

                                  final provider =
                                      Provider.of<CarServicesProvider>(context,
                                          listen: false);
                                  provider.clearPriceFilters();

                                  context.pop();
                                },
                                child: Row(children: [
                                  Icon(Icons.arrow_back_ios,
                                      color: KTextColor, size: 17.sp),
                                  Transform.translate(
                                      offset: Offset(-3.w, 0),
                                      child: Text(s.back,
                                          style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                              color: KTextColor)))
                                ])),
                            SizedBox(height: 8.h),
                            _buildFiltersRow(s),
                            SizedBox(height: 4.h),
                            _buildAdHeader(context, allAds.length),
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
      ),
    );
  }

  Widget _buildAdHeader(BuildContext context, int totalAds) {
    bool isSmallScreen = MediaQuery.of(context).size.width <= 370;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          Text('${S.of(context)!.ad} $totalAds',
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
                  SizedBox(width: isSmallScreen ? 8.w : 15.w),
                  Expanded(
                      child: Text(S.of(context)!.sort,
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
                          value: _sortByDateEnabled,
                          onChanged: (val) {
                            setState(() {
                              _sortByDateEnabled = val;
                            });
                          },
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
      ),
    );
  }

  Widget _buildAdList(String title, List<CarServiceModel> items) {
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
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: KTextColor,
        ),
      ),
    );
  }

  Widget _buildCard(CarServiceModel item) {
    // استخدم الـ Adapter مرة واحدة لإعادة الاستخدام داخل الكارد
    final adapter = CarServiceAdCardAdapter(item);
    return GestureDetector(
      onTap: () {
        context.push('/car-service-details/${item.id}');
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SearchCard(
          item: adapter,
          showDelete: false,
          onAddToFavorite: () {
            // زر المفضلة بدون وظيفة حالياً
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إضافة الإعلان للمفضلة')),
            );
          },
          onDelete: () {},
          // في هذه الصفحة فقط: عرض title داخل line1 بنفس مواصفات النمط المطلوب
          showLine1: true,
          customLine1Span: TextSpan(
            text: adapter.line1,
            style: TextStyle(
              color: KTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              height: 1.2,
            ),
          ),
          // تمرير الأزرار المخصصة مع الوظائف
          customActionButtons: [
            _buildActionIcon(Icons.phone, onTap: () {
              final phoneNumber = item.phoneNumber;
              if (phoneNumber != null && phoneNumber.isNotEmpty) {
                final telUrl = PhoneNumberFormatter.getTelUrl(phoneNumber);
                _launchUrl(telUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رقم الهاتف غير متوفر')),
                );
              }
            }),
            const SizedBox(width: 5),
            _buildActionIcon(FontAwesomeIcons.whatsapp, onTap: () {
              final phoneNumber = item.phoneNumber;
              if (phoneNumber != null && phoneNumber.isNotEmpty) {
                final whatsappUrl =
                    PhoneNumberFormatter.getWhatsAppUrl(phoneNumber);
                _launchUrl(whatsappUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رقم الهاتف غير متوفر')),
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

  Widget _buildFiltersRow(S s) {
    return Container(
      height: 35.h,
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/filter.svg',
              width: 25.w, height: 25.h),
          SizedBox(width: 5.w),
          Expanded(
            child: Row(
              children: [
                Flexible(
                    flex: 4,
                    child: Consumer<CarServicesProvider>(
                      builder: (context, provider, child) {
                        // الحصول على أسماء الخدمات من الإعلانات المعروضة حالياً
                        final currentAds = provider.ads;
                        final availableServiceNames = currentAds
                            .map((ad) => ad.serviceName)
                            .where((name) => name != null && name.isNotEmpty)
                            .toSet()
                            .toList();

                        return _buildMultiSelectField(
                            context,
                            s.service_type,
                            _selectedServiceTypes,
                            availableServiceNames, (selection) {
                          setState(() => _selectedServiceTypes = selection);
                          _applyAndSearchWithDebounce();
                        }, isFilter: true);
                      },
                    )),
                SizedBox(width: 2.w),
                Flexible(
                    flex: 4,
                    child: Consumer<CarServicesInfoProvider>(
                      builder: (context, infoProvider, child) {
                        // الحصول على المناطق بناءً على الإمارة المختارة
                        final availableDistricts =
                            infoProvider.selectedEmirate != null
                                ? infoProvider.getDistrictsForEmirate(
                                    infoProvider.selectedEmirate)
                                : <String>[];

                        return _buildMultiSelectField(
                            context,
                            s.district,
                            _selectedDistricts,
                            availableDistricts, (selection) {
                          setState(() => _selectedDistricts = selection);
                          _applyAndSearchWithDebounce();
                        }, isFilter: true);
                      },
                    )),
                SizedBox(width: 2.w),
                Flexible(
                    flex: 4,
                    child: Consumer<CarServicesProvider>(
                      builder: (context, provider, child) {
                        return _buildRangePickerField(context,
                            title: s.price,
                            fromValue: provider.priceFrom,
                            toValue: provider.priceTo,
                            unit: "AED",
                            isFilter: true, onTap: () async {
                          final result = await _showRangePicker(context,
                              title: s.price,
                              initialFrom: provider.priceFrom,
                              initialTo: provider.priceTo,
                              unit: "AED");
                          if (result != null) {
                            provider.updatePriceRange(
                                result['from'], result['to']);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMultiSelectField(
    BuildContext context,
    String title,
    List<String> selectedValues,
    List<String> allItems,
    Function(List<String>) onConfirm,
    {bool isFilter = true}) {
  String displayText =
      selectedValues.isEmpty ? title : selectedValues.join(', ');
  return GestureDetector(
    onTap: () async {
      final result = await showModalBottomSheet<List<String>>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => _MultiSelectBottomSheet(
            title: title, items: allItems, initialSelection: selectedValues),
      );
      if (result != null) {
        onConfirm(result);
      }
    },
    child: Container(
        height: isFilter ? 35 : 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
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
    bool isFilter = true}) {
  final s = S.of(context);
  final from = (fromValue != null && fromValue.isNotEmpty)
      ? NumberFormatter.formatNumber(fromValue)
      : s!.from;
  final to = (toValue != null && toValue.isNotEmpty)
      ? NumberFormatter.formatNumber(toValue)
      : s!.to;
  String displayText = (fromValue == null || fromValue.isEmpty) &&
          (toValue == null || toValue.isEmpty)
      ? title
      : '$from - $to $unit'.trim();
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: isFilter ? 35 : 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8)),
      child: Text(displayText,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 9.5),
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
    ),
  );
}

Future<Map<String, String?>?> _showRangePicker(BuildContext context,
    {required String title,
    String? initialFrom,
    String? initialTo,
    required String unit}) {
  return showModalBottomSheet<Map<String, String?>>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => _RangeSelectionBottomSheet(
        title: title,
        initialFrom: initialFrom,
        initialTo: initialTo,
        unit: unit),
  );
}

class _MultiSelectBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> initialSelection;
  const _MultiSelectBottomSheet(
      {required this.title,
      required this.items,
      required this.initialSelection});
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
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onItemTapped(String item) {
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                child: Text(s!.reset,
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp))),
          ]),
          const SizedBox(height: 16),
          TextFormField(
              controller: _searchController,
              style: const TextStyle(color: KTextColor),
              decoration: InputDecoration(
                  hintText: s.search,
                  prefixIcon: const Icon(Icons.search, color: KTextColor),
                  hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: KPrimaryColor, width: 2)))),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(s.noResultsFound,
                          style: const TextStyle(color: KTextColor)))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return CheckboxListTile(
                            title: Text(item,
                                style: const TextStyle(color: KTextColor)),
                            value: _selectedItems.contains(item),
                            activeColor: KPrimaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) => _onItemTapped(item));
                      })),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedItems),
                  child: Text(s.apply,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))))),
          const SizedBox(height: 16)
        ]),
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
      return TextFormField(
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
              filled: true));
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
                child: Text(s!.reset,
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp))),
          ]),
          SizedBox(height: 16.h),
          Row(children: [
            Expanded(
                child: buildTextField(s.from, widget.unit, _fromController)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(s.to,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: KTextColor,
                        fontSize: 14))),
            Expanded(child: buildTextField(s.to, widget.unit, _toController))
          ]),
          SizedBox(height: 24.h),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context,
                      {'from': _fromController.text, 'to': _toController.text}),
                  child: Text(s.apply,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))))),
          SizedBox(height: 16.h)
        ],
      ),
    );
  }
}
