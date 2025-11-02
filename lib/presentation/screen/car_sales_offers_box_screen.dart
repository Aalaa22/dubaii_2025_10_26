import 'package:advertising_app/data/model/car_ad_model.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// تعريف الثوابت
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class OffersBoxScreen extends StatefulWidget {
  const OffersBoxScreen({super.key});

  @override
  State<OffersBoxScreen> createState() => _OffersBoxScreenState();
}

class _OffersBoxScreenState extends State<OffersBoxScreen> with FavoritesHelper<OffersBoxScreen> {
  bool _isMapSortActive = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
    // تحميل معرفات الإعلانات الموجودة بالمفضلة لتحديث الأيقونة
    loadFavoriteIds();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    _refreshData();
  }

  Future<void> _refreshData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarAdProvider>().fetchOfferAds();
    });
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<CarAdProvider>(
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
                      child: provider.isLoadingOffers &&
                            provider.offerAds.isEmpty
                        ? _buildSimpleLoadingGrid()
                        : provider.offersError != null
                            ? Center(child: Text("خطأ: ${provider.offersError}"))
                            : provider.offerAds.isEmpty
                                ? Center(child: Text("لا توجد عروض متاحة"))
                                : GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      itemCount: provider.offerAds.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        childAspectRatio: cardSize.width /
                                            (cardSize.height * 1.25),
                                      ),
                                      itemBuilder: (context, index) {
                                        final car = provider.offerAds[index];
                                        return _buildAdCard(car, cardSize);
                                      },
                                    ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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

  Widget _buildFiltersRow(S s, CarAdProvider provider) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvgPicture.asset('assets/icons/filter.svg',
              width: 25.w, height: 25.h),
          SizedBox(width: 12.w),
          Expanded(
              child: _buildRangePickerField(context,
                  title: s.year,
                  fromValue: provider.offerYearFrom,
                  toValue: provider.offerYearTo,
                  unit: "",
                  isFilter: true, onTap: () async {
            final result = await _showRangePicker(context,
                title: s.year,
                initialFrom: provider.offerYearFrom,
                initialTo: provider.offerYearTo,
                unit: "");
            if (result != null) {
              provider.updateYearRangeForOffers(result['from'], result['to']);
            }
          })),
          SizedBox(width: 7.w),
          Expanded(
              child: _buildRangePickerField(context,
                  title: s.km,
                  fromValue: provider.offerKmFrom,
                  toValue: provider.offerKmTo,
                  unit: "KM",
                  isFilter: true, onTap: () async {
            final result = await _showRangePicker(context,
                title: s.km,
                initialFrom: provider.offerKmFrom,
                initialTo: provider.offerKmTo,
                unit: "KM");
            if (result != null) {
              provider.updateKmRangeForOffers(result['from'], result['to']);
            }
          })),
          SizedBox(width: 7.w),
          Expanded(
              child: _buildRangePickerField(context,
                  title: s.price,
                  fromValue: provider.offerPriceFrom,
                  toValue: provider.offerPriceTo,
                  unit: "AED",
                  isFilter: true, onTap: () async {
            final result = await _showRangePicker(context,
                title: s.price,
                initialFrom: provider.offerPriceFrom,
                initialTo: provider.offerPriceTo,
                unit: "AED");
            if (result != null) {
              provider.updatePriceRangeForOffers(result['from'], result['to']);
            }
          })),
        ],
      ),
    );
  }

  Widget _buildSortBar(S s, int totalAds) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen = screenWidth <= 370;
    return Row(
      children: [
        Text('${s.ad} $totalAds',
            style: TextStyle(
                fontSize: 12.sp,
                color: KTextColor,
                fontWeight: FontWeight.w400)),
        SizedBox(width: isSmallScreen ? 35.w : 40.w),
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
                  scale: isSmallScreen ? 0.8 : 0.9,
                  child: Switch(
                      value: _isMapSortActive,
                      onChanged: (val) {
                        setState(() => _isMapSortActive = val);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: const Color.fromRGBO(8, 194, 201, 1),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[300]),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildAdCard(CarAdModel car, Size cardSize) {
    return GestureDetector(
        onTap: () => context.push('/car-details/${car.id}'),
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children:[ ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                  child: CachedNetworkImage(
                    imageUrl: ImageUrlHelper.getFullImageUrl(car.mainImage),
                    height: (cardSize.height * 0.55).h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: (cardSize.height * 0.55).h,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                     height: (cardSize.height * 0.6).h,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child:
                          Image.asset('assets/images/car.jpg', fit: BoxFit.cover),
                    ),
                  ),
                ),


                 Positioned(
              top: 8,
              right: 8,
              child: buildFavoriteIcon(
                CarAdOfferItemAdapter(car),
                onAddToFavorite: () {},
                onRemoveFromFavorite: null,
              ),
            ),
        
             ] ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       SizedBox(height: 5,),
                      Text(NumberFormatter.formatPrice(car.price),
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp)),
                      SizedBox(height: 5,),
                     
                      Text("${car.make} ${car.model} ${car.trim}",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                              color: KTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),

                          SizedBox(height: 5,),
                      Row(
                        children: [
                          Text(car.year,
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color.fromRGBO(165, 164, 162, 1),
                                  fontWeight: FontWeight.w600)),
                          SizedBox(width: 8.w),
                          Expanded(
                              child: Text(
                                  NumberFormatter.formatKilometers(car.km),
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color.fromRGBO(
                                          165, 164, 162, 1),
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      SizedBox(height: 5,),
                      Text(car.advertiserName,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                              color: KTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      
                       SizedBox(height: 5,),
                      Row(
                        children: [
                          SvgPicture.asset('assets/icons/Vector.svg',
                              width: 10.5.w, height: 13.5.h),
                          const SizedBox(width: 5),
                          Text(car.emirate,
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Color.fromRGBO(0, 30, 91, .75),
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(width: 5),
                          Text(car.area.toString(),
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Color.fromRGBO(0, 30, 91, .75),
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis)
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

Size getCardSize(double screenWidth) {
  if (screenWidth <= 320) {
    return const Size(120, 115);
  } else if (screenWidth <= 375) {
    return const Size(135, 115);
  } else if (screenWidth <= 430) {
    return const Size(150, 130);
  } else {
    return const Size(165, 140);
  }
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
      : '${fromValue ?? s.from} - ${toValue ?? s.to} ${unit}'.trim();
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8)),
      child: Text(displayText,
          style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w500,
              color: KTextColor),
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

// Adapter class to make CarAdModel compatible with FavoriteItemInterface for Offers Box
class CarAdOfferItemAdapter implements FavoriteItemInterface {
  final CarAdModel _ad;
  CarAdOfferItemAdapter(this._ad);

  @override
  String get id => _ad.id.toString();

  @override
  String get contact => _ad.advertiserName;

  @override
  String get details => _ad.title;

  @override
  String get category => 'Cars Sales';

  @override
  String get addCategory => _ad.addCategory ?? 'Cars Sales';

  @override
  List<String> get images => [
        ImageUrlHelper.getMainImageUrl(_ad.mainImage),
        ...ImageUrlHelper.getThumbnailImageUrls(_ad.thumbnailImages)
      ].where((img) => img.isNotEmpty).toList();

  @override
  String get line1 =>
      "Year: ${_ad.year}  Km: ${NumberFormatter.formatNumber(_ad.km)}   Specs: ${_ad.specs ?? ''}";

  @override
  String get location => "${_ad.emirate}  ${_ad.area ?? ''}".trim();

  @override
  String get price => _ad.price;

  @override
  String get title => "${_ad.make} ${_ad.model} ${_ad.trim ?? ''}".trim();

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
