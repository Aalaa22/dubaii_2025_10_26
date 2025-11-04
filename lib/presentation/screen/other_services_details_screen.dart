// lib/presentation/screens/other_services_details_screen.dart

import 'package:advertising_app/data/model/other_service_model.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/other_service_ad_model.dart';
import 'package:advertising_app/presentation/providers/other_services_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/presentation/widget/location_map.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

// تعريف الثوابت
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

class OtherServicesDetailsScreen extends StatefulWidget {
  final int adId;
  const OtherServicesDetailsScreen({super.key, required this.adId});

  @override
  State<OtherServicesDetailsScreen> createState() =>
      _OtherServicesDetailsScreenState();
}

class _OtherServicesDetailsScreenState
    extends State<OtherServicesDetailsScreen> with FavoritesHelper {
  // PageController is not needed as there is only one main image.

  @override
  void initState() {
    super.initState();
    loadFavoriteIds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OtherServicesDetailsProvider>().fetchAdDetails(widget.adId);
    });
  }

  // دالة فتح الروابط بنفس أسلوب باقي الشاشات
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // لجعل الـ status bar يندمج مع الصورة
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<OtherServicesDetailsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text("Error: ${provider.error}"));
          }
          if (provider.adDetails == null) {
            return const Center(child: Text("Ad Details Not Found."));
          }
          return _buildContent(provider.adDetails!);
        },
      ),
    );
  }

  Widget _buildContent(OtherServiceAdModel ad) {
    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final imageUrl = ImageUrlHelper.getMainImageUrl(ad.mainImage ?? '');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 238.h,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (context, url, error) => Image.asset(
                            'assets/images/placeholder.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                      top: 40.h,
                      left: isArabic ? null : 15.w,
                      right: isArabic ? 15.w : null,
                      child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Row(children: [
                            const SizedBox(width: 2),
                            const SizedBox(
                                width: 15,
                                child: Icon(Icons.arrow_back_ios,
                                    color: KTextColor, size: 18)),
                            Text(s.back,
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: KTextColor))
                          ]))),
                  Positioned(
                      top: 40.h,
                      left: isArabic ? 16.w : null,
                      right: isArabic ? null : 16.w,
                      child: buildFavoriteIcon(
                        OtherServiceAdItemAdapter(ad),
                        onAddToFavorite: () {
                          // Add to favorites callback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إضافة الإعلان للمفضلة')),
                          );
                        },
                        onRemoveFromFavorite: null, // No delete callback for details screen
                      )),
                  Positioned(
                      top: 80.h,
                      left: isArabic ? 16.w : null,
                      right: isArabic ? null : 16.w,
                      child:
                          Icon(Icons.share, color: Colors.white, size: 30.sp)),
                ],
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/priceicon.svg',
                                width: 24.w, height: 19.h),
                            SizedBox(width: 6.w),
                            Text(NumberFormatter.formatPrice(ad.price),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.red)),
                            const Spacer(),
                            Text(ad.date,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                )),
                          ],
                        ),
                        SizedBox(height: 6.h),

                        Text(ad.serviceName ?? '',
                            style: TextStyle(
                                fontSize: 16.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 6.h),
                        Text(ad.title,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor)),
                        SizedBox(height: 1.h),

                        // SizedBox(height: 6.h),
                        // Row(children: [ SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 18.h), SizedBox(width: 6.w), Expanded(child: Text("${ad.emirate ?? ''} / ${ad.district ?? ''}", style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500)))]),
                        // SizedBox(height: 5.h),
                      ],
                    ),
                    const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                    Text(s.section_type,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: KTextColor)),
                    SizedBox(height: 15.h),
                    Text(ad.sectionType ?? 'N/A',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: KTextColor)),
                    SizedBox(height: 5.h),
                    const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                    Text(s.description,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: KTextColor)),
                    SizedBox(height: 10.h),
                    ReadMoreText(
                      ad.description ?? "no_description_provided",
                      trimLines: 5,
                      colorClickableText: KPrimaryColor,
                      trimMode: TrimMode.Line,
                      trimCollapsedText: S.of(context).read_more,
                      trimExpandedText: '  ${S.of(context).show_less}',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: KTextColor,
                          height: 1.5),
                      moreStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: KPrimaryColor),
                    ),
                    SizedBox(height: 1.h),
                    const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                    Text(s.location,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: KTextColor)),
                    SizedBox(height: 8.h),
                    Row(children: [
                      SvgPicture.asset('assets/icons/locationicon.svg',
                          width: 20.w, height: 20.h),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: Text(ad.addres ?? '',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  color: KTextColor,
                                  fontWeight: FontWeight.w500)))
                    ]),
                    SizedBox(height: 8.h),
                    LocationMap(
                      address: ad.addres ?? '',
                      markerTitle: ad.title,
                      height: 188.h,
                    ),
                    SizedBox(height: 10.h),
                    const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Container(
                            height: 63.h,
                            width: 78.w,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.r)),
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text("Agent", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: KTextColor)),
                              SizedBox(height: 2.h),
                              Text(ad.advertiserName,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: KTextColor,
                                      fontWeight: FontWeight.w500)),
                              SizedBox(height: 3.h),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/all_add_other_service'),
                                child: Text(s.view_all_ads,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF08C2C9),
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            const Color(0xFF08C2C9))),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Column(
                            children: [
                              _buildActionIcon(FontAwesomeIcons.whatsapp, ad),
                              SizedBox(height: 5.h),
                              _buildActionIcon(Icons.phone, ad),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                    SizedBox(height: 7.h),
                    Center(
                        child: Text(s.report_this_ad,
                            style: TextStyle(
                                color: KTextColor,
                                fontSize: 16.sp,
                                decoration: TextDecoration.underline,
                                decorationColor: KTextColor,
                                fontWeight: FontWeight.w600))),
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      height: 110.h,
                      padding: EdgeInsets.symmetric(
                          vertical: 20.h, horizontal: 15.w),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)]),
                          borderRadius: BorderRadius.circular(8.r)),
                      child: Center(
                          child: Text(s.use_this_space_for_ads,
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: KTextColor))),
                    ),
                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return SizedBox(
        height: 188.h,
        width: double.infinity,
        child: Stack(children: [
          Positioned.fill(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.asset('assets/images/map.png', fit: BoxFit.cover))),
          Positioned(
              top: 80.h,
              left: 0,
              right: 0,
              child: Icon(Icons.location_pin, color: Colors.red, size: 40.sp))
        ]));
  }

  Widget _buildActionIcon(IconData icon, OtherServiceAdModel ad) {
    return GestureDetector(
      onTap: () {
        if (icon == FontAwesomeIcons.whatsapp) {
          final phoneNumber = ad.whatsappNumber ?? ad.phoneNumber;
          if (phoneNumber != null &&
              phoneNumber.isNotEmpty &&
              phoneNumber != 'null' &&
              phoneNumber != 'nullnow') {
            final whatsappUrl =
                PhoneNumberFormatter.getWhatsAppUrl(phoneNumber);
            _launchUrl(whatsappUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("WhatsApp number not available")),
            );
          }
        } else if (icon == Icons.phone) {
          final phoneNumber = ad.phoneNumber;
          if (phoneNumber != null &&
              phoneNumber.isNotEmpty &&
              phoneNumber != 'null' &&
              phoneNumber != 'nullnow') {
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
            color: const Color(0xFF01547E),
            borderRadius: BorderRadius.circular(8.r)),
        child: Center(child: Icon(icon, color: Colors.white, size: 20.sp)),
      ),
    );
  }
}

// Adapter class to make OtherServiceModel compatible with FavoriteItemInterface
class OtherServiceAdItemAdapter implements FavoriteItemInterface {
  final OtherServiceAdModel otherService;

  OtherServiceAdItemAdapter(this.otherService);

  @override
  String get id => otherService.id.toString();

  @override
  String get title => otherService.title ?? '';

  @override
  String get location => otherService.location;

  @override
  String get price => otherService.price;

  @override
  String get line1 => otherService.line1;

  @override
  String get details => otherService.details;

  @override
  String get date => otherService.date;

  @override
  String get contact => otherService.contact;

  @override
  bool get isPremium => otherService.isPremium;

  @override
  List<String> get images => otherService.images;

  @override
  String get category => 'other_services';

  @override
  String get addCategory => 'Other Services';

  @override
  AdPriority get priority {
    if (otherService.isPremium == true) {
      return AdPriority.premium;
    }
    return AdPriority.free;
  }
}
