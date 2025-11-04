// lib/presentation/screens/real_estate_search_screen.dart

import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/real_estate_ad_model.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/real_estate_ad_provider.dart';
import 'package:advertising_app/presentation/providers/real_estate_info_provider.dart'; // ++ استيراد جديد
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

// Adapter
class RealEstateAdCardAdapter implements FavoriteItemInterface {
  final RealEstateAdModel _ad;
  RealEstateAdCardAdapter(this._ad);
  @override
  int get id => _ad.id;
  @override
  String get contact => _ad.advertiserName;
  @override
  String get details => "${_ad.propertyType} ${_ad.contractType}";
  @override
  String get category => 'Real State'; // Category for real estate
  
  @override
  String get addCategory => _ad.addCategory ?? 'Real State'; // Use dynamic category from API or fallback
  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(_ad.mainImage ?? '');
  @override
  List<String> get images => [
        ImageUrlHelper.getMainImageUrl(_ad.mainImage ?? ''),
        ...ImageUrlHelper.getThumbnailImageUrls(_ad.thumbnailImages)
      ].where((img) => img.isNotEmpty).toList();
  @override
  String get line1 => '';
  @override
  String get line2 => "${_ad.propertyType ?? ''} - ${_ad.contractType ?? ''}";
  @override
  String get price => _ad.price;
  @override
  String get location =>
      ("${_ad.emirate ?? ''} ${_ad.district ?? ''} ${_ad.area ?? ''}").trim();
  @override
  String get title => _ad.title;
  @override
  String get date => _ad.createdAt?.split('T').first ?? '';
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

class RealEstateSearchScreen extends StatefulWidget {
  final Map<String, String>? filters;
  const RealEstateSearchScreen({super.key, this.filters});

  @override
  State<RealEstateSearchScreen> createState() => _RealEstateSearchScreenState();
}

class _RealEstateSearchScreenState extends State<RealEstateSearchScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingFilterBar = false;
  double _lastScrollOffset = 0.0;
  bool _sortByPriority = false; // Sort switch state - default off

  List<String> _selectedTypes = [];
  List<String> _selectedDistricts = [];
  List<String> _selectedContracts = [];
  String? _priceFrom, _priceTo;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // الاعتماد حصراً على auth_token (قد يكون null لبعض الـ APIs العامة)
      final storage = const FlutterSecureStorage();
      final authToken = await storage.read(key: 'auth_token');

      if (mounted) {
        // Fetch filter options and ads
        context.read<RealEstateInfoProvider>().fetchAllData(token: authToken);

        // Apply filters if they exist, otherwise fetch all ads
        if (widget.filters != null && widget.filters!.isNotEmpty) {
          _applyFiltersFromNavigation();
        } else {
          context.read<RealEstateAdProvider>().fetchAds();
        }
      }
    });
  }

  void _applyFiltersFromNavigation() {
    final provider = context.read<RealEstateAdProvider>();
    final filters = widget.filters!;

    // Apply filters based on the received data
    Map<String, dynamic> filterParams = {};

    // Handle emirate filter
    if (filters['emirate'] != null && filters['emirate'] != 'All') {
      filterParams['emirate'] = filters['emirate'];
    }

    // Handle district filter
    if (filters['district'] != null && filters['district'] != 'All') {
      filterParams['district'] = filters['district'];
    }

    // Handle property type filter
    if (filters['propertyType'] != null && filters['propertyType'] != 'All') {
      filterParams['property_type'] = filters['propertyType'];
    }

    // Handle contract type filter
    if (filters['contractType'] != null && filters['contractType'] != 'All') {
      filterParams['contract_type'] = filters['contractType'];
    }

    // Handle keyword (local filter)
    if (filters['keyword'] != null && filters['keyword']!.isNotEmpty) {
      filterParams['keyword'] = filters['keyword']!;
    }

    // If all filters are 'All' or no specific filters, fetch all ads
    if (filterParams.isEmpty) {
      provider.fetchAds();
    } else {
      // Apply the filters to fetch filtered ads
      provider.fetchAds(filters: filterParams);
    }
  }

  void _applyCurrentFilters() {
    Map<String, String> filters = {};

    // إضافة فلاتر الأنواع المختارة
    if (_selectedTypes.isNotEmpty) {
      filters['property_type'] = _selectedTypes.join(',');
    }

    // إضافة فلاتر المناطق المختارة
    if (_selectedDistricts.isNotEmpty) {
      filters['district'] = _selectedDistricts.join(',');
    }

    // إضافة فلاتر العقود المختارة
    if (_selectedContracts.isNotEmpty) {
      filters['contract_type'] = _selectedContracts.join(',');
    }

    // تطبيق الفلاتر
    context.read<RealEstateAdProvider>().fetchAds(filters: filters);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    if (currentOffset < _lastScrollOffset) {
      if (!_showFloatingFilterBar)
        setState(() => _showFloatingFilterBar = true);
    } else if (currentOffset > _lastScrollOffset) {
      if (_showFloatingFilterBar)
        setState(() => _showFloatingFilterBar = false);
    }
    _lastScrollOffset = currentOffset;
  }

  // Reset all filters
  void _resetAllFilters() {
    setState(() {
      _selectedTypes.clear();
      _selectedDistricts.clear();
      _selectedContracts.clear();
      _priceFrom = null;
      _priceTo = null;
    });
    // Clear price filters in provider and fetch all ads
    context.read<RealEstateAdProvider>().clearPriceFilters();
    context.read<RealEstateAdProvider>().fetchAds();
  }

  // ++ تم تحديث هذه الدالة لتستخدم بيانات من الـ Provider
  Widget _buildFiltersRow() {
    return Consumer<RealEstateInfoProvider>(
        builder: (context, infoProvider, child) {
      // الحصول على جميع المناطق من جميع الإمارات المتاحة
      List<String> allDistricts = infoProvider.emirateDisplayNames
          .expand((emirate) => infoProvider.getDistrictsForEmirate(emirate))
          .toSet()
          .toList();

      return Container(
        height: 35.h,
        child: Row(
          children: [
            SvgPicture.asset('assets/icons/filter.svg',
                width: 25.w, height: 25.h),
            SizedBox(width: 4.w),
            Flexible(
              flex: 3,
              child: _buildMultiSelectField(
                  context,
                  S.of(context).type,
                  _selectedTypes,
                  infoProvider.propertyTypes, // ++ استخدام بيانات حقيقية
                  (selection) {
                setState(() => _selectedTypes = selection);
                _applyCurrentFilters();
              }, isFilter: true, isLoading: infoProvider.isLoading),
            ),
            SizedBox(width: 1.w),
            Flexible(
              flex: 3,
              child: _buildMultiSelectField(context, S.of(context).district,
                  _selectedDistricts, allDistricts, // ++ استخدام بيانات حقيقية
                  (selection) {
                setState(() => _selectedDistricts = selection);
                _applyCurrentFilters();
              }, isFilter: true, isLoading: infoProvider.isLoading),
            ),
            SizedBox(width: 1.w),
            Flexible(
              flex: 3,
              child: _buildMultiSelectField(
                  context,
                  S.of(context).contract,
                  _selectedContracts,
                  infoProvider.contractTypes, // ++ استخدام بيانات حقيقية
                  (selection) {
                setState(() => _selectedContracts = selection);
                _applyCurrentFilters();
              }, isFilter: true, isLoading: infoProvider.isLoading),
            ),
            SizedBox(width: 1.w),
            Flexible(
              flex: 3,
              child: _buildRangePickerField(context,
                  title: S.of(context).price,
                  fromValue: _priceFrom,
                  toValue: _priceTo,
                  unit: "AED",
                  isFilter: true, onTap: () async {
                final result = await _showRangePicker(context,
                    title: S.of(context).price,
                    initialFrom: _priceFrom,
                    initialTo: _priceTo,
                    unit: "AED");
                if (result != null) {
                  setState(() {
                    // Handle empty strings as null to properly reset
                    _priceFrom =
                        result['from']?.isEmpty == true ? null : result['from'];
                    _priceTo =
                        result['to']?.isEmpty == true ? null : result['to'];
                  });
                  // Apply price filters to provider
                  if (_priceFrom != null || _priceTo != null) {
                    context.read<RealEstateAdProvider>().updatePriceRange(
                          _priceFrom,
                          _priceTo,
                        );
                  } else {
                    context.read<RealEstateAdProvider>().clearPriceFilters();
                  }
                  _applyCurrentFilters();
                }
              }),
            ),
          ],
        ),
      );
    });
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
          child: Consumer<RealEstateAdProvider>(
              builder: (context, provider, child) {
            final allAds = provider.ads;

            // Apply sorting based on switch state
            if (_sortByPriority) {
              allAds.sort(
                  (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
            }

            final premiumStarAds = allAds
                .where((ad) =>
                    RealEstateAdCardAdapter(ad).priority ==
                    AdPriority.PremiumStar)
                .toList();
            final premiumAds = allAds
                .where((ad) =>
                    RealEstateAdCardAdapter(ad).priority == AdPriority.premium)
                .toList();
            final featuredAds = allAds
                .where((ad) =>
                    RealEstateAdCardAdapter(ad).priority == AdPriority.featured)
                .toList();
            final freeAds = allAds
                .where((ad) =>
                    RealEstateAdCardAdapter(ad).priority == AdPriority.free)
                .toList();

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    // Build current filters from selected state
                    Map<String, String> currentFilters = {};

                    if (_selectedTypes.isNotEmpty) {
                      currentFilters['property_type'] =
                          _selectedTypes.join(',');
                    }

                    if (_selectedDistricts.isNotEmpty) {
                      currentFilters['district'] = _selectedDistricts.join(',');
                    }

                    if (_selectedContracts.isNotEmpty) {
                      currentFilters['contract_type'] =
                          _selectedContracts.join(',');
                    }

                    // Add price filters if they exist
                    if (_priceFrom != null && _priceFrom!.isNotEmpty) {
                      currentFilters['price_from'] = _priceFrom!;
                    }

                    if (_priceTo != null && _priceTo!.isNotEmpty) {
                      currentFilters['price_to'] = _priceTo!;
                    }

                    // Fetch ads with current filters
                    await provider.fetchAds(
                        filters:
                            currentFilters.isNotEmpty ? currentFilters : null);
                  },
                  child: SingleChildScrollView(
                    key: const PageStorageKey('real_estate_scroll'),
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
                                  SizedBox(height: 3.h),
                                  Center(
                                      child: Text(s.realestate,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 24.sp,
                                              color: KTextColor)))
                                ])),
                        SizedBox(height: 8.h),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: _buildFiltersRow()),
                        SizedBox(height: 4.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              bool isSmallScreen =
                                  MediaQuery.of(context).size.width <= 370;
                              return Row(children: [
                                Text('${s.ad} ${provider.totalAds}',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: KTextColor,
                                        fontWeight: FontWeight.w400)),
                                SizedBox(width: isSmallScreen ? 35.w : 30.w),
                                Expanded(
                                    child: Container(
                                        height: 37.h,
                                        padding:
                                            EdgeInsetsDirectional.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 8.w : 12.w),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: const Color(0xFF08C2C9)),
                                            borderRadius:
                                                BorderRadius.circular(8.r)),
                                        child: Row(children: [
                                          SvgPicture.asset(
                                              'assets/icons/locationicon.svg',
                                              width: 18.w,
                                              height: 18.h),
                                          SizedBox(
                                              width:
                                                  isSmallScreen ? 12.w : 15.w),
                                          Expanded(
                                              child: Text(s.sort,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: KTextColor,
                                                      fontSize: 12.sp))),
                                          SizedBox(
                                              width:
                                                  isSmallScreen ? 35.w : 32.w,
                                              child: Transform.scale(
                                                  scale:
                                                      isSmallScreen ? 0.8 : .9,
                                                  child: Switch(
                                                      value: _sortByPriority,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          _sortByPriority = val;
                                                        });
                                                      },
                                                      activeColor: Colors.white,
                                                      activeTrackColor:
                                                          const Color(
                                                              0xFF08C2C9),
                                                      inactiveThumbColor:
                                                          isSmallScreen
                                                              ? Colors.white
                                                              : Colors.grey,
                                                      inactiveTrackColor:
                                                          Colors.grey[300])))
                                        ])))
                              ]);
                            },
                          ),
                        ),
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
                                  child: Text("Error: ${provider.error}")))
                        else if (allAds.isEmpty && !provider.isLoading)
                          Center(
                              child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(S.of(context).noResultsFound)))
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
                              bottom: BorderSide(color: Colors.grey.shade300))),
                      child: Column(
                        children: [
                          GestureDetector(
                              onTap: () => context.pop(),
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
                          _buildFiltersRow(),
                          SizedBox(height: 4.h),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isSmallScreen =
                                  MediaQuery.of(context).size.width <= 370;
                              return Row(children: [
                                Text('${s.ad} ${provider.totalAds}',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: KTextColor,
                                        fontWeight: FontWeight.w400)),
                                SizedBox(width: isSmallScreen ? 35.w : 30.w),
                                Expanded(
                                    child: Container(
                                        height: 37.h,
                                        padding:
                                            EdgeInsetsDirectional.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 8.w : 12.w),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: const Color(0xFF08C2C9)),
                                            borderRadius:
                                                BorderRadius.circular(8.r)),
                                        child: Row(children: [
                                          SvgPicture.asset(
                                              'assets/icons/locationicon.svg',
                                              width: 18.w,
                                              height: 18.h),
                                          SizedBox(
                                              width:
                                                  isSmallScreen ? 12.w : 15.w),
                                          Expanded(
                                              child: Text(s.sort,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: KTextColor,
                                                      fontSize: 12.sp))),
                                          SizedBox(
                                              width:
                                                  isSmallScreen ? 35.w : 32.w,
                                              child: Transform.scale(
                                                  scale:
                                                      isSmallScreen ? 0.8 : .9,
                                                  child: Switch(
                                                      value: _sortByPriority,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          _sortByPriority = val;
                                                        });
                                                      },
                                                      activeColor: Colors.white,
                                                      activeTrackColor:
                                                          const Color(
                                                              0xFF08C2C9),
                                                      inactiveThumbColor:
                                                          isSmallScreen
                                                              ? Colors.white
                                                              : Colors.grey,
                                                      inactiveTrackColor:
                                                          Colors.grey[300])))
                                        ])))
                              ]);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 35.h,
        width: 62.w,
        decoration: BoxDecoration(
          color: Color(0xFF01547E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
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

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Clean the phone number
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Try to launch WhatsApp app first
    final whatsappUrl = 'whatsapp://send?phone=$cleanNumber';
    final Uri whatsappUri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // If WhatsApp app is not available, try web version
      final webWhatsappUrl = 'https://wa.me/$cleanNumber';
      final Uri webWhatsappUri = Uri.parse(webWhatsappUrl);

      if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // If both fail, show message to invite user to install WhatsApp
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "WhatsApp غير متوفر. يرجى تثبيت WhatsApp أو دعوة المستخدم للانضمام"),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildAdList(String title, List<RealEstateAdModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
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
        child: Text(title,
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: KTextColor)));
  }

  Widget _buildCard(RealEstateAdModel item) {
    return GestureDetector(
      onTap: () {
        context.push('/real-details/${item.id}');
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SearchCard(
          showLine1: false,
          item: RealEstateAdCardAdapter(item),
          showDelete: false,
          onAddToFavorite: () {},
          onDelete: () {},
          customActionButtons: [
            // WhatsApp button
            _buildActionIcon(
              FontAwesomeIcons.whatsapp,
              () {
                if (item.whatsappNumber != null &&
                    item.whatsappNumber!.isNotEmpty &&
                    item.whatsappNumber != 'null' &&
                    item.whatsappNumber != 'nullnow') {
                  final url =
                      PhoneNumberFormatter.getWhatsAppUrl(item.whatsappNumber!);
                  _launchUrl(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("WhatsApp number not available")),
                  );
                }
              },
            ),
            SizedBox(
              width: 2,
            ),
            // Phone button
            _buildActionIcon(
              Icons.phone,
              () {
                if (item.phoneNumber != null &&
                    item.phoneNumber!.isNotEmpty &&
                    item.phoneNumber != 'null' &&
                    item.phoneNumber != 'nullnow') {
                  final url = PhoneNumberFormatter.getTelUrl(item.phoneNumber!);
                  _launchUrl(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Phone number not available")),
                  );
                }
              },
            ),
          ],
        ),
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
    {bool isFilter = false,
    bool isLoading = false}) {
  final s = S.of(context);
  String displayText = isLoading
      ? 'Loading...'
      : (selectedValues.isEmpty ? title : selectedValues.join(', '));
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (!isFilter)
      Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
    if (!isFilter) const SizedBox(height: 4),
    GestureDetector(
      onTap: isLoading || allItems.isEmpty
          ? null
          : () async {
              final result = await showModalBottomSheet<List<String>>(
                  context: context,
                  backgroundColor: Colors.white,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => _MultiSelectBottomSheet(
                      title: title,
                      items: allItems,
                      initialSelection: selectedValues));
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
            color: (isLoading || allItems.isEmpty)
                ? Colors.grey.shade200
                : Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8)),
        child: Text(
          displayText,
          style: TextStyle(
              fontWeight:
                  selectedValues.isEmpty ? FontWeight.w500 : FontWeight.w500,
              color: selectedValues.isEmpty
                  ? (isLoading ? Colors.grey.shade600 : KTextColor)
                  : KTextColor,
              fontSize: 9.5),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ),
  ]);
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
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (!isFilter)
      Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
    if (!isFilter) const SizedBox(height: 4),
    GestureDetector(
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
                  fontWeight: FontWeight.w500,
                  color: KTextColor,
                  fontSize: 9.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1)),
    ),
  ]);
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _RangeSelectionBottomSheet(
          title: title,
          initialFrom: initialFrom,
          initialTo: initialTo,
          unit: unit));
}

class _MultiSelectBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> initialSelection;
  const _MultiSelectBottomSheet(
      {Key? key,
      required this.title,
      required this.items,
      required this.initialSelection})
      : super(key: key);
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
    return Theme(
        data: Theme.of(context).copyWith(
            checkboxTheme: CheckboxThemeData(
                side: MaterialStateBorderSide.resolveWith(
                    (_) => BorderSide(width: 1.0, color: borderColor)))),
        child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                        fontSize: 14.sp)))
                          ]),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _searchController,
                          style: const TextStyle(color: KTextColor),
                          decoration: InputDecoration(
                              hintText: s.search,
                              prefixIcon:
                                  const Icon(Icons.search, color: KTextColor),
                              hintStyle:
                                  TextStyle(color: KTextColor.withOpacity(0.5)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: KPrimaryColor, width: 2)))),
                      const SizedBox(height: 8),
                      const Divider(),
                      Expanded(
                          child: _filteredItems.isEmpty
                              ? Center(
                                  child: Text(s.noResultsFound,
                                      style:
                                          const TextStyle(color: KTextColor)))
                              : ListView.builder(
                                  itemCount: _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];
                                    return CheckboxListTile(
                                        title: Text(item,
                                            style: const TextStyle(
                                                color: KTextColor)),
                                        value: _selectedItems.contains(item),
                                        activeColor: KPrimaryColor,
                                        checkColor: Colors.white,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        onChanged: (_) => _onItemTapped(item));
                                  })),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, _selectedItems),
                              child: Text(s.apply),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: KPrimaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)))))
                    ])))));
  }
}

class _RangeSelectionBottomSheet extends StatefulWidget {
  final String title;
  final String? initialFrom;
  final String? initialTo;
  final String unit;
  const _RangeSelectionBottomSheet(
      {Key? key,
      required this.title,
      this.initialFrom,
      this.initialTo,
      required this.unit})
      : super(key: key);
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
                    child: Text(s.reset,
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp)
                            )
                            )
              ]),
              SizedBox(height: 16.h),
              Row(children: [
                Expanded(
                    child:
                        buildTextField(s.from, widget.unit, _fromController)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(s.to,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: KTextColor,
                            fontSize: 14))),
                Expanded(
                    child: buildTextField(s.to, widget.unit, _toController))
              ]),
              SizedBox(height: 24.h),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, {
                            'from': _fromController.text,
                            'to': _toController.text
                          }),
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
            ]));
  }
}
