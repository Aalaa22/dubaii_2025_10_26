import 'package:advertising_app/data/model/car_ad_model.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:advertising_app/presentation/widget/location_map.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';

class CarDetailsScreen extends StatefulWidget {
  // نستقبل الآن الـ ID فقط
  final int adId;

  const CarDetailsScreen({super.key, required this.adId});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen>
    with FavoritesHelper {
  int _currentPage = 0;
  late PageController _pageController;

  // دالة عامة لتنسيق الأرقام بإضافة فاصلة كل 3 أرقام
  String formatNumber(String number) {
    if (number.isEmpty) return number;

    // إزالة أي فاصلات موجودة مسبقاً
    String cleanNumber = number.replaceAll(',', '');

    // التحقق إذا كان المدخل صالح كعدد عشري (موجب أو سالب)
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(cleanNumber)) {
      return number; // إرجاع النص كما هو إذا لم يكن عدداً صحيحاً أو عشرياً
    }

    // تقسيم الرقم لجزء صحيح فقط (إزالة الجزء العشري)
    List<String> parts = cleanNumber.split('.');
    String integerPart = parts[0];

    // تحويل الجزء الصحيح لقائمة أحرف وعكسها
    bool isNegative = integerPart.startsWith('-');
    if (isNegative) {
      integerPart = integerPart.substring(1); // نشيل الـ - مؤقتاً
    }

    List<String> digits = integerPart.split('').reversed.toList();
    List<String> formatted = [];

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add(',');
      }
      formatted.add(digits[i]);
    }

    String formattedInteger = formatted.reversed.join('');
    if (isNegative) formattedInteger = '-' + formattedInteger;

    // إرجاع الجزء الصحيح فقط بدون أرقام عشرية
    return formattedInteger;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadFavoriteIds(); // Load favorite IDs when screen initializes
    // جلب البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CarAdProvider>(context, listen: false)
          .fetchAdDetails(widget.adId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white,
          body: Consumer<CarAdProvider>(
            builder: (context, provider, child) {
              // حالة التحميل
              if (provider.isLoadingDetails) {
                return const Center(child: CircularProgressIndicator());
              }
              // حالة الخطأ
              if (provider.detailsError != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'خطأ في تحميل تفاصيل الإعلان',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getErrorMessage(provider.detailsError!),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () =>
                                  provider.fetchAdDetails(widget.adId),
                              icon: Icon(Icons.refresh),
                              label: Text("إعادة المحاولة"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.arrow_back),
                              label: Text("العودة"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
              // حالة عدم وجود بيانات
              if (provider.adDetails == null) {
                return const Center(child: Text('Ad not found.'));
              }

              // بناء الواجهة بالبيانات الحقيقية بعد نجاح التحميل
              return _buildAdDetails(context, provider.adDetails!);
            },
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('incrementViews')) {
      return 'هذا الإعلان غير متاح حالياً. يرجى المحاولة لاحقاً أو اختيار إعلان آخر.';
    } else if (error.contains('500')) {
      return 'خطأ في الخادم. يرجى المحاولة لاحقاً.';
    } else if (error.contains('404')) {
      return 'الإعلان المطلوب غير موجود أو تم حذفه.';
    } else if (error.contains('Token')) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'تحقق من اتصال الإنترنت وحاول مرة أخرى.';
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';
    }
  }

  Widget _buildAdDetails(BuildContext context, CarAdModel car) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final s = S.of(context);

    // قائمة الصور الآن ديناميكية من الـ API مع تحويلها إلى URLs كاملة
    final List<String> images = [
      ImageUrlHelper.getMainImageUrl(car.mainImage),
      ...ImageUrlHelper.getThumbnailImageUrls(car.thumbnailImages)
    ];
    // إزالة أي روابط فارغة لضمان عدم حدوث خطأ
    images.removeWhere((element) => element.isEmpty);

    if (images.isEmpty) {
      images.add('https://via.placeholder.com/400x300.png?text=No+Image');
    }

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
                  itemCount: images.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => CachedNetworkImage(
                    imageUrl: images[index],
                    key: ValueKey(images[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
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
                  CarAdItemAdapter(car),
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

              // Back button
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
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              // Favorite & Share icons
              Positioned(
                top: 40.h,
                right: isArabic ? null : 16.w,
                left: isArabic ? 16.w : null,
                child: buildFavoriteIcon(
                  CarAdItemAdapter(car),
                  onAddToFavorite: () {
                    // Add to favorites callback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة الإعلان للمفضلة')),
                    );
                  },
                  onRemoveFromFavorite:
                      null, // No delete callback for details screen
                ),
              ),

              Positioned(
                  top: 80.h,
                  right: isArabic ? null : 16.w,
                  left: isArabic ? 16.w : null,
                  child: Icon(Icons.share, color: Colors.white, size: 30.sp)),

              // Page indicator dots
              if (images.length > 1)
                Positioned(
                  bottom: 12.h,
                  left: MediaQuery.of(context).size.width / 2 -
                      (images.length * 10.w / 2),
                  child: Row(
                    children: List.generate(images.length, (index) {
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
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('${_currentPage + 1}/${images.length}',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                ),
              ),
            ],
          ),
          // تقليل الفراغ أسفل السلايدر بدون تغيير ارتفاعه
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
                          SvgPicture.asset('assets/icons/priceicon.svg',
                              width: 24.w, height: 19.h),
                          SizedBox(width: 6.w),
                          Text("${formatNumber(car.price.toString())} AED",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: Colors.red)),
                          const Spacer(),
                          Text(car.createdAt?.split('T').first ?? '',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                              )),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        "${car.make} ${car.model} ${car.trim}",
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: KTextColor),
                      ),
                      SizedBox(height: 6.h),
                      // عرض معلومات السيارة الأساسية بنفس تنسيق TextSpan المستخدم في SearchCard
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Year: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: KTextColor,
                                  fontSize: 15.sp),
                              children: [
                                TextSpan(
                                  text: '${car.year}   ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: KTextColor,
                                      fontSize: 16.sp),
                                ),
                              ],
                            ),
                            TextSpan(
                              text: 'Km: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: KTextColor,
                                  fontSize: 15.sp),
                              children: [
                                TextSpan(
                                  text:
                                      '${NumberFormatter.formatNumber(car.km)}   ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: KTextColor,
                                      fontSize: 16.sp),
                                ),
                              ],
                            ),
                            TextSpan(
                              text: 'Specs: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: KTextColor,
                                  fontSize: 15.sp),
                              children: [
                                TextSpan(
                                  text: '${car.specs ?? ''}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: KTextColor,
                                      fontSize: 16.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        car.title ?? '',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontSize: 14.sp,
                            color: KTextColor,
                            fontWeight: FontWeight.w500),
                      ),
                      // SizedBox(height: 6.h),
                      // Row(
                      //   children: [
                      //     SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 18.h),
                      //     SizedBox(width: 6.w),
                      //     Expanded(child: Text('${car.emirate} ${car.area}', style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500))),
                      //   ],
                      // ),
                      SizedBox(height: 5.h),
                    ],
                  ),
                ),
                Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                Text(s.car_details,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: KTextColor)),
                SizedBox(height: 5.h),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent:
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? MediaQuery.of(context).size.height * 0.09.h
                            : MediaQuery.of(context).size.height * 0.08.h,
                    crossAxisSpacing: 30.w,
                  ),
                  children: [
                    _buildDetailBox(s.car_type, car.carType ?? 'N/A'),
                    _buildDetailBox(s.trans_type, car.transType ?? 'N/A'),
                    _buildDetailBox(s.color, car.color ?? 'N/A'),
                    _buildDetailBox(
                        s.interior_color, car.interiorColor ?? 'N/A'),
                    _buildDetailBox(s.fuel_type, car.fuelType ?? 'N/A'),
                    _buildDetailBox(s.warranty, car.warranty ? s.yes : s.no),
                    _buildDetailBox(s.doors_no, car.doorsNo ?? 'N/A'),
                    _buildDetailBox(s.seats_no, car.seatsNo ?? 'N/A'),
                    _buildDetailBox(
                        s.engine_capacity, car.engineCapacity ?? 'N/A'),
                    _buildDetailBox(s.cylinders, car.cylinders ?? 'N/A'),
                    _buildDetailBox(s.horse_power, car.horsepower ?? 'N/A'),
                    _buildDetailBox(s.steering_side, car.steeringSide ?? 'N/A'),
                  ],
                ),
                Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                Text(s.description,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: KTextColor)),
                SizedBox(height: 20.h),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: ReadMoreText(
                          car.description,
                          trimLines: 5,
                          colorClickableText: Color.fromARGB(255, 9, 37, 108),
                          trimMode: TrimMode.Line,
                          trimCollapsedText: 'Read more',
                          lessStyle: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 9, 37, 108),
                          ),
                          trimExpandedText: '  Show less',
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
                Text(s.location,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        color: KTextColor)),
                SizedBox(height: 8.h),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/icons/locationicon.svg',
                          width: 20.w, height: 20.h),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: Text('${car.emirate} ${car.area ?? ''}',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  color: KTextColor,
                                  fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                LocationMap(
                  address: car.area ?? '${car.emirate} ${car.area ?? ''}',
                  markerTitle: '${car.make} ${car.model}',
                  height: 188.h,
                ),
                SizedBox(height: 10.h),
                Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                Row(
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
                          Text(
                            car.advertiserType,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: KTextColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            car.advertiserName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: KTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          GestureDetector(
                            onTap: () => context.push('/all_ad_car_sales'),
                            child: Text(
                              s.view_all_ads,
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
                          _buildActionIcon(FontAwesomeIcons.whatsapp,
                              onTap: () {
                            if (car.whatsapp != null &&
                                car.whatsapp!.isNotEmpty) {
                              final url = PhoneNumberFormatter.getWhatsAppUrl(
                                  car.whatsapp!);
                              _launchUrl(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("WhatsApp number not available")),
                              );
                            }
                          }),
                          SizedBox(height: 5.h),
                          _buildActionIcon(Icons.phone, onTap: () {
                            final url =
                                PhoneNumberFormatter.getTelUrl(car.phoneNumber);
                            _launchUrl(url);
                          }),
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
                    s.report_this_ad,
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
                  padding:
                      EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
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
                      s.use_this_space_for_ads,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 14.sp,
                color: KTextColor,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 3.5.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          width: double.infinity,
          height: 38.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF08C2C9)),
              borderRadius: BorderRadius.circular(8.r)),
          child: Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
                color: KTextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        width: 63.w,
        decoration: BoxDecoration(
            color: Color(0xFF01547E), borderRadius: BorderRadius.circular(8.r)),
        child: Center(child: Icon(icon, color: Colors.white, size: 20.sp)),
      ),
    );
  }
}

// Adapter class to make CarAdModel compatible with FavoriteItemInterface
class CarAdItemAdapter implements FavoriteItemInterface {
  final CarAdModel _car;

  CarAdItemAdapter(this._car);

  @override
  String get id => _car.id.toString();

  @override
  String get contact => _car.advertiserName;

  @override
  String get details => _car.description;

  @override
  String get category => 'Cars Sales';

  @override
  String get addCategory => _car.addCategory ?? 'Cars Sales';

  @override
  String get imageUrl => ImageUrlHelper.getMainImageUrl(_car.mainImage);

  @override
  List<String> get images => [
        ImageUrlHelper.getMainImageUrl(_car.mainImage),
        ...ImageUrlHelper.getThumbnailImageUrls(_car.thumbnailImages)
      ].where((img) => img.isNotEmpty).toList();

  @override
  String get line1 =>
      "Year: ${_car.year}  Km: ${NumberFormatter.formatNumber(_car.km)}   Specs: ${_car.specs ?? ''}";

  @override
  String get line2 => _car.title;

  @override
  String get price => _car.price;

  @override
  String get location => "${_car.emirate}  ${_car.area ?? ''}".trim();

  @override
  String get title => "${_car.make} ${_car.model} ${_car.trim ?? ''}".trim();

  @override
  String get date => _car.createdAt?.split('T').first ?? '';

  @override
  bool get isPremium {
    if (_car.planType == null) return false;
    return _car.planType!.toLowerCase() != 'free';
  }

  @override
  AdPriority get priority {
    if (_car.planType == null || _car.planType!.toLowerCase() == 'free') {
      return AdPriority.free;
    }
    return AdPriority.premium;
  }
}
