import 'package:advertising_app/data/model/restaurant_ad_model.dart';
import 'package:advertising_app/presentation/providers/restaurant_offers_provider.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);


class RestaurantOfferBox extends StatefulWidget {
  const RestaurantOfferBox({super.key});

  @override
  State<RestaurantOfferBox> createState() => _RestaurantOfferBoxState();
}

class _RestaurantOfferBoxState extends State<RestaurantOfferBox> with FavoritesHelper<RestaurantOfferBox> {
  
  // +++ تم تحديث المتغيرات لتناسب الأنواع الجديدة للحقول +++
  List<String> _selectedDistricts = [];
  List<String> _selectedCategories = [];
  String? _priceFrom, _priceTo;
  bool _isMapSortActive = false;

  @override
  void initState() {
    super.initState();
    loadFavoriteIds();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  Future<void> _refreshData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantOffersProvider>().fetchOfferAds();
    });
  }

  Widget _buildSimpleLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
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
            child: Consumer<RestaurantOffersProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Column(
                        children: [
                          _buildHeader(s),
                          SizedBox(height: 10.h),
                          _buildFiltersRow(s, provider),
                          SizedBox(height: 6.h),
                          _buildSortBar(s, provider.offerAds.length),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        child: provider.isLoadingOffers && provider.offerAds.isEmpty
                            ? _buildSimpleLoadingGrid()
                            : provider.offersError != null
                                ? Center(child: Text("خطأ: ${provider.offersError}"))
                                : provider.offerAds.isEmpty
                                    ? Center(child: Text("لا توجد عروض متاحة"))
                                    : _buildRestaurantGrid(provider.offerAds, cardSize),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ));
  }

  Widget _buildHeader(S s) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
              Transform.translate(
                  offset: Offset(-3.w, 0),
                  child: Text(s.back,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: KTextColor))),
            ],
          ),
        ),
        SizedBox(height: 7.h),
        Center(
            child: Text("Offers Box",
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 24.sp,
                    color: KTextColor))),
      ],
    );
  }

  Widget _buildFiltersRow(S s, RestaurantOffersProvider provider) {
    return Container(
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
            child: Row(
              children: [
                Expanded(
                  child: _buildMultiSelectField(
                    context, s.district, _selectedDistricts,
                    const ["Dubai", "Abu Dhabi", "Sharjah", "Ajman"],
                    (selection) {
                      setState(() => _selectedDistricts = selection);
                      provider.updateDistrictsFilter(selection);
                    }, isFilter: true),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: _buildRangePickerField(
                    context, title: s.price, fromValue: _priceFrom, toValue: _priceTo, unit: "AED", isFilter: true,
                    onTap: () async {
                      final result = await _showRangePicker(context, title: s.price, initialFrom: _priceFrom, initialTo: _priceTo, unit: "AED");
                      if (result != null) {
                        setState(() { _priceFrom = result['from']; _priceTo = result['to']; });
                        provider.updatePriceRangeForOffers(result['from'], result['to']);
                      }
                    }
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: _buildMultiSelectField(
                    context, s.category, _selectedCategories,
                    const ["Fast Food", "Italian", "Asian", "Desserts", "Arabic"],
                    (selection) {
                      setState(() => _selectedCategories = selection);
                      provider.updateCategoriesFilter(selection);
                    }, isFilter: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar(S s, int adCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = MediaQuery.of(context).size.width <= 370;

        return Row(
          children: [
            Text(
              '${s.ad} $adCount',
              style: TextStyle(
                fontSize: 12.sp,
                color: KTextColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: isSmallScreen ? 40.w : 35.w),
            Expanded(
              child: Container(
                height: 37.h,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF08C2C9)),
                  borderRadius: BorderRadius.circular(8.r),
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
                        s.sort,
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
                          value: _isMapSortActive,
                          onChanged: (val) {
                            setState(() {
                              _isMapSortActive = val;
                            });
                          },
                          activeColor: Colors.white,
                          activeTrackColor: const Color.fromRGBO(8, 194, 201, 1),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey[300],
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
    );
  }

Widget _buildRestaurantGrid(List<RestaurantAdModel> ads, Size cardSize) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: GridView.builder(
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
                child: GestureDetector(
                  onTap: () {
                    context.push('/restaurant_details', extra: {'id': ad.id});
                  },
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
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: CachedNetworkImage(
                              imageUrl: ImageUrlHelper.getFullImageUrl(ad.mainImage),
                              height: (cardSize.height * 0.6).h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF08C2C9),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[400],
                                  size: 40.sp,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: buildFavoriteIcon(
                              RestaurantOfferItemAdapter(ad),
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "${ad.priceRange} AED",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                              Text(
                                ad.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                  color: KTextColor,
                                ),
                              ),
                              Text(
                                ad.advertiserName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                  color: KTextColor,
                                ),
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/Vector.svg',
                                    width: 10.5.w,
                                    height: 13.5.h,
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      "${ad.district}, ${ad.emirate}",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Color.fromRGBO(0, 30, 91, .75),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                ),
              );
            },
          )
        );
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
                fontSize: 9.5
              ),
              overflow: TextOverflow.ellipsis, maxLines: 1,
            ),
          ),
        ),
      ],
    );
}

Widget _buildRangePickerField(BuildContext context, {required String title, String? fromValue, String? toValue, required String unit, required VoidCallback onTap, bool isFilter = false}) {
    final s = S.of(context);
    String displayText;
      displayText = (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) 
          ? title
          : '${fromValue ?? s.from} - ${toValue ?? s.to} ${unit}'.trim();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(!isFilter) Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
        if(!isFilter) const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: isFilter ? 35 : 48, 
            width: double.infinity, 
            padding: const EdgeInsets.symmetric(horizontal: 8), 
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Text(displayText, style: TextStyle(
              fontWeight: (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) ? FontWeight.w500 : FontWeight.w500,
              color: (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) ? KTextColor : KTextColor,
              fontSize: 9.5), 
              overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ),
      ],
    );
  }

Future<Map<String, String?>?> _showRangePicker(BuildContext context, {required String title, String? initialFrom, String? initialTo, required String unit}) {
    return showModalBottomSheet<Map<String, String?>>(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _RangeSelectionBottomSheet(title: title, initialFrom: initialFrom, initialTo: initialTo, unit: unit),
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

class _RangeSelectionBottomSheet extends StatefulWidget {
  final String title; final String? initialFrom; final String? initialTo; final String unit;
  const _RangeSelectionBottomSheet({Key? key, required this.title, this.initialFrom, this.initialTo, required this.unit}) : super(key: key);
  @override
  __RangeSelectionBottomSheetState createState() => __RangeSelectionBottomSheetState();
}
class __RangeSelectionBottomSheetState extends State<_RangeSelectionBottomSheet> {
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
    
    Widget buildTextField(String hint, String suffix, TextEditingController controller) {
      return Expanded(
        child: TextFormField(
          controller: controller, keyboardType: TextInputType.number, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
            suffixIcon: suffix.isNotEmpty 
                ? Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(suffix, style: TextStyle(color: KTextColor, fontWeight: FontWeight.bold, fontSize: 12)))
                : null,
            suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white, filled: true,
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
            TextButton(
              onPressed: () { _fromController.clear(); _toController.clear(); setState(() {}); }, 
              child: Text(s.reset, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.sp))),
          ]),
          SizedBox(height: 16.h),
          Row(children: [
            buildTextField(s.from, widget.unit, _fromController),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(s.to, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14))),
            buildTextField(s.to, widget.unit, _toController),
          ]),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'from': _fromController.text, 'to': _toController.text}),
              child: Text(s.apply, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

// Adapter to make RestaurantAdModel compatible with FavoriteItemInterface
class RestaurantOfferItemAdapter implements FavoriteItemInterface {
  final RestaurantAdModel ad;

  RestaurantOfferItemAdapter(this.ad);

  @override
  String get id => ad.id.toString();

  @override
  String get title => ad.title;

  @override
  String get location => ("${ad.emirate} ${ad.district} ${ad.area ?? ''}").trim();

  @override
  String get price => ad.priceRange;

  @override
  String get line1 => ad.title;

  @override
  String get details => ad.description;

  @override
  String get date => ad.createdAt ?? '';

  @override
  String get contact => ad.phoneNumber;

  @override
  bool get isPremium => ad.planType == 'premium' || ad.activeOffersBoxStatus;

  @override
  List<String> get images => ad.thumbnailImagesUrls.isNotEmpty ? ad.thumbnailImagesUrls : ad.thumbnailImages;

  @override
  String get category => 'restaurant';

  @override
  String get addCategory => ad.addCategory;

  @override
  AdPriority get priority => isPremium ? AdPriority.premium : AdPriority.free;
}