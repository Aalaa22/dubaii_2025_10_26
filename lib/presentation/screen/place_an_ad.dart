import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/car_services_ad_provider.dart';
import 'package:advertising_app/presentation/providers/car_rent_ad_provider.dart';
import 'package:advertising_app/presentation/providers/real_estate_ad_provider.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:advertising_app/presentation/providers/restaurants_ad_provider.dart';
import 'package:advertising_app/presentation/providers/settings_provider.dart';
import 'package:advertising_app/presentation/providers/other_services_ad_post_provider.dart';
import 'package:advertising_app/presentation/providers/electronics_ad_post_provider.dart';
import 'package:advertising_app/presentation/providers/job_ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PlaceAnAd extends StatefulWidget {
  final Map<String, dynamic>? adData;
  
  const PlaceAnAd({Key? key, this.adData}) : super(key: key);
  
  @override
  State<PlaceAnAd> createState() => _PlaceAnAdState();
}

class _PlaceAnAdState extends State<PlaceAnAd> {
  int selectedOption = 0;
  bool _isSubmitting = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // طباعة البيانات المستلمة في Console
    if (widget.adData != null) {
      print('=== البيانات المستلمة في صفحة اختيار الخطة ===');
      widget.adData!.forEach((key, value) {
        print('$key: $value');
      });
      print('=======================================');
    } else {
      print('تحذير: لا توجد بيانات إعلان مرسلة!');
    }
  }

  Future<void> _loadSettings() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.fetchSystemSettings();
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    });
  }

  void _showFreeAdNotEligibleDialog() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final settingsProvider = context.read<SettingsProvider>();
    final maxFreePrice = settingsProvider.systemSettings?.maxPriceFreeAdCarsSales ?? 120000;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: KTextColor,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  S.of(context).warning,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: KTextColor,
                  ),
                ),
              ],
            ),
            content: Text(
              S.of(context).freeAdNotEligibleMessage(maxFreePrice.toStringAsFixed(0)),
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: KTextColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Text(
                    S.of(context).ok,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _submitAdWithType() async {
    if (widget.adData == null || widget.adData!['adType'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).adDataIncomplete), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      // 1. تجهيز بيانات الخطة
      final adOptions = _getAdOptions();
      final selectedAdOption = adOptions[selectedOption];
      final expiresAt = DateTime.now().add(Duration(days: selectedAdOption.duration));
      String planType;
      if (selectedAdOption.title.contains('⭐')) { planType = 'premium_star'; } 
      else if (selectedAdOption.title.toLowerCase().contains('premium')) { planType = 'premium'; }
      else if (selectedAdOption.title.toLowerCase().contains('featured')) { planType = 'featured'; }
      else { planType = 'free'; }

      // إضافة بيانات الخطة إلى بيانات الإعلان
      widget.adData!['planType'] = planType;
      widget.adData!['planDays'] = selectedAdOption.duration;
      widget.adData!['planExpiresAt'] = expiresAt.toIso8601String();

      // 2. تحديد نوع الإعلان واستدعاء الـ Provider الصحيح
      final String adType = widget.adData!['adType'];
      bool success = false;
      String? submissionError;

      if (adType == 'car_sale') {
        final provider = context.read<CarAdProvider>();
        success = await provider.submitCarAd(widget.adData!);
        submissionError = provider.submitAdError;

      } else if (adType == 'car_service') {
        final provider = context.read<CarServicesAdProvider>();
        success = await provider.submitCarServiceAd(widget.adData!);
        submissionError = provider.error;
      } else if (adType == 'car_rent') {
        final provider = context.read<CarRentAdProvider>();
        success = await provider.submitCarRentAd(widget.adData!);
        submissionError = provider.createAdError;
      } else if (adType == 'restaurant') {
        final provider = context.read<RestaurantsAdProvider>();
        success = await provider.submitRestaurantAd(widget.adData!);
        submissionError = provider.error;
      } else if (adType == 'real_estate') {
         print('=== Submitting Real Estate Ad ===');
        print('Ad Data before submission: ${widget.adData}');
        print('Plan Type: ${widget.adData!['planType']}');
        print('Plan Days: ${widget.adData!['planDays']}');
        print('Plan Expires At: ${widget.adData!['planExpiresAt']}');
        
        final provider = context.read<RealEstateAdProvider>();
        success = await provider.submitRealEstateAd(widget.adData!);
        submissionError = provider.error;
        print('Submission result: $success');
        print('Submission error: $submissionError');
        print('=== Real Estate Ad Submission Complete ===');
      } else if (adType == 'electronics') {
        final provider = context.read<ElectronicsAdPostProvider>();
        success = await provider.submitElectronicsAd(widget.adData!);
        submissionError = provider.error;
      } else if (adType == 'job') {
        final provider = context.read<JobAdProvider>();
        success = await provider.submitJobAd(widget.adData!);
        submissionError = provider.submitAdError;
      } else if (adType == 'other_service') {
        final provider = context.read<OtherServicesAdPostProvider>();
        success = await provider.submitOtherServiceAd(widget.adData!);
        submissionError = provider.error;
      }

      if (!mounted) return;

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).adPublishedSuccessfully), backgroundColor: Colors.green));
          context.go('/home'); // أو العودة للصفحة الرئيسية
        }
      } else {
        if (mounted) {
          // عرض الرسالة للمستخدم بدون استثناء ثم التوجه لصفحة الدفع مع تفاصيل الإعلان
          final String message = submissionError ?? S.of(context).planExpiredOrInactivePleasePay;
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(message), backgroundColor: Colors.orange),
          // );

          context.push('/payment', extra: {
            'adData': widget.adData!,
            'amount': selectedAdOption.price,
            'apiMessage': message,
          });
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).errorOccurredWithMessage(e.toString())), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }



  List<AdOption> _getAdOptions() {
    final s = S.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    
    List<AdOption> options = [
      AdOption(
        title: '${s.premium} ⭐',
        price: settingsProvider.getPlanPrice('premium_star').toStringAsFixed(0),
        duration: settingsProvider.getPlanDuration('premium_star'),
        labelColor: KTextColor,
        features: [
          s.appearance_top,
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.premium,
        price: settingsProvider.getPlanPrice('premium').toStringAsFixed(0),
        duration: settingsProvider.getPlanDuration('premium'),
        labelColor: Color.fromRGBO(1, 84, 126, 1),
        features: [
          '${s.appearance_after_star} ⭐',
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.featured,
        price: settingsProvider.getPlanPrice('featured').toStringAsFixed(0),
        duration: settingsProvider.getPlanDuration('featured'),
        labelColor: Color.fromRGBO(8, 194, 201, 1),
        features: [
          s.appearance_after_premium,
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.free,
        price: '0',
        duration: settingsProvider.getFreeAdCycleDays(),
        labelColor: Colors.grey,
        features: [
          s.appearance_after_featured,
          s.daily_refresh,
        ],
      ),
    ];
    
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final s = S.of(context);

    // Show loading while fetching settings
    if (_isLoadingSettings) {
      return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(KTextColor),
                ),
                SizedBox(height: 16),
                Text(
                  isArabic ? 'جاري تحميل الإعدادات...' : 'Loading settings...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: KTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<AdOption> adOptions = _getAdOptions();
    
    // Check if free ad is not available and show message
    final settingsProvider = context.read<SettingsProvider>();
    final carPrice = double.tryParse(widget.adData?['price']?.toString() ?? '0') ?? 0;
    final isFreeAdEligible = settingsProvider.canPostFreeAd(carPrice);
    final maxFreePrice = settingsProvider.systemSettings?.maxPriceFreeAdCarsSales ?? 120000;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(height: 50.h),
            GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
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
            SizedBox(height: 5.h),
            Center(
              child: Text(
                s.post,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 24.sp,
                  color: KTextColor,
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: adOptions.length,
                separatorBuilder: (_, __) => SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final option = adOptions[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: Color.fromRGBO(181, 179, 177, 0.98)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Container الملون اللي في أول السطر
                        Container(
                          height: 40.h,
                          width: double.infinity,
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8)),
                            color: index == 3 ? null : option.labelColor,
                            gradient: index == 3
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE4F8F6),
                                      Color(0xFFC9F8FE)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              // Check if trying to select free option (index 3) and not eligible
                              if (index == 3) {
                                final settingsProvider = context.read<SettingsProvider>();
                                final carPrice = double.tryParse(widget.adData?['price']?.toString() ?? '0') ?? 0;
                                final isFreeAdEligible = settingsProvider.canPostFreeAd(carPrice);
                                
                                if (!isFreeAdEligible) {
                                  _showFreeAdNotEligibleDialog();
                                  return;
                                }
                              }
                              
                              setState(() {
                                selectedOption = index;
                              });
                            },
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: selectedOption,
                                  activeColor: index == 3 ? KTextColor : Color.fromRGBO(245, 247, 250, 1),
                                  focusColor: option.labelColor,
                                  onChanged: (val) {
                                    // Check if trying to select free option (index 3) and not eligible
                                    if (val == 3) {
                                      final settingsProvider = context.read<SettingsProvider>();
                                      final carPrice = double.tryParse(widget.adData?['price']?.toString() ?? '0') ?? 0;
                                      final isFreeAdEligible = settingsProvider.canPostFreeAd(carPrice);
                                      
                                      if (!isFreeAdEligible) {
                                        _showFreeAdNotEligibleDialog();
                                        return;
                                      }
                                    }
                                    
                                    setState(() {
                                      selectedOption = val!;
                                    });
                                  },
                                ),
                                Text(
                                  option.title,
                                  style: TextStyle(
                                    color: index == 3
                                        ? KTextColor
                                        : Color.fromRGBO(245, 247, 250, 1),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        ...option.features.map(
                          (f) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Color.fromRGBO(0, 30, 90, 1))),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      color: Color.fromRGBO(0, 30, 90, 1),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Color.fromRGBO(0, 30, 90, 1))),
                              Text(
                                '${s.cost} [${option.price}] AED ${s.for_days(option.duration.toString())}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color.fromRGBO(0, 30, 90, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  _isSubmitting
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(KTextColor),
                          ),
                        )
                      : CustomButton(
                          ontap: _submitAdWithType,
                          text: s.submit,
                        ),
                   SizedBox(height: 8),
                  // Text(
                  //   s.top_of_day_note,
                  //   style: TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w500,
                  //       color: Color.fromRGBO(129, 126, 126, 1)),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  

}

class AdOption {
  final String title;
  final String price;
  final int duration;
  final List<String> features;
  final Color labelColor;

  AdOption({
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    required this.labelColor,
  });
}
