import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

// تأكد من استيراد هذه الملفات من مشروعك
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:advertising_app/presentation/providers/car_services_ad_provider.dart';
import 'package:advertising_app/presentation/providers/car_rent_ad_provider.dart';
import 'package:advertising_app/presentation/providers/restaurants_ad_provider.dart';
import 'package:advertising_app/presentation/providers/real_estate_ad_provider.dart';
import 'package:advertising_app/presentation/providers/electronics_ad_post_provider.dart';
import 'package:advertising_app/presentation/providers/other_services_ad_post_provider.dart';
import 'package:advertising_app/presentation/providers/job_ad_provider.dart';

class PaymentScreen extends StatelessWidget {
  final Function(Locale) onLanguageChange;
  final Map<String, dynamic>? adData;
  final num? amount;
  final String? apiMessage;

  const PaymentScreen({
    Key? key,
    required this.onLanguageChange,
    this.adData,
    this.amount,
    this.apiMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final primaryColor = Color.fromRGBO(1, 84, 126, 1);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    final String totalAmountStr = amount == null
        ? '0'
        : (amount is double ? (amount as double).toStringAsFixed(0) : amount.toString());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 25.h),

              // Back Button (مثل الشاشات السابقة)
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    SizedBox(width: 5.w),
                    Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                    Transform.translate(
                      offset: Offset(-3.w, 0),
                      child: Text(
                        s.back,
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
              SizedBox(height: 7.h),

              Center(
                child: Text(
                  s.payment,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 24.sp,
                    color: KTextColor,
                  ),
                ),
              ),
              SizedBox(height: 25.h),

              // API message from previous step (optional)
              if (apiMessage != null && apiMessage!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  margin: EdgeInsets.only(bottom: 10.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: primaryColor.withOpacity(0.15)),
                  ),
                  child: Text(
                    _cleanMessage(apiMessage!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),

              // Total Section
              _buildTotalSection(s, totalAmountStr),
              SizedBox(height: 5.h),

              // Payment Form Section
              _buildPaymentForm(s, borderColor, currentLocale),
              SizedBox(height: 10.h),

              // Pay Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _payAndSubmit(context),
                  child: Text(s.payNow,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- الدوال المساعدة ---

  Widget _buildTotalSection(S s, String totalAmountStr) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(228, 248, 246, 1),
              Color.fromRGBO(201, 248, 254, 1)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
            )
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(s.total,
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: KTextColor)),
          Text("AED $totalAmountStr",
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Color.fromRGBO(227, 34, 17, 1))),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(S s, Color borderColor, String currentLocale) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/ri_visa-fill.png',
                  width: 40.w), // تأكد من وجود صورة الشعار هنا
              SizedBox(width: 4.w),
              Text(s.payWithCreditCard,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: KTextColor)),
            ],
          ),
          SizedBox(height: 13.h),
          _buildTitledTextField(
              s.cardNumber, '1234567891011111', borderColor, currentLocale,
              isNumber: true),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildTitledTextField2(
                      s.expireDate, '09/2024', borderColor, currentLocale)),
              SizedBox(width: 15.w),
              Expanded(
                  child: _buildTitledTextField2(
                      s.cvv, '123', borderColor, currentLocale,
                      isNumber: true)),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTitledTextField(
              s.cardHolderName, 'Ahmed Ali', borderColor, currentLocale),
        ],
      ),
    );
  }

  Widget _buildTitledTextField(String title, String initialValue,
      Color borderColor, String currentLocale,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(0, 30, 91, 1),
                fontSize: 16.sp)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 30, 91, 1),
              fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Color.fromRGBO(1, 84, 126, 1), width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTitledTextField2(String title, String initialValue,
      Color borderColor, String currentLocale,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(0, 30, 91, 1),
                fontSize: 14.sp)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 30, 91, 1),
              fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Color.fromRGBO(1, 84, 126, 1), width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Future<void> _payAndSubmit(BuildContext context) async {
    final s = S.of(context);
    if (adData == null || adData!['adType'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بيانات الإعلان غير كاملة'), backgroundColor: Colors.red),
      );
      return;
    }

    final String adType = adData!['adType'];
    bool success = false;
    String? submissionError;

    // Ensure payment flag is included with the ad body
    try {
      adData!['payment'] = 1;
    } catch (_) {}

    // طباعة منظمة لحظة الدفع فقط (بدلاً من الطباعة أثناء الضغط على Submit)
    try {
      final planType = adData?['planType'];
      final planDays = adData?['planDays'];
      final planExpiresAt = adData?['planExpiresAt'];
      print('Terminal#948-948: === بدء عملية الدفع وإرسال الإعلان ===');
      print('نوع الإعلان: $adType');
      print('Plan Type: $planType');
      print('Plan Days: $planDays');
      print('Plan Expires At: $planExpiresAt');
      print('المبلغ للدفع: ${amount ?? '0'}');
      print('payment flag: ${adData?['payment']}');
      print('بيانات الإعلان قبل الإرسال (الدفع): ${adData}');
    } catch (_) {}

    try {
      if (adType == 'car_sale') {
        final provider = context.read<CarAdProvider>();
        success = await provider.submitCarAd(adData!);
        submissionError = provider.submitAdError;
      } else if (adType == 'car_service') {
        final provider = context.read<CarServicesAdProvider>();
        success = await provider.submitCarServiceAd(adData!);
        submissionError = provider.error;
      } else if (adType == 'car_rent') {
        final provider = context.read<CarRentAdProvider>();
        success = await provider.submitCarRentAd(adData!);
        submissionError = provider.createAdError;
      } else if (adType == 'restaurant') {
        final provider = context.read<RestaurantsAdProvider>();
        success = await provider.submitRestaurantAd(adData!);
        submissionError = provider.error;
      } else if (adType == 'real_estate') {
        final provider = context.read<RealEstateAdProvider>();
        success = await provider.submitRealEstateAd(adData!);
        submissionError = provider.error;
      } else if (adType == 'electronics') {
        final provider = context.read<ElectronicsAdPostProvider>();
        success = await provider.submitElectronicsAd(adData!);
        submissionError = provider.error;
      } else if (adType == 'job') {
        final provider = context.read<JobAdProvider>();
        success = await provider.submitJobAd(adData!);
        submissionError = provider.submitAdError;
      } else if (adType == 'other_service') {
        final provider = context.read<OtherServicesAdPostProvider>();
        success = await provider.submitOtherServiceAd(adData!);
        submissionError = provider.error;
      }

      // طباعة نتيجة الإرسال بعد الدفع
      try {
        print('نتيجة الإرسال بعد الدفع: $success');
        print('خطأ الإرسال (إن وجد): $submissionError');
        print('Terminal#948-948: === انتهاء عملية الدفع والإرسال ===');
      } catch (_) {}

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الدفع ونشر الإعلان بنجاح'), backgroundColor: Colors.green),
        );
        context.push('/manage');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cleanMessage(submissionError ?? 'فشل في نشر الإعلان بعد الدفع')), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanMessage('حدث خطأ: $e')), backgroundColor: Colors.red),
      );
    }
  }

  String _cleanMessage(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'^\s*Exception:\s*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'Exception:\s*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^\s*exeption:\s*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'exeption:\s*', caseSensitive: false), '');
    return s.trim();
  }
}
