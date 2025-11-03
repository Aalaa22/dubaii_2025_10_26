// lib/presentation/screens/job_search_screen.dart

import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/job_ad_model.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/job_ad_provider.dart';
import 'package:advertising_app/presentation/providers/job_info_provider.dart';
import 'package:advertising_app/presentation/widget/custom_search2_card.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:advertising_app/presentation/widget/custome_search_job.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/constant/image_url_helper.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class JobSearchScreen extends StatefulWidget {
  final Map<String, String>? filters;
  const JobSearchScreen({super.key, this.filters});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingFilterBar = false;
  double _lastScrollOffset = 0;
  bool _isPriceSortingEnabled = false;

  List<String> _selectedCategories = [];
  List<String> _selectedSections = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = widget.filters;
      if (initial != null && initial.isNotEmpty) {
        context.read<JobAdProvider>().fetchAds(filters: initial);
      } else {
        context.read<JobAdProvider>().fetchAds();
      }
      context.read<JobInfoProvider>().fetchJobAdValues();
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

  Widget _buildFiltersRow() {
    return Container(
      height: 35.h,
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/filter.svg',
              width: 25.w, height: 25.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Consumer<JobInfoProvider>(
              builder: (context, info, _) {
                final categories = info.categoryTypes;
                final sections = info.sectionTypes;
                return Row(
                  children: [
                    Expanded(
                      child: _buildMultiSelectField(
                        context,
                        S.of(context).category,
                        _selectedCategories,
                        categories,
                        (selection) {
                          setState(() => _selectedCategories = selection);
                          context
                              .read<JobAdProvider>()
                              .updateSelectedCategories(selection);
                        },
                        isFilter: true,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: _buildMultiSelectField(
                        context,
                        S.of(context).section,
                        _selectedSections,
                        sections,
                        (selection) {
                          setState(() => _selectedSections = selection);
                          context
                              .read<JobAdProvider>()
                              .updateSelectedSections(selection);
                        },
                        isFilter: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark));
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<JobAdProvider>(builder: (context, provider, child) {
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
                    key: const PageStorageKey('job_search_scroll'),
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
                                      child: Text(s.jobs,
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
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              bool isSmallScreen =
                                  MediaQuery.of(context).size.width <= 370;
                              return Row(children: [
                                Text('${s.ad} ${provider.ads.length}',
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
                                                      value:
                                                          _isPriceSortingEnabled,
                                                      onChanged: (val) {
                                                        setState(() =>
                                                            _isPriceSortingEnabled =
                                                                val);
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
                            })),
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
                                  child: Text(s.noResultsFound)))
                        else ...[
                          _buildAdList(
                              s.priority_first_premium, premiumStarAds),
                          _buildAdList(s.priority_premium, premiumAds),
                          _buildAdList(s.priority_featured, featuredAds),
                          _buildAdList(s.priority_free, freeAds)
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
                                    child: Text(S.of(context).back,
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: KTextColor)))
                              ])),
                          SizedBox(height: 8.h),
                          _buildFiltersRow(),
                          SizedBox(height: 4.h),
                          LayoutBuilder(builder: (context, constraints) {
                            bool isSmallScreen =
                                MediaQuery.of(context).size.width <= 370;
                            return Row(children: [
                              Text('${S.of(context).ad} ${provider.ads.length}',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: KTextColor,
                                      fontWeight: FontWeight.w400)),
                              SizedBox(width: isSmallScreen ? 35.w : 30.w),
                              Expanded(
                                  child: Container(
                                      height: 37.h,
                                      padding: EdgeInsetsDirectional.symmetric(
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
                                            width: isSmallScreen ? 12.w : 15.w),
                                        Expanded(
                                            child: Text(S.of(context).sort,
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
                                                    value:
                                                        _isPriceSortingEnabled,
                                                    onChanged: (val) {
                                                      setState(() =>
                                                          _isPriceSortingEnabled =
                                                              val);
                                                    },
                                                    activeColor: Colors.white,
                                                    activeTrackColor:
                                                        const Color(0xFF08C2C9),
                                                    inactiveThumbColor:
                                                        isSmallScreen
                                                            ? Colors.white
                                                            : Colors.grey,
                                                    inactiveTrackColor:
                                                        Colors.grey[300])))
                                      ])))
                            ]);
                          }),
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

  Widget _buildAdList(String title, List<JobAdModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle(title),
      ...items.map((item) => _buildCard(item)).toList()
    ]);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        child: Row(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: KTextColor)),

                    
          ],
        ));
  }

  Widget _buildCard(JobAdModel item) {
    final provider = context.read<JobAdProvider>();

    // ++ التصحيح هنا: نجعل المقارنة غير حساسة لحالة الأحرف والمسافات ++
    final imageKey = (item.categoryType?.trim().toLowerCase() == 'job offer')
        ? 'job_offer'
        : 'job_seeker';

    final imagePath = provider.categoryImages[imageKey] ?? '';
    final imageUrl = ImageUrlHelper.getFullImageUrl(imagePath);

    return GestureDetector(
      onTap: () {
        context.push('/job-details/${item.id}');
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SearchCardJob(
          customImageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          showLine1: true,
          customLine1Span: TextSpan(children: [
            WidgetSpan(
                child: Text(item.line1,
                    style: const TextStyle(
                        color: Color.fromRGBO(0, 30, 90, 1),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)))
          ]),
          item: item,
          showDelete: false,
          onAddToFavorite: () {},
          onDelete: () {},
          customActionButtons: const [], // قائمة فارغة لإخفاء الأزرار
          customBottomWidget:
              item.contactInfo != null && item.contactInfo!.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 4.h),
                      child: Text("Contact: ${item.contactInfo!}",
                          maxLines: 1, // تحديد سطرين
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: KTextColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600)),
                    )
                  : null,
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
    {bool isFilter = false}) {
  final s = S.of(context);
  String displayText =
      selectedValues.isEmpty ? title : selectedValues.join(', ');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!isFilter)
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
      if (!isFilter) const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
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
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8)),
          child: Text(displayText,
              style: TextStyle(
                  fontWeight: selectedValues.isEmpty
                      ? FontWeight.w500
                      : FontWeight.w500,
                  color: KTextColor,
                  fontSize: 9.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ),
      ),
    ],
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
                  (_) => BorderSide(width: 1.0, color: borderColor)))),
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
                    style: const TextStyle(color: KTextColor),
                    decoration: InputDecoration(
                        hintText: s.search,
                        prefixIcon: const Icon(Icons.search, color: KTextColor),
                        hintStyle:
                            TextStyle(color: KTextColor.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: KPrimaryColor, width: 2)))),
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
                                checkColor: Colors.white,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (_) => _onItemTapped(item));
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
                              borderRadius: BorderRadius.circular(8)))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
