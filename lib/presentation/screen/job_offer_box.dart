import 'package:advertising_app/data/job_data_dummy.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/job_offer_ads_provider.dart';
import 'package:advertising_app/presentation/providers/job_info_provider.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class JobOfferBox extends StatefulWidget {
  const JobOfferBox({super.key});

  @override
  State<JobOfferBox> createState() => _JobOfferBoxState();
}

class _JobOfferBoxState extends State<JobOfferBox> with FavoritesHelper<JobOfferBox> {

  // +++ تم تحديث المتغيرات لتناسب الأنواع الجديدة للحقول +++
  List<String> _selectedCategories = [];
  List<String> _selectedSections = [];
  bool _isPriceSortingEnabled = false;

  @override
  void initState() {
    super.initState();
    // جلب بيانات عروض الوظائف عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobOfferAdsProvider>().fetchOfferAds();
      // جلب القيم الحقيقية للاختيارات وصور الفئات من مزود معلومات الوظائف
      context.read<JobInfoProvider>().fetchJobAdValues();
    });
    loadFavoriteIds();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSize = getCardSize(screenWidth);
    final s = S.of(context);

    return Directionality(
        textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),

                      // Back Button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Row(
                          children: [
                            const SizedBox(width: 18),
                            Icon(Icons.arrow_back_ios,
                                color: KTextColor, size: 17.sp),
                            Transform.translate(
                              offset: Offset(-3.w, 0),
                              child: Text(
                                S.of(context).back,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: KTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 7.h),

                      // Title
                      Center(
                        child: Text(
                          "Offers Box",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.sp,
                            color: KTextColor,
                          ),
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // +++ صف الفلاتر المحدث +++
                      Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                        child: Container(
                          height: 35.h,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/filter.svg',
                                width: 25.w,
                                height: 25.h,
                              ),
                              SizedBox(width: 12.w),
                                  Expanded(
                                    child: Consumer<JobInfoProvider>(
                                      builder: (context, infoProvider, _) {
                                        final categoryItems = infoProvider.categoryTypes;
                                        final sectionItems = infoProvider.sectionTypes;
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: _buildMultiSelectField(
                                                context,
                                                S.of(context).category,
                                                _selectedCategories,
                                                categoryItems.isNotEmpty ? categoryItems : const <String>[],
                                                (selection) {
                                                  setState(() => _selectedCategories = selection);
                                                  context.read<JobOfferAdsProvider>().updateSelectedCategories(selection);
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
                                                sectionItems.isNotEmpty ? sectionItems : const <String>[],
                                                (selection) {
                                                  setState(() => _selectedSections = selection);
                                                  context.read<JobOfferAdsProvider>().updateSelectedSections(selection);
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
                        ),
                      ),

                      SizedBox(height: 6.h),

                      // Second Row
                      Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            bool isSmallScreen =
                                MediaQuery.of(context).size.width <= 370;

                             return Row(
                                children: [
                                  Consumer<JobOfferAdsProvider>(
                                    builder: (context, provider, _) {
                                      return Text(
                                        '${S.of(context).ad} ${provider.offerAds.length}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: KTextColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: isSmallScreen ? 40.w : 35.w),
                                  Expanded(
                                    child: Container(
                                      height: 37.h,
                                      padding: EdgeInsetsDirectional.symmetric(
                                          horizontal: 8.w),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color(0xFF08C2C9)),
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/locationicon.svg',
                                            width: 18.w,
                                            height: 18.h,
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Text(
                                              S.of(context).sort,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: KTextColor,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 1.w),
                                          SizedBox(
                                            width: 35.w,
                                            child: Transform.scale(
                                              scale: 0.8,
                                              child: Switch(
                                                value: _isPriceSortingEnabled,
                                                onChanged: (val) {
                                                  setState(() => _isPriceSortingEnabled = val);
                                                  // يمكن تطبيق ترتيب محلي هنا إن لزم
                                                },
                                                activeColor: Colors.white,
                                                activeTrackColor:
                                                    const Color.fromRGBO(
                                                        8, 194, 201, 1),
                                                inactiveThumbColor:
                                                    Colors.white,
                                                inactiveTrackColor:
                                                    Colors.grey[300],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                          },
                        ),
                      ),
                      SizedBox(height: 5.h),
                    ],
                  ),

                  // Grid Section - Scrollable (باستخدام بيانات المزود)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Consumer<JobOfferAdsProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoadingOffers) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (provider.offersError != null && provider.offersError!.isNotEmpty) {
                          return Center(child: Text('حدث خطأ: ${provider.offersError}'));
                        }
                        if (provider.offerAds.isEmpty) {
                          return const Center(child: Text('لا توجد نتائج متاحة حاليًا'));
                        }

                        final ads = provider.offerAds;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ads.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 6,
                            childAspectRatio: .89,
                          ),
                          itemBuilder: (context, index) {
                            final ad = ads[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                width: cardSize.width.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 5.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Stack(children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4.r),
                                        child: Builder(
                                          builder: (context) {
                                            final infoProvider = context.read<JobInfoProvider>();
                                            final imageKey = (ad.categoryType?.trim().toLowerCase() == 'job offer') ? 'job_offer' : 'job_seeker';
                                            final imagePath = infoProvider.categoryImages[imageKey] ?? '';
                                            final imageUrl = ImageUrlHelper.getFullImageUrl(imagePath);
                                            return CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              height: (cardSize.height * 0.6).h,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: Colors.grey[300],
                                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              ),
                                              errorWidget: (context, url, error) => Image.asset(
                                                'assets/images/jobs.jpg',
                                                height: (cardSize.height * 0.6).h,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: buildFavoriteIcon(
                                          ad,
                                          onAddToFavorite: () {},
                                          onRemoveFromFavorite: null,
                                        ),
                                      ),
                                    ]),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text("${NumberFormatter.formatPrice(ad.salary) ?? ''}", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12.sp)),
                                            Text(ad.job_name!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, color: KTextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(ad.advertiserName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, color: KTextColor)),
                                            Row(children: [
                                              SvgPicture.asset('assets/icons/Vector.svg', width: 10.5.w, height: 13.5.h),
                                              SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  '${ad.emirate ?? ''} ${ad.district ?? ''}',
                                                  style: TextStyle(fontSize: 12.sp, color: Color.fromRGBO(0, 30, 91, .75), fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20,)
                ],
              ),
            ),
          ),
        ));
  }
}

Size getCardSize(double screenWidth) {
  if (screenWidth <= 320) {
    return const Size(120, 140);
  } else if (screenWidth <= 375) {
    return const Size(135, 150);
  } else if (screenWidth <= 430) {
    return const Size(150, 160);
  } else {
    return const Size(165, 175);
  }
}

// ... (باقي الكود ودوال المساعدة واللوحات السفلية تبقى كما هي)

Widget _buildMultiSelectField(BuildContext context, String title, List<String> selectedValues, List<String> allItems, Function(List<String>) onConfirm, {bool isFilter = false}) {
    final s = S.of(context);
    String displayText = selectedValues.isEmpty ? title : selectedValues.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         if(!isFilter) Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
         if(!isFilter) const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<List<String>>(
              context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (context) => _MultiSelectBottomSheet(title: title, items: allItems, initialSelection: selectedValues),
            );
            if (result != null) { onConfirm(result); }
          },
          child: Container(
            height: isFilter ? 35 : 48,
            width: double.infinity, 
            padding: const EdgeInsets.symmetric(horizontal: 8), 
            alignment: Alignment.center, 
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Text(
              displayText,
              style: TextStyle(
                fontWeight: selectedValues.isEmpty ? FontWeight.w500 : FontWeight.w500,
                color: selectedValues.isEmpty ? KTextColor : KTextColor,
                fontSize: 10.5
              ),
              overflow: TextOverflow.ellipsis, maxLines: 1,
            ),
          ),
        ),
      ],
    );
}

class _MultiSelectBottomSheet extends StatefulWidget {
  final String title; final List<String> items; final List<String> initialSelection;
  const _MultiSelectBottomSheet({Key? key, required this.title, required this.items, required this.initialSelection}) : super(key: key);
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
      _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList();
    });
  }
  void _onItemTapped(String item) {
    setState(() {
      if (_selectedItems.contains(item)) { _selectedItems.remove(item); } 
      else { _selectedItems.add(item); }
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _searchController,
                  style: TextStyle(color: KTextColor), 
                  decoration: InputDecoration(
                    hintText: s.search, prefixIcon: Icon(Icons.search, color: KTextColor),
                    hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 8), const Divider(),
                Expanded(
                  child: _filteredItems.isEmpty 
                    ? Center(child: Text(s.noResultsFound, style: TextStyle(color: KTextColor)))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return CheckboxListTile(
                            title: Text(item, style: TextStyle(color: KTextColor)),
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
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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