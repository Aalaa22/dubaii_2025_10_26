import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:readmore/readmore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/presentation/widget/location_map.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

class CarServiceDetails extends StatefulWidget {
  final CarServiceModel car_service;
  const CarServiceDetails({super.key, required this.car_service});

  @override
  State<CarServiceDetails> createState() => _CarServiceDetailsState();
}

class _CarServiceDetailsState extends State<CarServiceDetails> with FavoritesHelper {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadFavoriteIds(); // Load favorite IDs when screen initializes
  }

  // Function to format price by removing decimals and adding comma separators
  String _formatPrice(String price) {
    try {
      // Remove any existing decimal points and convert to integer
      double priceValue = double.parse(price);
      int intPrice = priceValue.toInt();
      
      // Add comma separators every 3 digits
      String formattedPrice = intPrice.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      
      return formattedPrice;
    } catch (e) {
      // If parsing fails, return original price
      return price;
    }
  }

  // Function to launch WhatsApp
  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Clean phone number by removing any non-digit characters
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If number is empty or invalid, use a default message to open WhatsApp
    String whatsappUrl;
    if (cleanedNumber.isEmpty) {
      // Open WhatsApp with invitation message
      whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent('مرحباً، أريد التواصل معك بخصوص الخدمة المعروضة')}';
    } else {
      // Open WhatsApp with specific number and invitation message
      whatsappUrl = 'https://wa.me/$cleanedNumber?text=${Uri.encodeComponent('مرحباً، أريد التواصل معك بخصوص الخدمة المعروضة')}';
    }
    
    final Uri whatsappUri = Uri.parse(whatsappUrl);
    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If WhatsApp is not installed, try to open web version
      final Uri webWhatsappUri = Uri.parse('https://web.whatsapp.com/');
      await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  // Function to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
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
    final car_service = widget.car_service;
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
                      // اعرض الصور بنفس منطق بطاقة البحث: PageView مع قص الحواف وصورة مغطية بعرض كامل
                      child: (car_service.thumbnailImages.isNotEmpty || car_service.mainImage != null)
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: car_service.thumbnailImages.isNotEmpty
                                  ? car_service.thumbnailImages.length
                                  : 1,
                              onPageChanged: (index) =>
                                  setState(() => _currentPage = index),
                              itemBuilder: (context, index) {
                                final String imagePath = car_service.thumbnailImages.isNotEmpty
                                    ? car_service.thumbnailImages[index]
                                    : car_service.mainImage!;
                                return ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: ImageUrlHelper.getFullImageUrl(imagePath),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    width: double.infinity,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
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
                        CarServiceAdItemAdapter(widget.car_service),
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
                    // Page indicator dots - only show if there are multiple thumbnail images
                    if (car_service.thumbnailImages.length > 1)
                      Positioned(
                        bottom: 12.h,
                        left: MediaQuery.of(context).size.width / 2 -
                            (car_service.thumbnailImages.length * 10.w / 2),
                        child: Row(
                          children: List.generate(car_service.thumbnailImages.length, (index) {
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
                    // Image counter - only show if there are multiple thumbnail images
                    if (car_service.thumbnailImages.length > 1)
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
                            '${_currentPage + 1}/${car_service.thumbnailImages.length}',
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
                                  "${_formatPrice(widget.car_service.price)} AED",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.red,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  widget.car_service.createdAt?.split('T').first ??  'N/A',
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
                              widget.car_service.serviceName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor,
                              ),
                            ),
                            
                            SizedBox(height: 6.h),
                            Text(
                              widget.car_service.title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.car_service.serviceType,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6.h),
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
                            //         "${widget.car_service.emirate} ${widget.car_service.district}  ${widget.car_service.area} ",
                            //         style: TextStyle(
                            //           fontSize: 14.sp,
                            //           color: KTextColor,
                            //           fontWeight: FontWeight.w500,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            
                            SizedBox(height: 5.h),
                          ],
                        ),
                      ),
                      
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      Text(
                        S.of(context).description,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: KTextColor,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: ReadMoreText(
                          widget.car_service.description,
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
                            height: 1.4, // Reduced line height for better spacing
                          ),
                          moreStyle: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 9, 37, 108),
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h), // Reduced spacing after description
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
                                widget.car_service.location ?? '',
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
                        address: widget.car_service.location ?? '',
                        markerTitle: widget.car_service.title,
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
                                  car_service.advertiserName,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: KTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                GestureDetector(
                                  onTap: () => context.push('/AllAddsCarService'),
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
                                GestureDetector(
                                  onTap: () => _launchWhatsApp(widget.car_service.whatsapp ?? widget.car_service.phoneNumber),
                                  child: _buildActionIcon(FontAwesomeIcons.whatsapp),
                                ),
                                SizedBox(height: 5.h),
                                GestureDetector(
                                  onTap: () => _makePhoneCall(widget.car_service.phoneNumber),
                                  child: _buildActionIcon(Icons.phone),
                                ),
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

  Widget _buildDetailBox(String title, String value) {
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
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
              color: KTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      height: 40.h,
      width: 63.w,
      decoration: BoxDecoration(
        color: Color(0xFF01547E),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }
}

// Adapter class to make CarServiceModel compatible with FavoriteItemInterface
class CarServiceAdItemAdapter implements FavoriteItemInterface {
  final CarServiceModel _carService;
  
  CarServiceAdItemAdapter(this._carService);
  
  @override
  String get id => _carService.id.toString();
  
  @override
  String get contact => _carService.advertiserName;
  
  @override
  String get details => _carService.description;
  
  @override
  String get category => 'Car Service';
  
  @override
  String get addCategory => _carService.addCategory ?? 'Car Services';
  
  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(_carService.mainImage);
  
  @override
  List<String> get images => [
    if (_carService.mainImage != null && _carService.mainImage!.isNotEmpty)
      ImageUrlHelper.getMainImageUrl(_carService.mainImage!),
    ...ImageUrlHelper.getThumbnailImageUrls(_carService.thumbnailImages)
  ].where((img) => img.isNotEmpty).toList();
  
  @override
  String get line1 => _carService.title;
  
  @override
  String get line2 => _carService.description;
  
  @override
  String get price => _carService.price;
  
  @override
  String get location => "${_carService.emirate}  ${_carService.area ?? ''}".trim();
  
  @override
  String get title => _carService.title;
  
  @override
  String get date => _carService.createdAt?.split('T').first ?? '';
  
  @override
  bool get isPremium {
    if (_carService.planType == null) return false;
    return _carService.planType!.toLowerCase() != 'free';
  }
  
  @override
  AdPriority get priority {
    if (_carService.planType == null || _carService.planType!.toLowerCase() == 'free') {
      return AdPriority.free;
    }
    return AdPriority.premium;
  }
}
