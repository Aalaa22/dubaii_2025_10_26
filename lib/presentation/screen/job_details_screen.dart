// lib/presentation/screens/job_details_screen.dart

import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/job_ad_model.dart';
import 'package:advertising_app/presentation/providers/job_details_provider.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/presentation/widget/location_map.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

// تعريف الثوابت
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class JobDetailsScreen extends StatefulWidget {
  final int adId;
  const JobDetailsScreen({super.key, required this.adId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> with FavoritesHelper {
  @override
  void initState() {
    super.initState();
    loadFavoriteIds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobDetailsProvider>().fetchAdDetails(widget.adId);
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<JobDetailsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text("Error: ${provider.error}"));
          }
          if (provider.adDetails == null) {
            return const Center(child: Text("Ad not found."));
          }
          return _buildContent(provider.adDetails!);
        },
      ),
    );
  }

  Widget _buildContent(JobAdModel ad) {
    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final provider = context.read<JobDetailsProvider>();

    final imageKey = (ad.categoryType ?? '').toLowerCase().contains('offer')
        ? 'job_offer'
        : 'job_seeker';
    final imagePath = provider.categoryImages[imageKey] ?? '';
    final imageUrl = ImageUrlHelper.getFullImageUrl(imagePath);

    debugPrint('Displaying Image URL for Job Details: $imageUrl');

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
                        errorWidget: (context, url, error) {
                          debugPrint(
                              'Error loading image from URL: $imageUrl\nError: $error');
                          return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey, size: 50)));
                        },
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
                                    color: Colors.white, size: 18)),
                            Text(s.back,
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 2)
                                    ]))
                          ]))),
                  Positioned(
                      top: 40.h,
                      left: isArabic ? 16.w : null,
                      right: isArabic ? null : 16.w,
                      child: buildFavoriteIcon(
                        JobAdItemAdapter(ad),
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
                            Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 2)
                          ])),
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
                              Text("${NumberFormatter.formatPrice(ad.price)}" ?? "N/A",
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
                          Text(ad.job_name ??'',
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: KTextColor)),
                          SizedBox(height: 6.h),
                          Text(ad.title,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: KTextColor)),
                                   const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                        SizedBox(height: 2.h),
                            Text(s.sectionType,
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: KTextColor)),
                            SizedBox(height: 8.h),
                            Text(ad.sectionType!,
                                style: TextStyle(
                                    color: KTextColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4)),
                            SizedBox(height: 1.h),
                           const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                         
                             SizedBox(height: 2.h),
                            Text("Contact Us Via",
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: KTextColor)),
                            SizedBox(height: 8.h),
                            Text(ad.contactInfo!,
                                style: TextStyle(
                                    color: KTextColor,
                                    fontSize: 14.sp,
                                     fontWeight: FontWeight.w500,
                                    height: 1.4)),
                            SizedBox(height: 1.h),
                           const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                          SizedBox(height: 2.h),
                          Text(s.description,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: KTextColor)),
                          SizedBox(height: 10.h),
                          ReadMoreText(
                              ad.description ?? 'No description provided.',
                              trimLines: 5,
                              colorClickableText: KPrimaryColor,
                              trimMode: TrimMode.Line,
                              trimCollapsedText: S.of(context).read_more,
                              trimExpandedText: '  ${S.of(context).show_less}',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: KTextColor,
                                  height: 1.5)),
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
                                child: Text(
                                    ad.address ??
                                        ad.location ??
                                        'Location not specified',
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: KTextColor,
                                        fontWeight: FontWeight.w500)))
                          ]),
                          SizedBox(height: 8.h),
                          LocationMap(
                            address: ad.address ??
                                ad.location ??
                                'Location not specified',
                            markerTitle: ad.title,
                            height: 188.h,
                          ),
                          SizedBox(height: 10.h),
                          const Divider(color: Color(0xFFB5A9B1), thickness: 1),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: Row(children: [
                              Container(
                                  height: 63.h,
                                  width: 78.w,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(
                                          8.r))), // Placeholder for agent image
                              SizedBox(width: 15.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 5.h),
                                    // Text("Agent",
                                    //     style: TextStyle(
                                    //         fontSize: 16.sp,
                                    //         fontWeight: FontWeight.w600,
                                    //         color: KTextColor)),
                                    SizedBox(height: 2.h),
                                    Text(ad.advertiserName,
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            color: KTextColor,
                                            fontWeight: FontWeight.w500)),
                                    SizedBox(height: 3.h),
                                    GestureDetector(
                                        onTap: () =>
                                            context.push('/all_add_job'),
                                        child: Text(s.view_all_ads,
                                            style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: borderColor,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: borderColor))),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          // if (ad.contactInfo != null &&
                          //     ad.contactInfo!.isNotEmpty) ...[
                          //   const Divider(
                          //       color: Color(0xFFB5A9B1), thickness: 1),
                          //   SizedBox(height: 10.h),
                          //   Text("Contact Information",
                          //       style: TextStyle(
                          //           fontSize: 16.sp,
                          //           fontWeight: FontWeight.w600,
                          //           color: KTextColor)),
                          //   SizedBox(height: 8.h),
                          //   Text(ad.contactInfo!,
                          //       style: TextStyle(
                          //           color: KTextColor,
                          //           fontSize: 14.sp,
                          //           height: 1.4)),
                          //   SizedBox(height: 10.h),
                          // ],
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
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFE4F8F6),
                                    Color(0xFFC9F8FE)
                                  ]),
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
                    ]),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: KTextColor)),
        ],
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
            child: Icon(Icons.location_pin, color: Colors.red, size: 40.sp)),
      ]),
    );
  }
}

// Adapter class to make JobAdModel compatible with FavoriteItemInterface
class JobAdItemAdapter implements FavoriteItemInterface {
  final JobAdModel job;

  JobAdItemAdapter(this.job);

  @override
  String get id => job.id.toString();

  @override
  String get title => job.title ?? '';

  @override
  String get location =>  '';

  @override
  String get price => job.salary?.toString() ?? '';

  @override
  String get line1 => job.title ?? '';

  @override
  String get details => job.description ?? '';

  @override
  String get date => job.createdAt ?? '';

  @override
  String get contact => job.phoneNumber ?? '';

  @override
  bool get isPremium => job.isPremium ?? false;

  @override
  List<String> get images => job.images ?? [];

  @override
  String get category => 'jobs';

  @override
  String get addCategory => 'Jop';

  @override
  AdPriority get priority {
    if (job.isPremium == true) {
      return AdPriority.premium;
    }
    return AdPriority.free;
  }
}
