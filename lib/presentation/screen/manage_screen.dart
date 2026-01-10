import 'package:advertising_app/data/model/my_ad_model.dart';
import 'package:advertising_app/data/repository/user_packages_repository.dart';
import 'package:advertising_app/presentation/providers/manage_ads_provider.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/providers/user_packages_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/core/scaffold_messenger_key.dart';

// ضبط اتجاه النص داخل SnackBar بحسب اتجاه الواجهة الحالي (دالة عامة)
Widget _localizedSnackText(BuildContext context, String text) {
  final isRTL = Directionality.of(context) == TextDirection.rtl;
  return Directionality(
    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
    child: Text(text, textAlign: TextAlign.start),
  );
}

class ManageScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const ManageScreen({Key? key, required this.onLanguageChange})
      : super(key: key);
  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyAdsProvider>(context, listen: false).fetchMyAds();
      // Fetch user packages for balance table
      () async {
        final token =
            await const FlutterSecureStorage().read(key: 'auth_token');
        if (!mounted) return;
        await Provider.of<UserPackagesProvider>(context, listen: false)
            .fetch(token: token);
      }();
    });
  }

  @override
  void dispose() {
    Provider.of<MyAdsProvider>(context, listen: false).stopAutoRefresh();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primaryColor = Color.fromRGBO(1, 84, 126, 1);
    final myAdsProvider = context.watch<MyAdsProvider>();
    final packagesProvider = context.watch<UserPackagesProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: CustomBottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              Center(
                  child: Text(s.manageAds,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 24.sp,
                          color: KTextColor))),
              SizedBox(height: 5.h),
              _buildFilterButtons(s, primaryColor, myAdsProvider),
              SizedBox(height: 6.h),
              if (packagesProvider.summary != null)
                _buildBalanceTable(s, primaryColor, packagesProvider.summary!),
              SizedBox(height: 6.h),
              _buildAdsContent(myAdsProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons(S s, Color primaryColor, MyAdsProvider provider) {
    final filters = {
      s.all: "All",
      s.valid: "Valid",
      s.pending: "Pending",
      s.expired: "Expired",
      s.rejected: "Rejected"
    };
    return Row(
      children: filters.entries.map((entry) {
        final isSelected = provider.selectedStatus == entry.value;
        Widget buttonChild = ElevatedButton(
          onPressed: () => provider.filterAdsByStatus(entry.value),
          style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? primaryColor : Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Text(entry.key,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp)),
        );
        return Expanded(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: isSelected
                    ? buttonChild
                    : Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                                colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter)),
                        child: buttonChild)));
      }).toList(),
    );
  }

  Widget _buildAdsContent(MyAdsProvider provider) {
    if (provider.isLoading && provider.displayedAds.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (provider.error != null)
      return Center(child: Text('Error: ${provider.error}'));
    if (provider.displayedAds.isEmpty)
      return Center(
          child: Text('No ads in this category.',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700)));
    return ListView.builder(
      itemCount: provider.displayedAds.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      cacheExtent: 500.0,
      itemBuilder: (context, index) {
        final ad = provider.displayedAds[index];
        return _AdCardWidget(key: ValueKey(ad.id), ad: ad);
      },
    );
  }

  Widget _buildBalanceTable(
      S s, Color primaryColor, UserPackageSummary summary) {
    Widget buildCell(Widget child,
            {bool isHeader = false, Alignment alignment = Alignment.center}) =>
        Container(
            padding: EdgeInsets.all(8.h),
            alignment: alignment,
            child: DefaultTextStyle(
                style: TextStyle(
                    color: KTextColor,
                    fontSize: 12.sp,
                    fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500),
                child: child));
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Color.fromRGBO(8, 194, 201, 1)),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Table(
            border: TableBorder(
                horizontalInside:
                    BorderSide(color: Color.fromRGBO(8, 194, 201, 1), width: 1),
                verticalInside:
                    BorderSide(color: Colors.grey.shade300, width: 1)),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1)
            },
            children: [
              TableRow(children: [
                buildCell(Text(s.adsType),
                    isHeader: true, alignment: Alignment.centerLeft),
                buildCell(
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(s.premium,
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2.w),
                      Icon(Icons.star, color: Color(0xFFF7C325), size: 11.5.sp)
                    ]),
                    isHeader: true),
                buildCell(Text(s.premium), isHeader: true),
                buildCell(Text(s.featured), isHeader: true)
              ]),
              TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    buildCell(Text(s.totalAds),
                        alignment: Alignment.centerLeft),
                    buildCell(Text('${summary.premiumStar.totalAds}')),
                    buildCell(Text('${summary.premium.totalAds}')),
                    buildCell(Text('${summary.featured.totalAds}'))
                  ]),
              TableRow(children: [
                buildCell(Text(s.balance), alignment: Alignment.centerLeft),
                buildCell(Text('${summary.premiumStar.balance}')),
                buildCell(Text('${summary.premium.balance}')),
                buildCell(Text('${summary.featured.balance}'))
              ])
            ],
          ),
          Divider(height: 1, color: Color.fromRGBO(8, 194, 201, 1)),
          Padding(
              padding: EdgeInsets.all(10.h),
              child: Text(
                  '${s.contractExpire}:${summary.contractExpire ?? '00/00/0000'}',
                  style: TextStyle(
                      color: KTextColor,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500)))
        ],
      ),
    );
  }
}

class _AdCardWidget extends StatefulWidget {
  final MyAdModel ad;
  const _AdCardWidget({super.key, required this.ad});
  @override
  State<_AdCardWidget> createState() => __AdCardWidgetState();
}

class __AdCardWidgetState extends State<_AdCardWidget> {
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedAction = S.of(context)!.upgrade);
    });
  }

  void _navigateToDetails(BuildContext context) {
    final ad = widget.ad;
    final slug = ad.categorySlug.toLowerCase();
    final category = (ad.category ?? '').toLowerCase();

    if (slug == 'car-sales' ||
        slug == 'car_sales' ||
        category.contains('cars sales')) {
      context.push('/car-details/${ad.id}');
    } else if (slug == 'car-rent' ||
        slug == 'car_rent' ||
        category.contains('car rent')) {
      context.push('/car-rent-details/${ad.id}');
    } else if (slug == 'job' ||
        slug.contains('job') ||
        category == 'jobs' ||
        category == 'jop') {
      context.push('/job-details/${ad.id}');
    } else if (slug == 'electronic' ||
        slug.contains('electronic') ||
        category.contains('electronic')) {
      context.push('/electronic-details/${ad.id}');
    } else if (slug == 'other-services' ||
        slug == 'other_services' ||
        category.contains('other services')) {
      context.push('/other_service-details/${ad.id}');
    } else if (slug == 'car-services' ||
        slug == 'car_services' ||
        category.contains('car services')) {
      context.push('/car-service-details/${ad.id}');
    } else if (slug == 'restaurant' ||
        slug == 'restaurants' ||
        category.contains('restaurant')) {
      context.push('/restaurant_details/${ad.id}');
    } else if (slug == 'real-estate' ||
        slug == 'real_estate' ||
        category.contains('real estate') ||
        category.contains('real state')) {
      context.push('/real-details/${ad.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primaryColor = Color.fromRGBO(1, 84, 126, 1);
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);
    final ad = widget.ad;
    final statusColor = _getStatusColor(ad.status);
    final statusText = _getStatusText(ad.status, s);

    // حدد صورة العرض بناءً على نوع الفئة للوظائف
    final jobImages = context.watch<MyAdsProvider>().jobCategoryImages;
    final slugLower = (ad.categorySlug).toLowerCase();
    final isJobCategory =
        slugLower.contains('job') || slugLower.contains('jop');
    final isOffer = (ad.categoryType ?? '').toLowerCase().contains('offer');
    final jobImageKey = isOffer ? 'job_offer' : 'job_seeker';
    final jobImagePath = jobImages[jobImageKey] ?? '';
    final resolvedImageUrl = ImageUrlHelper.getFullImageUrl(
      isJobCategory && jobImagePath.isNotEmpty ? jobImagePath : ad.mainImageUrl,
    );

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3))
            ]),
        child: Column(
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(
                children: [
                  SizedBox(
                    width: 140.w,
                    height: 105.h,
                    child: Stack(children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                              imageUrl: resolvedImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Image.asset(
                                  'assets/images/car.jpg',
                                  fit: BoxFit.cover))),
                      Positioned(
                          bottom: 4.h,
                          left: 4.w,
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                  color: Color.fromRGBO(255, 255, 255, .49),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                  "${NumberFormatter.formatPrice(ad.price)}",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold)))),
                    ]),
                  ),
                  // Plan type box positioned above the image
                if (ad.planType != null && ad.planType!.isNotEmpty)
                  Positioned(
                    top: 4.h,
                    left: 4.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFC9F8FE), Color(0xFF08C2C9)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ad.planType!.replaceAll('_star', ''),
                            style: TextStyle(
                              color: KTextColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (ad.planType!.contains('_star')) ...[
                            SizedBox(width: 2.w),
                            Icon(
                              Icons.star,
                              color: Color(0xFFF7C325),
                              size: 10.sp,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 10.w),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              // Show title first for all categories
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getAdTitle(ad),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: KTextColor,
                                    ),
                                  ),
                                  (ad.categorySlug == 'car_sales' ||
                                          ad.categorySlug == 'car_rent')
                                      ? (((ad.make != null &&
                                                  ad.make!.isNotEmpty) ||
                                              (ad.model != null &&
                                                  ad.model!.isNotEmpty) ||
                                              (ad.year != null &&
                                                  ad.year!.isNotEmpty)))
                                          ? Padding(
                                              padding:
                                                  EdgeInsets.only(top: 4.h),
                                              child: Row(
                                                children: [
                                                  if (ad.make != null &&
                                                      ad.make!.isNotEmpty) ...[
                                                    Text(ad.make!,
                                                        style: TextStyle(
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: KTextColor)),
                                                    if ((ad.model != null &&
                                                            ad.model!
                                                                .isNotEmpty) ||
                                                        (ad.year != null &&
                                                            ad.year!
                                                                .isNotEmpty))
                                                      Text(' • ',
                                                          style: TextStyle(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  KTextColor)),
                                                  ],
                                                  if (ad.model != null &&
                                                      ad.model!.isNotEmpty) ...[
                                                    Text(ad.model!,
                                                        style: TextStyle(
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: KTextColor)),
                                                    if (ad.year != null &&
                                                        ad.year!.isNotEmpty)
                                                      Text(' • ',
                                                          style: TextStyle(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  KTextColor)),
                                                  ],
                                                  if (ad.year != null &&
                                                      ad.year!.isNotEmpty)
                                                    Text(ad.year!,
                                                        style: TextStyle(
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: KTextColor)),
                                                ],
                                              ),
                                            )
                                          : SizedBox(height: 20.h)
                                      : SizedBox(
                                          height: Directionality.of(context) ==
                                                  TextDirection.rtl
                                              ? 0
                                              : 15.h),
                                ],
                              ),

                              // Add make, model, year for car_sales below the title

                              // SizedBox(height: 15.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                              //  SizedBox(height: 4.h),
                              Text(
                                  '${s.postDate}: ${_formatDateOnly(ad.createdAt)}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400)),
                              SizedBox(height: 2.h),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Builder(builder: (context) {
                                      if (ad.expiresAt == null) {
                                        return Text(
                                          '${s.expiresIn}: --',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400),
                                        );
                                      }
                                      try {
                                        final endDate =
                                            DateTime.parse(ad.expiresAt!);
                                        final now = DateTime.now();
                                        final difference =
                                            endDate.difference(now);
                                        final days = difference.inDays;

                                        String remainingText;
                                        if (days < 0) {
                                          remainingText = _formatDateOnly(ad.expiresAt!);
                                        } else {
                                          remainingText = '$days ${s.days}';
                                        }

                                        return Text(
                                            '${s.expiresIn}: $remainingText',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400));
                                      } catch (e) {
                                        return Text('${s.expiresIn}: --',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400));
                                      }
                                    }),
                                  ),
                                ],
                              )
                            ])),
                      ]),
                ])),
          ]),

          SizedBox(height: 2.h),
          // Search & Views section directly under image
          Row(children: [
            Icon(Icons.visibility_outlined,
                color: Color.fromRGBO(8, 194, 201, 1), size: 16.sp),
            SizedBox(width: 4.w),
            Row(
              children: [
                Text('${s.views}',
                    style: TextStyle(
                        color: Color.fromRGBO(8, 194, 201, 1),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400)),
                Text(' ${ad.views}',
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500)),
              ],
            )
          ]),

          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(s.refresh, primaryColor, borderColor, s, ad),
              _buildActionButton(s.edit, primaryColor, borderColor, s, ad),
              _buildActionButton(s.renew, primaryColor, borderColor, s, ad),
              _buildActionButton(s.delete, primaryColor, borderColor, s, ad),
            ],
          ),
        ],
      ),
    ));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Valid':
        return Color.fromRGBO(36, 150, 17, 1);
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      case 'Expired':
        return Colors.grey.shade600;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status, S s) {
    switch (status) {
      case 'Valid':
        return s.valid;
      case 'Pending':
        return s.pending;
      case 'Rejected':
        return s.rejected;
      case 'Expired':
        return s.expired;
      default:
        return status;
    }
  }

  String _formatDateOnly(String dateTimeString) {
    try {
      String dateOnly;
      // Handle different date formats
      if (dateTimeString.contains('T')) {
        dateOnly = dateTimeString.split('T').first;
      } else if (dateTimeString.contains(' ')) {
        dateOnly = dateTimeString.split(' ').first;
      } else {
        dateOnly = dateTimeString;
      }

      // Reverse the date format from YYYY-MM-DD to DD-MM-YYYY
      if (dateOnly.contains('-') && dateOnly.length >= 10) {
        List<String> parts = dateOnly.split('-');
        if (parts.length == 3) {
          return '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      return dateOnly;
    } catch (e) {
      return dateTimeString;
    }
  }

  String _getAdTitle(MyAdModel ad) {
    switch (ad.category) {
      case 'Cars Sales':
        List<String> carParts = [];
        if (ad.title != null && ad.title!.isNotEmpty) carParts.add(ad.title!);
        return carParts.isNotEmpty ? carParts.join(' ') : ad.title;
      case 'Car Rent':
        List<String> carParts = [];
        if (ad.title != null && ad.title!.isNotEmpty) carParts.add(ad.title!);
        return carParts.isNotEmpty ? carParts.join(' ') : ad.title;
      case 'Jobs':
      case 'Electronics':
      case 'Other Services':
        return ad.title;
      default:
        return ad.title;
    }
  }

  Widget _buildActionButton(
      String text, Color primaryColor, Color borderColor, S s, MyAdModel ad) {
    final isSelected = _selectedAction == text;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: ElevatedButton(
          onPressed: () async {
            if (text == s.edit) {
              final slug = (ad.categorySlug).toLowerCase();
              final category = (ad.category).toLowerCase();

              String? route;
              if ((slug.contains('car') &&
                      (slug.contains('sale') || slug.contains('sales'))) ||
                  category.contains('cars sales')) {
                route = '/car_sales_save_ads/${ad.id}';
              } else if (slug.contains('real') ||
                  slug.contains('estate') ||
                  category.contains('real estate') ||
                  category.contains('real state')) {
                route = '/real_estate_save_ads/${ad.id}';
              } else if ((slug.contains('car') && slug.contains('rent')) ||
                  category.contains('car rent')) {
                route = '/car_rent_save_ads/${ad.id}';
              } else if ((slug.contains('car') &&
                      (slug.contains('service') ||
                          slug.contains('services'))) ||
                  category.contains('car services')) {
                route = '/car_services_save_ads/${ad.id}';
              } else if (slug.contains('restaurant') ||
                  category.contains('restaurant')) {
                route = '/resturant_save_ads/${ad.id}';
              } else if (slug.contains('job') ||
                  category == 'jobs' ||
                  category == 'jop') {
                route = '/job_save_ads/${ad.id}';
              } else if (slug.contains('electronic') ||
                  category.contains('electronics')) {
                route = '/electronics_save_ads/${ad.id}';
              } else if ((slug.contains('other') && slug.contains('service')) ||
                  category.contains('other services')) {
                route = '/other_service_save_ads/${ad.id}';
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unknown category for edit')),
                );
              }

              if (route != null) {
                // انتظر الرجوع من صفحة التعديل، ثم أعد جلب الإعلانات لتحديث العرض فورًا
                await context.push(route);
                if (!mounted) return;
                await context.read<MyAdsProvider>().fetchMyAds();
              }
            } else if (text == s.refresh) {
              // تنفيذ طلب Rank One
              final messenger = rootScaffoldMessengerKey.currentState;
              final provider = context.read<MyAdsProvider>();
              messenger?.hideCurrentSnackBar();
              messenger?.showSnackBar(
                SnackBar(
                  content: _localizedSnackText(
                      context, S.of(context)!.rankAdInProgress),
                ),
              );
              final success = await provider.makeRankOne(ad: ad);
              messenger?.hideCurrentSnackBar();
              messenger?.showSnackBar(
                SnackBar(
                  content: _localizedSnackText(
                    context,
                    success
                        ? S.of(context)!.rankAdSuccess
                        : S.of(context)!.rankAdFailed,
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
              // بعد تنفيذ الترقية، أعِد الجلب لتتحدث حالة الإعلان فورًا
              await provider.fetchMyAds();
            } else if (text == s.renew) {
              // تنفيذ طلب Renew (حالياً يستخدم makeRankOne)
              final messenger = rootScaffoldMessengerKey.currentState;
              final provider = context.read<MyAdsProvider>();
              messenger?.hideCurrentSnackBar();
              messenger?.showSnackBar(
                SnackBar(
                  content: _localizedSnackText(
                      context, S.of(context)!.rankAdInProgress),
                ),
              );
              // قد يحتاج هذا إلى endpoint خاص بالتجديد مستقبلاً
              final success = await provider.makeRankOne(ad: ad);
              messenger?.hideCurrentSnackBar();
              messenger?.showSnackBar(
                SnackBar(
                  content: _localizedSnackText(
                    context,
                    success
                        ? S.of(context)!.rankAdSuccess
                        : S.of(context)!.rankAdFailed,
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
              await provider.fetchMyAds();
            } else if (text == s.delete) {
              final confirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      S.of(context)!.deleteAdTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        color: KTextColor,
                      ),
                    ),
                    content: Text(
                      S.of(context)!.deleteAdConfirmation,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: KTextColor,
                      ),
                    ),
                    actionsPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          S.of(context)!.cancel,
                          style: TextStyle(
                              fontSize: 12.sp, color: KTextColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          S.of(context)!.yesDelete,
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmed != true) return;

              final messenger = rootScaffoldMessengerKey.currentState;
              final provider = context.read<MyAdsProvider>();
              final success = await provider.deleteAd(ad: ad);
              messenger?.hideCurrentSnackBar();
              messenger?.showSnackBar(
                SnackBar(
                  content: _localizedSnackText(
                      context,
                      success
                          ? S.of(context)!.adDeletedSuccess
                          : S.of(context)!.adDeletedFailed),
                  backgroundColor: success ? Colors.green : const Color.fromARGB(255, 215, 54, 42),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              setState(() => _selectedAction = text);
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: text == s.delete
                  ? const Color.fromARGB(255, 214, 46, 34)
                  : (isSelected ? primaryColor : Colors.transparent),
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: text == s.delete ? Colors.red : borderColor,
                      width: 1))),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: text == s.delete
                      ? Colors.white
                      : (isSelected ? Colors.white : primaryColor),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.sp)),
        ),
      ),
    );
  }
}
