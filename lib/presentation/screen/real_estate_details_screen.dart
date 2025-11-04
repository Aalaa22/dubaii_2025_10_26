import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/real_estate_ad_model.dart';
import 'package:advertising_app/presentation/providers/real_estate_details_provider.dart';
import 'package:advertising_app/presentation/screen/car_rent_ads_screen.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/constant/my_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:advertising_app/presentation/widget/location_map.dart';
import 'package:readmore/readmore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

class RealEstateDetailsScreen extends StatefulWidget {
  final String adId;
  const RealEstateDetailsScreen({super.key, required this.adId});

  @override
  State<RealEstateDetailsScreen> createState() =>
      _RealEstateDetailsScreenState();
}

class _RealEstateDetailsScreenState extends State<RealEstateDetailsScreen> with FavoritesHelper {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadFavoriteIds(); // Load favorite IDs when screen initializes
    
    // Fetch real estate details when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealEstateDetailsProvider>().fetchRealEstateDetails(widget.adId);
    });
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white,
          body: Consumer<RealEstateDetailsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${provider.error}'),
                      ElevatedButton(
                        onPressed: () => provider.fetchRealEstateDetails(widget.adId),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final realEstate = provider.realEstateDetails;
              if (realEstate == null) {
                return const Center(child: Text('No data available'));
              }
              
              return _buildContent(realEstate, isArabic);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(RealEstateAdModel realEstate, bool isArabic) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 290.h,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _getOrderedImages(realEstate).length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final imageUrl = _getOrderedImages(realEstate)[index];
                    final fullImageUrl = ImageUrlHelper.getFullImageUrl(imageUrl ?? '');
                    
                    // Enhanced debugging for image loading
                    print('🖼️ Image Debug Info:');
                    print('   Index: $index');
                    print('   Original URL: $imageUrl');
                    print('   Full URL: $fullImageUrl');
                    print('   Images array length: ${_getOrderedImages(realEstate).length}');
                    print('   Images array: ${_getOrderedImages(realEstate)}');
                    
                    return fullImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: fullImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) {
                              print('🔄 Loading image: $url');
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: KPrimaryColor,
                                  ),
                                ),
                              );
                            },
                            errorWidget: (context, error, stackTrace) {
                              // Enhanced error logging
                              print('❌ ========== IMAGE LOADING ERROR ==========');
                              print('❌ Error: $error');
                              print('❌ Error Type: ${error.runtimeType}');
                              print('❌ Image URL: $fullImageUrl');
                              print('❌ Original path: $imageUrl');
                              print('❌ Index: $index');
                              print('❌ Stack trace: $stackTrace');
                              print('❌ ==========================================');
                              return Container(
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error, color: Colors.red, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      'فشل في تحميل الصورة',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    Text(
                                      'Error: ${error.toString()}',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image, size: 40, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'لا توجد صورة',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
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
                        RealEstateAdItemAdapter(realEstate),
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
                           ((realEstate.thumbnailImages?.length ?? 1) * 10.w / 2),
                      child: Row(
                        children: List.generate(realEstate.thumbnailImages?.length ?? 1, (index) {
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
                          '${_currentPage + 1}/${_getOrderedImages(realEstate).length}',
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
                                  NumberFormatter.formatPrice(realEstate.price ?? '0'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.red,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _formatDate(realEstate.createdAt ?? ''),
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12.sp,fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              realEstate.title ?? '',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor,
                              ),
                            ),
                           
                            SizedBox(height: 6.h),
                            Text(
                             "${realEstate.propertyType ?? ''} ${realEstate.contractType ?? ''}",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            
                            Transform.translate(
                              offset: Offset(-16.w, 0),
                              child: Row(
                                children: [
                                  SizedBox(width: 6.h),
                                  SvgPicture.asset(
                                    'assets/icons/locationicon.svg',
                                    width: 20.w,
                                    height: 18.h,
                                  ),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: Text(
                                      ('${realEstate.emirate ?? ''} ${realEstate.district ?? ''} ${realEstate.area ?? ''}').trim(),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: ReadMoreText(
                               "${realEstate.description}",
                                trimLines: 5,
                                colorClickableText:
                                    Color.fromARGB(255, 9, 37, 108),
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
                      SizedBox(height: 2.h),
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
                                '${realEstate.location ?? ''}'.trim(),
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
                        address: realEstate.location,
                        markerTitle: realEstate.title,
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
                                
                                SizedBox(height: 2.h),
                                Text(
                                   
                                  "Dubai investment",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: KTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                GestureDetector(
                                  onTap: () => context.push('/AllAdsRealEstate'),
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
                                  onTap: () {
                                    final whatsappNumber = realEstate.whatsappNumber ?? realEstate.phoneNumber ?? '';
                                    if (whatsappNumber.isNotEmpty && 
                                        whatsappNumber != 'null' && 
                                        whatsappNumber != 'nullnow') {
                                      final url = PhoneNumberFormatter.getWhatsAppUrl(whatsappNumber);
                                      _launchUrl(url);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('WhatsApp number not available')),
                                      );
                                    }
                                  },
                                  child: _buildActionIcon(FontAwesomeIcons.whatsapp),
                                ),
                                SizedBox(height: 5.h),
                                GestureDetector(
                                  onTap: () {
                                    final phoneNumber = realEstate.phoneNumber ?? '';
                                    if (phoneNumber.isNotEmpty && 
                                        phoneNumber != 'null' && 
                                        phoneNumber != 'nullnow') {
                                      final url = PhoneNumberFormatter.getTelUrl(phoneNumber);
                                      _launchUrl(url);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Phone number not available')),
                                      );
                                    }
                                  },
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
              color: MyColor.KTextColor,
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

  // Helper method to format date without time
  String _formatDate(String dateTime) {
    if (dateTime.isEmpty) return '';
    try {
      // Split by 'T' to separate date and time, then take only the date part
      return dateTime.split('T').first;
    } catch (e) {
      // If parsing fails, return original string
      return dateTime;
    }
  }

  // Helper method to get ordered images with main image first
  List<String?> _getOrderedImages(RealEstateAdModel realEstate) {
    List<String?> orderedImages = [];
    
    // Add main image first if it exists
    if (realEstate.mainImage != null && realEstate.mainImage!.isNotEmpty) {
      orderedImages.add(realEstate.mainImage);
    }
    
    // Add thumbnail images, excluding the main image if it's already in thumbnails
    if (realEstate.thumbnailImages != null) {
      for (String thumbnailImage in realEstate.thumbnailImages!) {
        // Only add if it's not the same as main image
        if (thumbnailImage != realEstate.mainImage) {
          orderedImages.add(thumbnailImage);
        }
      }
    }
    
    // If no images at all, return empty list
    if (orderedImages.isEmpty) {
      orderedImages.add(null); // This will show placeholder
    }
    
    return orderedImages;
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

  void _launchWhatsApp(String phoneNumber) async {
    // Clean phone number - remove spaces, dashes, and other non-numeric characters except +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    print('📱 WhatsApp Debug Info:');
    print('   Original number: $phoneNumber');
    print('   Cleaned number: $cleanNumber');
    
    // Check if number already has a country code
    if (cleanNumber.startsWith('+')) {
      // Number already has country code, use as is
      print('   Number already has country code: $cleanNumber');
    } else if (cleanNumber.startsWith('00')) {
      // Replace 00 with +
      cleanNumber = '+${cleanNumber.substring(2)}';
      print('   Converted 00 to +: $cleanNumber');
    } else if (cleanNumber.startsWith('971')) {
      // Already has UAE code without +, just add +
      cleanNumber = '+$cleanNumber';
      print('   Added + to existing 971: $cleanNumber');
    } else if (cleanNumber.length >= 9 && cleanNumber.length <= 10) {
      // Local UAE number, add +971
      cleanNumber = '+971$cleanNumber';
      print('   Added UAE country code: $cleanNumber');
    } else {
      // Number might already have country code without +, add + if it looks like international format
      if (cleanNumber.length > 10) {
        cleanNumber = '+$cleanNumber';
        print('   Added + to international number: $cleanNumber');
      } else {
        // Assume it's a local UAE number
        cleanNumber = '+971$cleanNumber';
        print('   Assumed local UAE number, added +971: $cleanNumber');
      }
    }
    
    final url = 'https://wa.me/${cleanNumber.substring(1)}'; // Remove + for WhatsApp URL
    print('   Final WhatsApp URL: $url');
    
    try {
      // Try using external_app_launcher for better WhatsApp integration
      bool whatsappInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: 'com.whatsapp',
        iosUrlScheme: 'whatsapp://',
      );
      
      if (whatsappInstalled) {
        await LaunchApp.openApp(
          androidPackageName: 'com.whatsapp',
          iosUrlScheme: 'whatsapp://send?phone=${cleanNumber.substring(1)}',
          appStoreLink: 'https://apps.apple.com/app/whatsapp-messenger/id310633997',
          openStore: false,
        );
        print('✅ WhatsApp launched successfully using external_app_launcher');
      } else {
        // Fallback to URL launcher
        if (await canLaunch(url)) {
          await launch(
            url,
            forceSafariVC: false,
            forceWebView: false,
            enableJavaScript: false,
          );
          print('✅ WhatsApp launched successfully using URL launcher');
        } else {
          print('❌ Could not launch WhatsApp: $url');
          // Try alternative WhatsApp URL format
          final alternativeUrl = 'whatsapp://send?phone=${cleanNumber.substring(1)}';
          print('   Trying alternative URL: $alternativeUrl');
          if (await canLaunch(alternativeUrl)) {
            await launch(alternativeUrl);
            print('✅ WhatsApp launched with alternative URL');
          } else {
            print('❌ Alternative URL also failed - WhatsApp may not be installed');
          }
        }
      }
    } catch (e) {
      print('❌ Error launching WhatsApp: $e');
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    // Clean phone number
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    final url = 'tel:$cleanNumber';
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        print('Could not make phone call: $url');
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }
}

// Adapter class to make RealEstateAdModel compatible with FavoriteItemInterface
class RealEstateAdItemAdapter implements FavoriteItemInterface {
  final RealEstateAdModel realEstate;

  RealEstateAdItemAdapter(this.realEstate);

  @override
  String get id => realEstate.id.toString();

  @override
  String get title => realEstate.title ?? '';

  @override
  String get location => realEstate.location ?? '';

  @override
  String get price => realEstate.price ?? '';

  @override
  String get line1 => realEstate.title ?? '';

  @override
  String get details => realEstate.description ?? '';

  @override
  String get date => realEstate.createdAt ?? '';

  @override
  String get contact => realEstate.phoneNumber ?? '';

  @override
  bool get isPremium => realEstate.planType == 'premium';

  @override
  List<String> get images => realEstate.thumbnailImages ?? [];

  @override
  String get category => 'Real State';

  @override
  String get addCategory => realEstate.addCategory ?? 'Real State';

  @override
  AdPriority get priority {
    if (realEstate.planType == 'premium') {
      return AdPriority.premium;
    }
    return AdPriority.free;
  }
}
