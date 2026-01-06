// ملف: custom_phone_field.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart'; // استيراد ضروري للحصول على كائن PhoneNumber
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';

class CustomPhoneField extends StatelessWidget {
  final Function(String)? onCountryChanged;
  final Function(String)? onPhoneNumberChanged; // Callback جديد لإرسال الرقم الكامل
  final TextEditingController controller;

  const CustomPhoneField({
    super.key,
    this.onCountryChanged,
    this.onPhoneNumberChanged, // تمت إضافته هنا
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // الحل النهائي لمشكلة لون النص في البحث عبر تغليف الويدجت بـ Theme
    return Theme(
      data: Theme.of(context).copyWith(
        // تحديد خصائص حقول الإدخال
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
              labelStyle: const TextStyle(color: Colors.grey),
              floatingLabelStyle: const TextStyle(color: KTextColor),
            ),
        // تحديد لون النص الذي يتم كتابته داخل حقل البحث
        textTheme: Theme.of(context).textTheme.copyWith(
              titleMedium: const TextStyle(color: KTextColor), // لـ Material 3
             // subtitle1: const TextStyle(color: KTextColor),   // لـ Material 2 (احتياطي)
            ).apply(
              bodyColor: KTextColor,
              displayColor: KTextColor,
            ),
      ),
      child: IntlPhoneField(
        controller: controller,
        initialCountryCode: 'AE',
        style: TextStyle(
          color: KTextColor,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: S.of(context)!.phoneNumberHint,
          hintStyle: const TextStyle(
              color: Color.fromRGBO(129, 126, 126, 1),
              fontSize: 14,
              fontWeight: FontWeight.w500),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide:
                BorderSide(color: Color.fromRGBO(8, 194, 201, 1), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
          ),
          counterText: '',
        ),
        dropdownTextStyle: TextStyle(
          color: KTextColor,
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
        pickerDialogStyle: PickerDialogStyle(
          searchFieldInputDecoration: InputDecoration(
            labelText: S.of(context)!.searchCountry,
          ),
          countryNameStyle: const TextStyle(color: KTextColor),
        ),

        // ✨ التعديل الأهم هنا ✨
        // يتم استدعاؤه عند تغيير الرقم أو الدولة
        onChanged: (PhoneNumber phone) {
          if (onPhoneNumberChanged != null) {
            // نمرر الرقم الكامل (مثال: "+971501234567") للخارج
            onPhoneNumberChanged!(phone.completeNumber);
          }
        },
        
        // هذه تبقى كما هي للتعامل مع تغيير الدولة فقط
        onCountryChanged: (country) {
          if (onCountryChanged != null) {
            onCountryChanged!(country.code);
          }
        },
      ),
    );
  }
}