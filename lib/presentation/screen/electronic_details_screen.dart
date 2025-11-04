// lib/presentation/screens/electronic_details_screen.dart

import 'package:advertising_app/data/model/electronics_ad_model.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/repository/electronics_repository.dart';
import 'package:advertising_app/presentation/providers/electronic_details_provider.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:readmore/readmore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:advertising_app/presentation/widget/location_map.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

// Consts
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class ElectronicDetailsScreen extends StatefulWidget {
  final int adId;
  const ElectronicDetailsScreen({super.key, required this.adId});

  @override
  State<ElectronicDetailsScreen> createState() =>
      _ElectronicDetailsScreenState();
}

class _ElectronicDetailsScreenState extends State<ElectronicDetailsScreen> with FavoritesHelper {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadFavoriteIds(); // Load favorite IDs when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ElectronicDetailsProvider>().fetchAdDetails(widget.adId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch $urlString")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Consumer<ElectronicDetailsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()));
        }
        if (provider.error != null) {
          return Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: Text("Error: ${provider.error}")));
        }
        if (provider.adDetails == null) {
          return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: Text("Ad Details Not Found.")));
        }

        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: _buildContent(provider.adDetails!),
          ),
        );
      },
    );
  }

  Widget _buildContent(ElectronicAdModel ad) {
    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final allImages = [ad.mainImage, ...ad.thumbnailImages]
        .where((img) => img != null && img.isNotEmpty)
        .cast<String>()
        .toList();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 290.h,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: allImages.isEmpty ? 1 : allImages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      // في حال عدم وجود صور، أعرض خلفية هادئة بدون صورة وهمية
                      if (allImages.isEmpty) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                          ),
                        );
                      }

                      final rawPath = allImages[index];
                      final processedUrl = ImageUrlHelper.getFullImageUrl(rawPath);

                      // إذا كان الرابط شبكة (http/https) أعرض لودر ثم الصورة
                      if (processedUrl.startsWith('http://') || processedUrl.startsWith('https://')) {
                        return CachedNetworkImage(
                          imageUrl: processedUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            ),
                          ),
                        );
                      }

                      // إذا كانت الصورة أصل محلي (assets)
                      if (rawPath.startsWith('assets/')) {
                        return Image.asset(
                          rawPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            ),
                          ),
                        );
                      }

                      // أي حالة أخرى
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 40.h,
                  left: isArabic ? null : 15.w,
                  right: isArabic ? 15.w : null,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        const SizedBox(width: 2),
                        const SizedBox(
                            width: 15,
                            child: Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 18)),
                        Text(s.back,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                shadows: [
                                  Shadow(blurRadius: 2, color: Colors.black54)
                                ])),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    top: 40.h,
                    left: isArabic ? 16.w : null,
                    right: isArabic ? null : 16.w,
                    child: buildFavoriteIcon(
                      ElectronicAdItemAdapter(ad),
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
                    child: Icon(Icons.share,
                        color: Colors.white,
                        size: 30.sp,
                        shadows: [
                          Shadow(blurRadius: 2, color: Colors.black54)
                        ])),
                if (allImages.length > 1)
                  Positioned(
                      bottom: 12.h,
                      left: 0,
                      right: 0,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              allImages.length,
                              (index) => Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                                  width: 7.w,
                                  height: 7.h,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? Colors.white
                                          : Colors.white54))))),
                if (allImages.length > 1)
                  Positioned(
                    bottom: 12.h,
                    right: isArabic ? 16.w : null,
                    left: isArabic ? null : 16.w,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8.r)),
                        child: Text('${_currentPage + 1}/${allImages.length}',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12.sp))),
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
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          SvgPicture.asset('assets/icons/priceicon.svg',
                              width: 24.w, height: 19.h),
                          SizedBox(width: 6.w),
                          Text(NumberFormatter.formatPrice(ad.price),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: Colors.red)),
                          const Spacer(),
                          Text(ad.date.split('T').first ?? '',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                              ))
                        ]),
                       SizedBox(height: 6.h),
                        Text(ad.productName ?? '',
                            style: TextStyle(
                                fontSize: 16.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w600)),
                                 SizedBox(height: 6.h),
                        Text(ad.title,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor)),
                        
                      //  SizedBox(height: 2.h),
                        // Row(children: [
                        //   SvgPicture.asset('assets/icons/locationicon.svg',
                        //       width: 20.w, height: 18.h),
                        //   SizedBox(width: 6.w),
                        //   Expanded(
                        //       child: Text(ad.location,
                        //           style: TextStyle(
                        //               fontSize: 14.sp,
                        //               color: KTextColor,
                        //               fontWeight: FontWeight.w500)))
                        // ]),
                        // SizedBox(height: 5.h),
                      ],
                    ),
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
                  ReadMoreText(ad.description ?? "no_description_provided",
                      trimLines: 5,
                      colorClickableText: KPrimaryColor,
                      trimMode: TrimMode.Line,
                      trimCollapsedText: S.of(context).read_more,
                      lessStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: KPrimaryColor),
                      trimExpandedText: '  ${S.of(context).show_less}',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: KTextColor),
                      moreStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: KPrimaryColor)),
                  SizedBox(height: 1.h),
                  const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                  Text(s.location,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: KTextColor)),
                  SizedBox(height: 8.h),
                  Row(children: [
                    SvgPicture.asset('assets/icons/locationicon.svg',
                        width: 20.w, height: 20.h),
                    SizedBox(width: 8.w),
                    Expanded(
                        child: Text(ad.addres!,
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w500)))
                  ]),
                  SizedBox(height: 8.h),
                  LocationMap(
                    address: ad.addres,
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
                                  borderRadius: BorderRadius.circular(8.r)))),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text("Agent",
                            //     style: TextStyle(
                            //         fontSize: 16.sp,
                            //         fontWeight: FontWeight.w600,
                            //         color: KTextColor)),
                            SizedBox(height: 2.h),
                            Text(ad.contact,
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    color: KTextColor,
                                    fontWeight: FontWeight.w500)),
                            SizedBox(height: 3.h),
                            GestureDetector(
                                onTap: () => context.push('/AllAddsElectronic'),
                                child: Text(s.view_all_ads,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: borderColor,
                                        decoration: TextDecoration.underline,
                                        decorationColor: borderColor))),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Column(
                          children: [
                            _buildActionIcon(FontAwesomeIcons.whatsapp, () {
                              final whatsappNumber = ad.whatsappNumber ?? ad.phoneNumber;
                              if (whatsappNumber != null && whatsappNumber.isNotEmpty && whatsappNumber != 'null' && whatsappNumber != 'nullnow') {
                                final url = PhoneNumberFormatter.getWhatsAppUrl(whatsappNumber);
                                _launchUrl(url);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("WhatsApp number not available")),
                                );
                              }
                            }),
                            SizedBox(height: 5.h),
                            _buildActionIcon(Icons.phone, () {
                              final phoneNumber = ad.phoneNumber;
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
                                  color: KTextColor)))),
                  SizedBox(height: 50.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      const Divider(color: Color(0xFFB5A9B1), thickness: 1),
      SizedBox(height: 5.h),
      Text(title,
          style: TextStyle(
              fontSize: 16.sp, fontWeight: FontWeight.w600, color: KTextColor)),
      SizedBox(height: 15.h),
      Text(value,
          style: TextStyle(
              fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor))
    ]);
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

class ElectronicAdItemAdapter implements FavoriteItemInterface {
  final ElectronicAdModel electronic;

  ElectronicAdItemAdapter(this.electronic);

  @override
  String get id => electronic.id.toString();

  @override
  String get title => electronic.title ?? '';

  @override
  String get location => electronic.area ?? '';

  @override
  String get price => electronic.price?.toString() ?? '';

  @override
  String get line1 => electronic.title ?? '';

  @override
  String get details => electronic.description ?? '';

  @override
  String get date => electronic.createdAt ?? '';

  @override
  String get contact => electronic.phoneNumber ?? '';

  @override
  bool get isPremium => electronic.isPremium ?? false;

  @override
  List<String> get images => electronic.images ?? [];

  @override
  String get category => 'electronics';

  @override
  String get addCategory => 'Electronics';

  @override
  AdPriority get priority {
    if (electronic.isPremium == true) {
      return AdPriority.premium;
    }
    return AdPriority.free;
  }
}
