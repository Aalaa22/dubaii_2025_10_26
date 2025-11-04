import 'package:advertising_app/data/model/car_rent_ad_model.dart';
import 'package:advertising_app/presentation/providers/car_rent_offers_provider.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class CarRentOfferBox extends StatefulWidget {
  const CarRentOfferBox({super.key});

  @override
  State<CarRentOfferBox> createState() => _CarRentOfferBoxState();
}

// Adapter class to make CarRentAdModel compatible with FavoriteItemInterface for Offers Box
class CarRentOfferItemAdapter implements FavoriteItemInterface {
  final CarRentAdModel _ad;
  CarRentOfferItemAdapter(this._ad);

  @override
  String get id => _ad.id.toString();

  @override
  String get contact => _ad.advertiserName;

  @override
  String get details => _ad.title;

  @override
  String get category => 'Cars Rent';

  @override
  String get addCategory => _ad.addCategory ?? 'Cars Rent';

  @override
  List<String> get images => [
        ImageUrlHelper.getMainImageUrl(_ad.mainImage),
        ...ImageUrlHelper.getThumbnailImageUrls(_ad.thumbnailImages)
      ].where((img) => img.isNotEmpty).toList();

  @override
  String get line1 =>
      "Day: ${_ad.dayRent}  Month: ${_ad.monthRent}   Trans: ${_ad.transType ?? ''}";

  @override
  String get location => "${_ad.emirate}  ${_ad.area ?? ''}".trim();

  @override
  String get price => _ad.price;

  @override
  String get title => "${_ad.make ?? ''} ${_ad.model ?? ''} ${_ad.trim ?? ''} ${_ad.year ?? ''}".trim();

  @override
  String get date => _ad.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium {
    if (_ad.planType == null) return false;
    return _ad.planType!.toLowerCase() != 'free';
  }

  @override
  AdPriority get priority {
    if (_ad.planType == null || _ad.planType!.toLowerCase() == 'free') {
      return AdPriority.free;
    }
    return AdPriority.premium;
  }
}

class _CarRentOfferBoxState extends State<CarRentOfferBox> with FavoritesHelper<CarRentOfferBox> {
  String? _yearFrom;
  String? _yearTo;
  String? _priceFrom;
  String? _priceTo;
  bool _isSortActive = false; // Add sort state variable with default false

  @override
  void initState() {
    super.initState();
    _refreshData();
    loadFavoriteIds();
  }

  Future<void> _refreshData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarRentOffersProvider>().fetchOfferAds();
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
        body: Consumer<CarRentOffersProvider>(
          builder: (context, provider, child) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(4),
                child: RefreshIndicator(
                  onRefresh: _refreshData,
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

                          // Filters Row
                          _buildFiltersRow(provider),

                          SizedBox(height: 6.h),

                          // Second Row
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                bool isSmallScreen =
                                    MediaQuery.of(context).size.width <= 370;

                                return Row(
                                  children: [
                                    Text(
                                      '${S.of(context).ad} ${provider.offerAds.length}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: KTextColor,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    SizedBox(
                                        width: isSmallScreen ? 40.w : 35.w),
                                    Expanded(
                                      child: Container(
                                        height: 37.h,
                                        padding:
                                            EdgeInsetsDirectional.symmetric(
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
                                                  value: _isSortActive,
                                                  onChanged: (val) {
                                                    setState(() {
                                                      _isSortActive = val;
                                                    });
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

                      // Grid Section - Scrollable
                      provider.isLoadingOffers
                          ? _buildSimpleLoadingGrid()
                          : provider.offersError != null
                              ? _buildErrorWidget(provider.offersError!)
                              : provider.offerAds.isEmpty
                                  ? _buildEmptyWidget()
                                  : _buildOffersGrid(provider.offerAds),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFiltersRow(CarRentOffersProvider provider) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
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
              child: Row(
                children: [
                  Expanded(
                    child: _buildRangePickerField(
                      context,
                      title: S.of(context).year,
                      fromValue: provider.offerYearFrom?.toString(),
                      toValue: provider.offerYearTo?.toString(),
                      unit: "",
                      isFilter: true,
                      onTap: () => _showYearRangePicker(provider),
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: _buildRangePickerField(
                      context,
                      title: S.of(context).price,
                      fromValue: provider.offerPriceFrom?.toString(),
                      toValue: provider.offerPriceTo?.toString(),
                      unit: "AED",
                      isFilter: true,
                      onTap: () => _showPriceRangePicker(provider),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showYearRangePicker(CarRentOffersProvider provider) async {
    final result = await _showRangePicker(
      context,
      title: S.of(context).year,
      initialFrom: provider.offerYearFrom?.toString(),
      initialTo: provider.offerYearTo?.toString(),
      unit: "",
    );
    if (result != null) {
      final fromYear = int.tryParse(result['from'] ?? '');
      final toYear = int.tryParse(result['to'] ?? '');
      provider.updateYearRangeForOffers(
          fromYear?.toString(), toYear?.toString());
    }
  }

  Widget _buildOffersGrid(List<CarRentAdModel> offers) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSize = getCardSize(screenWidth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: offers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          childAspectRatio: .9,
        ),
        itemBuilder: (context, index) {
          final car = offers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                context.push('/car-rent-details', extra: car);
              },
              child: Container(
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
                      child: CachedNetworkImage(
                        imageUrl:
                            ImageUrlHelper.getMainImageUrl(car.mainImage ?? ''),
                        height: (cardSize.height * 0.6).h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.directions_car,
                              size: 50, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.directions_car,
                              size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                    child: buildFavoriteIcon(
                      CarRentOfferItemAdapter(car),
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
                          Text(
                            '${NumberFormatter.formatPrice(car.price)}',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          ),
                          Text(
                            '${car.make} ${car.model} ${car.trim} ${car.year}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                              color: KTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            car.advertiserName ?? '',
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
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${car.emirate} ${car.area}' ?? '',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color.fromRGBO(0, 30, 91, .75),
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
          ));
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'لا توجد عروض متاحة',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على عروض تأجير سيارات',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  //  void _showYearRangePicker(CarRentOffersProvider provider) async {
  //    final result = await _showRangePicker(
  //      context,
  //      title: S.of(context).year,
  //      initialFrom: provider.offerYearFrom?.toString(),
  //     initialTo: provider.offerYearTo?.toString(),
  //      unit: "",
  //    );
  //    if (result != null) {
  //      final fromYear = int.tryParse(result['from'] ?? '');
  //      final toYear = int.tryParse(result['to'] ?? '');
  //      provider.updateYearRangeForOffers(fromYear?.toString(), toYear?.toString());
  //    }
  //  }

  void _showPriceRangePicker(CarRentOffersProvider provider) async {
    final result = await _showRangePicker(
      context,
      title: S.of(context).price,
      initialFrom: provider.offerPriceFrom?.toString(),
      initialTo: provider.offerPriceTo?.toString(),
      unit: "AED",
    );
    if (result != null) {
      final fromPrice = double.tryParse(result['from'] ?? '');
      final toPrice = double.tryParse(result['to'] ?? '');
      provider.updatePriceRangeForOffers(
          fromPrice?.toString(), toPrice?.toString());
    }
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
// ... (ودجت بناء الحقول)

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
      : '${fromValue ?? s.from} - ${toValue ?? s.to} ${unit}'.trim();

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
                  fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ),
      ),
    ],
  );
}

// Size getCardSize(double screenWidth) {
//   if (screenWidth <= 320) {
//     return const Size(120, 140);
//   } else if (screenWidth <= 375) {
//     return const Size(140, 160);
//   } else if (screenWidth <= 414) {
//     return const Size(160, 180);
//   } else {
//     return const Size(180, 200);
//   }
// }

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
