// lib/presentation/screens/other_service_search_screen.dart

import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/presentation/providers/other_services_ad_provider.dart';
import 'package:advertising_app/presentation/widget/custom_search2_card.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/presentation/providers/other_services_info_provider.dart';
import 'package:advertising_app/data/model/other_service_ad_model.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class OtherServiceSearchScreen extends StatefulWidget {
  final Map<String, String>? initialFilters;
  const OtherServiceSearchScreen({super.key, this.initialFilters});

  @override
  State<OtherServiceSearchScreen> createState() =>
      _OtherServiceSearchScreenState();
}

class _OtherServiceSearchScreenState extends State<OtherServiceSearchScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingFilterBar = false;
  double _lastScrollOffset = 0;

  List<String> _selectedSections = [];
  List<String> _selectedServices = [];
  String? _priceFrom, _priceTo;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      // جلب بيانات الفلاتر حتى بدون توكن (التوكن يُستخدم فقط لمعلومات التواصل عند توفره)
      context.read<OtherServicesInfoProvider>().fetchAllData(token: token);

      final initial = widget.initialFilters;
      if (initial != null && initial.isNotEmpty) {
        // حفظ الفلاتر الأولية لدمجها مع أي فلاتر لاحقة يتم تطبيقها محليًا
        context.read<OtherServicesAdProvider>().setInitialFilters(initial);
        context.read<OtherServicesAdProvider>().fetchAds(filters: initial);
      } else {
        // لا توجد فلاتر مبدئية: تأكد من تنظيف أي فلاتر محفوظة سابقًا ثم اجلب الإعلانات
        final adProvider = context.read<OtherServicesAdProvider>();
        adProvider.clearInitialFilters();
        adProvider.clearPriceFilters();
        adProvider.fetchAds();
      }
    });
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

  void _applyFilters() {
    final provider = context.read<OtherServicesAdProvider>();
    Map<String, String> filters = {};

    if (_selectedSections.isNotEmpty)
      filters['section_type'] = _selectedSections.join(',');
    if (_selectedServices.isNotEmpty)
      filters['service_name'] = _selectedServices.join(',');
    if (_priceFrom != null && _priceFrom!.isNotEmpty)
      filters['price_from'] = _priceFrom!;
    if (_priceTo != null && _priceTo!.isNotEmpty)
      filters['price_to'] = _priceTo!;

    provider.fetchAds(filters: filters);
  }

  Widget _buildFiltersRow() {
    return Consumer<OtherServicesInfoProvider>(
        builder: (context, infoProvider, child) {
      return Container(
        height: 35.h,
        child: Row(
          children: [
            SvgPicture.asset('assets/icons/filter.svg',
                width: 25.w, height: 25.h),
            SizedBox(width: 8.w),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                      flex: 3,
                      child: _buildMultiSelectField(
                          context,
                          S.of(context).section,
                          _selectedSections,
                          infoProvider.sectionTypes, (selection) {
                        setState(() => _selectedSections = selection);
                        _applyFilters();
                      }, isFilter: true, isLoading: infoProvider.isLoading)),
                  SizedBox(width: 3.w),
                  Flexible(
                      flex: 3,
                      child: Consumer<OtherServicesAdProvider>(
                        builder: (context, adProvider, _) => _buildMultiSelectField(
                            context,
                            S.of(context).service,
                            _selectedServices,
                            adProvider.serviceNames,
                            (selection) {
                              setState(() => _selectedServices = selection);
                              _applyFilters();
                            },
                            isFilter: true,
                            isLoading: adProvider.isLoading),
                      )),
                  SizedBox(width: 3.w),
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
                            _priceFrom =
                                result['from'] == "" ? null : result['from'];
                            _priceTo = result['to'] == "" ? null : result['to'];
                          });
                          final adProvider = context.read<OtherServicesAdProvider>();
                          if ((_priceFrom == null || _priceFrom!.isEmpty) &&
                              (_priceTo == null || _priceTo!.isEmpty)) {
                            adProvider.clearPriceFilters();
                          } else {
                            adProvider.setPriceFilters(_priceFrom, _priceTo);
                          }
                          _applyFilters();
                        }
                      })),
                ],
              ),
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
          child: Consumer<OtherServicesAdProvider>(
            builder: (context, provider, child) {
              final allAds = provider.ads;
              allAds.sort(
                  (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
              final premiumStarAds = allAds
                  .where((ad) => ad.priority == AdPriority.PremiumStar)
                  .toList();
              final premiumAds = allAds
                  .where((ad) => ad.priority == AdPriority.premium)
                  .toList();
              final featuredAds = allAds
                  .where((ad) => ad.priority == AdPriority.featured)
                  .toList();
              final freeAds =
                  allAds.where((ad) => ad.priority == AdPriority.free).toList();

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async => provider.fetchAds(),
                    child: SingleChildScrollView(
                      key: const PageStorageKey('other_service_scroll'),
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
                                  ]),
                                ),
                                SizedBox(height: 3.h),
                                Center(
                                  child: Text(s.otherservices,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 24.sp,
                                          color: KTextColor)),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: _buildFiltersRow(),
                          ),
                          SizedBox(height: 4.h),
                          _buildAdHeader(context, provider.totalAds),
                          SizedBox(height: 5.h),
                          if (provider.isLoading && allAds.isEmpty)
                            const Center(
                                heightFactor: 10,
                                child: CircularProgressIndicator())
                          else if (provider.error != null && allAds.isEmpty)
                            Center(
                                heightFactor: 10,
                                child: Text("Error: ${provider.error}"))
                          else if (allAds.isEmpty && !provider.isLoading)
                            Center(
                                heightFactor: 10, child: Text(s.noResultsFound))
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
                              bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
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
                              ]),
                            ),
                            SizedBox(height: 8.h),
                            _buildFiltersRow(),
                            SizedBox(height: 4.h),
                            _buildAdHeader(context, provider.totalAds),
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
    final adProvider = context.watch<OtherServicesAdProvider>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
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
                    child: Text(S.of(context).sort,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: KTextColor,
                            fontSize: 12.sp)),
                  ),
                  SizedBox(
                    width: isSmallScreen ? 35.w : 32.w,
                    child: Transform.scale(
                      scale: isSmallScreen ? 0.8 : .9,
                      child: Switch(
                          value: adProvider.sortByNearest,
                          onChanged: (val) {
                            adProvider.setSortByNearest(val);
                          },
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF08C2C9),
                          inactiveThumbColor:
                              isSmallScreen ? Colors.white : Colors.grey,
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

  Widget _buildAdList(String title, List<OtherServiceAdModel> items) {
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
              fontSize: 18.sp, fontWeight: FontWeight.bold, color: KTextColor)),
    );
  }

  Widget _buildCard(OtherServiceAdModel item) {
    return GestureDetector(
      onTap: () {
        context.push('/other_service-details/${item.id}');
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SearchCard2(
           customLine1Span: TextSpan(children: [WidgetSpan(child: Text(item.line1, style: const TextStyle( color: Color.fromRGBO(0, 30, 90, 1), fontSize: 14, fontWeight: FontWeight.w600)))]),
        
          showLine1: true,
          item: item,
          showDelete: false,
          onAddToFavorite: () {},
          onDelete: () {},
          // أزرار واتساب والهاتف بنفس آلية صفحات التفاصيل
          customActionButtons: [
            _buildActionIcon(FontAwesomeIcons.whatsapp, onTap: () {
              final whatsappNumber = item.whatsappNumber ?? item.phoneNumber;
              if (whatsappNumber != null && whatsappNumber.isNotEmpty && whatsappNumber != 'null' && whatsappNumber != 'nullnow') {
                final url = PhoneNumberFormatter.getWhatsAppUrl(whatsappNumber);
                _launchUrl(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("WhatsApp number not available")),
                );
              }
            }),
            const SizedBox(width: 5),
            _buildActionIcon(Icons.phone, onTap: () {
              final phoneNumber = item.phoneNumber;
              if (phoneNumber != null && phoneNumber.isNotEmpty && phoneNumber != 'null' && phoneNumber != 'nullnow') {
                final url = PhoneNumberFormatter.getTelUrl(phoneNumber);
                _launchUrl(url);
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
      ? "Loading..."
      : selectedValues.isEmpty
          ? title
          : selectedValues.join(', ');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
                      initialSelection: selectedValues),
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
              color: (isLoading || allItems.isEmpty)
                  ? Colors.grey.shade200
                  : Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8)),
          child: Text(
            displayText,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selectedValues.isEmpty && !isLoading
                    ? KTextColor
                    : KTextColor,
                fontSize: 9.5),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    ],
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
  String displayText;
  displayText = (fromValue == null || fromValue.isEmpty) &&
          (toValue == null || toValue.isEmpty)
      ? title
      : '${fromValue ?? s.from} - ${toValue ?? s.to} $unit'.trim();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!isFilter)
        Text(title,
            style: TextStyle(
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
                  fontWeight: (fromValue == null || fromValue.isEmpty) &&
                          (toValue == null || toValue.isEmpty)
                      ? FontWeight.w500
                      : FontWeight.w500,
                  color: (fromValue == null || fromValue.isEmpty) &&
                          (toValue == null || toValue.isEmpty)
                      ? KTextColor
                      : KTextColor,
                  fontSize: 9.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ),
      ),
    ],
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
            (_) => BorderSide(width: 1.0, color: borderColor),
          ),
        ),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                              fontSize: 14.sp)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _searchController,
                  style: TextStyle(color: KTextColor),
                  decoration: InputDecoration(
                    hintText: s.search,
                    prefixIcon: Icon(Icons.search, color: KTextColor),
                    hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Text(s.noResultsFound,
                              style: TextStyle(color: KTextColor)))
                      : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return CheckboxListTile(
                              title: Text(item,
                                  style: TextStyle(color: KTextColor)),
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
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
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
      return Expanded(
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            suffixIcon: suffix.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(suffix,
                        style: TextStyle(
                            color: KTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)))
                : null,
            suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: TextStyle(
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
              child: Text(s.apply,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: KPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
