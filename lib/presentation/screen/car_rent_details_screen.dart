import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/car_rent_ad_model.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:readmore/readmore.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/presentation/widget/location_map.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

class CarRentDetailsScreen extends StatefulWidget {
  final CarRentAdModel car_rent;
  const CarRentDetailsScreen({super.key, required this.car_rent});

  @override
  State<CarRentDetailsScreen> createState() => _car_rentRentDetailsScreenState();
}

class _car_rentRentDetailsScreenState extends State<CarRentDetailsScreen> with FavoritesHelper {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadFavoriteIds(); // Load favorite IDs when screen initializes
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    final car_rent = widget.car_rent;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBodyBehindAppBar: true, // يخلي الخلفية ورا الستاتس بار

          backgroundColor: Colors.white, // اجعل خلفية الـ Scaffold شفافة

          body: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 290.h,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: (car_rent.mainImage != null && car_rent.mainImage!.isNotEmpty ? 1 : 0) + car_rent.thumbnailImages.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          String imageUrl = '';
                          
                          // إعطاء الأولوية للصورة الرئيسية أولاً
                          if (index == 0 && car_rent.mainImage != null && car_rent.mainImage!.isNotEmpty) {
                            imageUrl = ImageUrlHelper.getMainImageUrl(car_rent.mainImage!);
                          } else {
                            // حساب الفهرس الصحيح للصور المصغرة
                            int thumbnailIndex = car_rent.mainImage != null && car_rent.mainImage!.isNotEmpty ? index - 1 : index;
                            if (thumbnailIndex >= 0 && thumbnailIndex < car_rent.thumbnailImages.length) {
                              imageUrl = ImageUrlHelper.getThumbnailImageUrls(car_rent.thumbnailImages)[thumbnailIndex];
                            }
                          }
                          
                          if (imageUrl.isEmpty) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            );
                          }
                          
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: 40.h,
                      left: isArabic ? null : 15.w,
                      right: isArabic ? 15.w : null,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Row(
                            children: [
                              const SizedBox(width: 2),
                              SizedBox(
                                width: 15,
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              Text(
                                S.of(context).back,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Favorite icon
                    Positioned(
                      top: 40.h,
                      left: isArabic ? 16.w : null,
                      right: isArabic ? null : 16.w,
                      child: buildFavoriteIcon(
                        CarRentAdItemAdapter(car_rent),
                        onAddToFavorite: () {
                          // Add to favorites callback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إضافة الإعلان للمفضلة')),
                          );
                        },
                        onRemoveFromFavorite: null, // No delete callback for details screen
                      ),
                    ),

                    Positioned(
                      top: 80.h,
                      left: isArabic ? 16.w : null,
                      right: isArabic ? null : 16.w,
                      child: Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                    // Page indicator dots
                    Positioned(
                      bottom: 12.h,
                      left: MediaQuery.of(context).size.width / 2 -
                          (((car_rent.mainImage != null && car_rent.mainImage!.isNotEmpty ? 1 : 0) + car_rent.thumbnailImages.length) * 10.w / 2),
                      child: Row(
                        children: List.generate((car_rent.mainImage != null && car_rent.mainImage!.isNotEmpty ? 1 : 0) + car_rent.thumbnailImages.length, (index) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 2.w),
                            width: 7.w,
                            height: 7.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),
                    // Image counter
                    Positioned(
                      bottom: 12.h,
                      right: isArabic ? 16.w : null,
                      left: isArabic ? null : 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${_currentPage + 1}/${(car_rent.mainImage != null && car_rent.mainImage!.isNotEmpty ? 1 : 0) + car_rent.thumbnailImages.length}',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12.sp),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/priceicon.svg',
                                  width: 24.w,
                                  height: 19.h,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  '${NumberFormatter.formatPrice(widget.car_rent.price)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.red,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  widget.car_rent.createdAt?.split('T').first ?? 'null',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "${widget.car_rent.make} ${widget.car_rent.model} ${widget.car_rent.trim} ${widget.car_rent.year}",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor,
                              ),
                            ),
                            SizedBox(height: 6.h),
                          
           Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLabelWithValue("Day Rent", widget.car_rent.dayRent),
                    const SizedBox(width: 16),
                    _buildLabelWithValue("Month Rent", widget.car_rent.monthRent),
                  ],
                ),
             
                       SizedBox(height: 6.h),
                            Text(
                              widget.car_rent.title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: KTextColor,
                              ),
                            ),
                            
                            // SizedBox(height: 6.h),
                            // Row(
                            //   children: [
                            //     SvgPicture.asset(
                            //       'assets/icons/locationicon.svg',
                            //       width: 20.w,
                            //       height: 18.h,
                            //     ),
                            //     SizedBox(width: 6.w),
                            //     Expanded(
                            //       child: Text(
                            //         "${widget.car_rent.emirate}/${widget.car_rent.area}",
                            //         style: TextStyle(
                            //           fontSize: 14.sp,
                            //           color: KTextColor,
                            //           fontWeight: FontWeight.w500,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            //SizedBox(height: 1.h),
                          ],
                        ),
                      ),

                   
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      Text(
                        S.of(context).car_details,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: KTextColor,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      GridView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: Localizations.localeOf(context).languageCode == 'ar'
                         ? MediaQuery.of(context).size.height * 0.09.h
                         : MediaQuery.of(context).size.height * 0.08.h,
                          crossAxisSpacing: 30.w,
                        ),
                        children: [
                          _buildDetailBox(
                              S.of(context).car_type, widget.car_rent.carType ?? 'null'),
                          _buildDetailBox(
                              S.of(context).trans_type, widget.car_rent.transType ?? "null"),
                          _buildDetailBox(
                              S.of(context).color, widget.car_rent.color ?? "null"),
                          _buildDetailBox(S.of(context).interior_color,
                            widget.car_rent.interior_color ??  "null"),
                          _buildDetailBox(
                              S.of(context).fuel_type, widget.car_rent.fuelType ?? "null"),
                           _buildDetailBox(S.of(context).seats_no,
                              widget.car_rent.seats_no ?? "null"),
                          ],
                      ),
                      // SizedBox(height: 1.h),
                       Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                Text(S.of(context).description, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: KTextColor)),
                SizedBox(height: 20.h),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: ReadMoreText(
                          widget.car_rent.description ?? "null",
                          trimLines: 5,
                          colorClickableText: Color.fromARGB(255, 9, 37, 108),
                          trimMode: TrimMode.Line,
                          trimCollapsedText: S.of(context).read_more,
                          lessStyle: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 9, 37, 108),
                          ),
                          trimExpandedText: '  ${S.of(context).show_less}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: KTextColor,
                          ),
                          moreStyle: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 9, 37, 108),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
                  Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                
                      Text(
                        S.of(context).location,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: KTextColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/locationicon.svg',
                              width: 20.w,
                              height: 20.h,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                widget.car_rent.location??'null' ,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: KTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                LocationMap(
                  address: widget.car_rent.location ?? '${widget.car_rent.emirate} ${widget.car_rent.area ?? ''}',
                  markerTitle: widget.car_rent.title,
                  height: 188.h,
                ),
                SizedBox(height: 10.h),
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      Row(
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Container(
                              height: 63.h,
                              width: 78.w,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(
                                //   "Agent",
                                //   style: TextStyle(
                                //     fontSize: 16.sp,
                                //     fontWeight: FontWeight.w600,
                                //     color: KTextColor,
                                //   ),
                                // ),
                                SizedBox(height: 2.h),
                                Text(
                                  car_rent.advertiserName,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: KTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                GestureDetector(
                                  onTap: () =>  context.push('/all_ad_car_rent'),
                                  child: Text(
                                    S.of(context).view_all_ads,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF08C2C9),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF08C2C9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Column(
                              children: [
                                _buildActionIcon(FontAwesomeIcons.whatsapp),
                                SizedBox(height: 5.h),
                                _buildActionIcon(Icons.phone),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      SizedBox(height: 7.h),
                      Center(
                        child: Text(
                          S.of(context).report_this_ad,
                          style: TextStyle(
                            color: KTextColor,
                            fontSize: 16.sp,
                            decoration: TextDecoration.underline,
                            decorationColor: KTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        height: 110.h,
                        padding: EdgeInsets.symmetric(
                            vertical: 20.h, horizontal: 15.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFE4F8F6),
                              Color(0xFFC9F8FE),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            S.of(context).use_this_space_for_ads,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: KTextColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox(String title, String? value) {
    // Handle null values by showing the field name with "null"
    final displayValue = (value == null || value.isEmpty || value.toLowerCase() == 'null') 
        ? "$title: null" 
        : value;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            color: KTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 3.5.h),
        Container(
          padding: EdgeInsets.all(8.w),
          width: double.infinity,
          height: 38.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF08C2C9)),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
              color: (value == null || value.isEmpty || value.toLowerCase() == 'null') 
                  ? Colors.grey 
                  : KTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return GestureDetector(
      onTap: () {
        if (icon == FontAwesomeIcons.whatsapp) {
          // وظيفة الواتساب
          final phoneNumber = widget.car_rent.whatsapp;
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            final whatsappUrl = PhoneNumberFormatter.getWhatsAppUrl(phoneNumber);
            _launchUrl(whatsappUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("WhatsApp number not available")),
            );
          }
        } else if (icon == Icons.phone) {
          // وظيفة الاتصال
          final phoneNumber = widget.car_rent.phoneNumber;
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            final telUrl = PhoneNumberFormatter.getTelUrl(phoneNumber);
            _launchUrl(telUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Phone number not available")),
            );
          }
        }
      },
      child: Container(
        height: 40.h,
        width: 63.w,
        decoration: BoxDecoration(
          color: Color(0xFF01547E),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 20.sp),
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

  Widget _buildLabelWithValue(String label, String? value) {
    // Handle null values by showing the field name with "null"
    final displayValue = (value == null || value.isEmpty || value.toLowerCase() == 'null') 
        ? "$label: null" 
        : value!.split('.')[0];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label ",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(0, 30, 90, 1),
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: (value == null || value.isEmpty || value.toLowerCase() == 'null') 
                  ? Colors.grey 
                  : const Color.fromRGBO(0, 30, 90, 1),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// Adapter class to make CarRentAdModel compatible with FavoriteItemInterface
class CarRentAdItemAdapter implements FavoriteItemInterface {
  final CarRentAdModel _carRent;
  
  CarRentAdItemAdapter(this._carRent);
  
  @override
  String get id => _carRent.id.toString();
  
  @override
  String get contact => _carRent.advertiserName;
  
  @override
  String get details => _carRent.title;
  
  @override
  String get category => 'Car Rent';
  
  @override
  String get addCategory => _carRent.addCategory ?? 'Car Rent';
  
  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(_carRent.mainImage);
  
  @override
  List<String> get images => [
    if (_carRent.mainImage != null && _carRent.mainImage!.isNotEmpty)
      ImageUrlHelper.getMainImageUrl(_carRent.mainImage!),
    ...ImageUrlHelper.getThumbnailImageUrls(_carRent.thumbnailImages)
  ].where((img) => img.isNotEmpty).toList();
  
  @override
  String get line1 => "Year: ${_carRent.year}  Km: ${NumberFormatter.formatNumber(_carRent.title)}   Specs: ${_carRent.area ?? ''}";
  
  @override
  String get line2 => _carRent.title;
  
  @override
  String get price => _carRent.price;
  
  @override
  String get location => "${_carRent.emirate}  ${_carRent.area ?? ''}".trim();
  
  @override
  String get title => "${_carRent.make} ${_carRent.model} ${_carRent.trim ?? ''}".trim();
  
  @override
  String get date => _carRent.createdAt?.split('T').first ?? '';
  
  @override
  bool get isPremium {
    if (_carRent.planType == null) return false;
    return _carRent.planType!.toLowerCase() != 'free';
  }
  
  @override
  AdPriority get priority {
    if (_carRent.planType == null || _carRent.planType!.toLowerCase() == 'free') {
      return AdPriority.free;
    }
    return AdPriority.premium;
  }
}