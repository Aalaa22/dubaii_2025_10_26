import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/repository/car_rent_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class PlanSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> adData;
  
  const PlanSelectionScreen({Key? key, required this.adData}) : super(key: key);

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CarRentRepository _repository = CarRentRepository(ApiService());
  
  String? selectedPlanType;
  bool isLoading = false;

  final List<Map<String, dynamic>> planTypes = [
    {
      'id': 'basic',
      'name': 'Basic Plan',
      'nameAr': 'الخطة الأساسية',
      'price': '0',
      'duration': '7 days',
      'durationAr': '7 أيام',
      'features': [
        'Standard listing visibility',
        'Basic support',
        'Limited promotion'
      ],
      'featuresAr': [
        'رؤية قياسية للإعلان',
        'دعم أساسي',
        'ترويج محدود'
      ],
      'color': Colors.grey[600]!,
      'icon': Icons.star_border,
    },
    {
      'id': 'premium',
      'name': 'Premium Plan',
      'nameAr': 'الخطة المميزة',
      'price': '99',
      'duration': '30 days',
      'durationAr': '30 يوم',
      'features': [
        'Enhanced visibility',
        'Priority support',
        'Featured listing',
        'Social media promotion'
      ],
      'featuresAr': [
        'رؤية محسنة',
        'دعم أولوية',
        'إعلان مميز',
        'ترويج على وسائل التواصل'
      ],
      'color': Color(0xFF4CAF50),
      'icon': Icons.star_half,
    },
    {
      'id': 'vip',
      'name': 'VIP Plan',
      'nameAr': 'الخطة الذهبية',
      'price': '199',
      'duration': '60 days',
      'durationAr': '60 يوم',
      'features': [
        'Maximum visibility',
        '24/7 premium support',
        'Top featured listing',
        'Multi-platform promotion',
        'Analytics dashboard'
      ],
      'featuresAr': [
        'أقصى رؤية',
        'دعم مميز 24/7',
        'إعلان في المقدمة',
        'ترويج متعدد المنصات',
        'لوحة تحليلات'
      ],
      'color': Color(0xFFFF9800),
      'icon': Icons.star,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isArabic = currentLocale == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        SizedBox(width: 5.w),
                        Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                        Transform.translate(
                          offset: Offset(-3.w, 0),
                          child: Text(
                            s!.back,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: KTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    isArabic ? 'اختر خطة الإعلان' : 'Choose Your Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.sp,
                      color: KTextColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isArabic 
                      ? 'اختر الخطة المناسبة لإعلانك للحصول على أفضل النتائج'
                      : 'Select the perfect plan for your ad to get the best results',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Plans List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: planTypes.length,
                itemBuilder: (context, index) {
                  final plan = planTypes[index];
                  final isSelected = selectedPlanType == plan['id'];
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? KPrimaryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedPlanType = plan['id'];
                        });
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plan Header
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: plan['color'].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    plan['icon'],
                                    color: plan['color'],
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isArabic ? plan['nameAr'] : plan['name'],
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: KTextColor,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        isArabic ? plan['durationAr'] : plan['duration'],
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      plan['price'] == '0' 
                                        ? (isArabic ? 'مجاني' : 'Free')
                                        : '\$${plan['price']}',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: plan['color'],
                                      ),
                                    ),
                                    if (plan['price'] != '0')
                                      Text(
                                        isArabic ? 'لكل إعلان' : 'per ad',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            // Features
                            ...List.generate(
                              (isArabic ? plan['featuresAr'] : plan['features']).length,
                              (featureIndex) {
                                final features = isArabic ? plan['featuresAr'] : plan['features'];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: plan['color'],
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          features[featureIndex],
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            // Selection indicator
                            if (isSelected)
                              Container(
                                margin: EdgeInsets.only(top: 12.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: KPrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: KPrimaryColor,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      isArabic ? 'محدد' : 'Selected',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: KPrimaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Continue Button
            Container(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedPlanType != null && !isLoading
                      ? _proceedWithSelectedPlan
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isArabic ? 'متابعة مع الخطة المحددة' : 'Continue with Selected Plan',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedWithSelectedPlan() async {
    if (selectedPlanType == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get token from secure storage
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Find selected plan details
      final selectedPlan = planTypes.firstWhere(
        (plan) => plan['id'] == selectedPlanType,
      );

      // Calculate expiry date based on plan duration
      final now = DateTime.now();
      int days = 7; // default
      if (selectedPlan['id'] == 'premium') {
        days = 15;
      } else if (selectedPlan['id'] == 'vip') {
        days = 30;
      }
      final expiryDate = now.add(Duration(days: days));

      // Prepare ad data with plan information
      final adDataWithPlan = Map<String, dynamic>.from(widget.adData);
      adDataWithPlan['planType'] = selectedPlanType;
      adDataWithPlan['planDays'] = days;
      adDataWithPlan['planExpiresAt'] = expiryDate.toIso8601String();

      // Submit ad to API
      await _repository.createCarRentAd(
        token: token,
        adData: adDataWithPlan,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر الإعلان بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home or ads list
        context.go('/');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}