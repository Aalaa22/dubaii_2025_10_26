import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:advertising_app/presentation/widget/custom_text_field.dart';
import 'package:advertising_app/router/local_notifier.dart';

class ResetPassword extends StatefulWidget {
  final LocaleChangeNotifier notifier;
  const ResetPassword({super.key, required this.notifier});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _submitNewPassword() {
    if (_formKey.currentState!.validate()) {
      // TODO: في المستقبل، هنا يمكنك استدعاء دالة من Provider لتغيير كلمة المرور عبر API
      print('Password is valid and ready to be changed.');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.notifier.locale;
    final isArabic = locale.languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 20.h),
              Row(
                children: [
                   Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(8), // لجعل التأثير دائريًا
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios, color: KTextColor, size: 16.sp),
                             Transform.translate(
                              offset: Offset(-5.w, 0), // قربنا النص من السهم
                              child: Text(
                                S.of(context)!.back,
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                 
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
        // --- هذا هو التصحيح ---
        // 1. نحدد اللغة الجديدة. إذا كانت الحالية 'en'، نغيرها إلى 'ar' والعكس.
        final currentLocale = widget.notifier.locale;
        final newLocale = currentLocale.languageCode == 'en'
            ? const Locale('ar')
            : const Locale('en');

        // 2. نستدعي الدالة الصحيحة باللغة الجديدة
        widget.notifier.changeLocale(newLocale);
    },
                    child: Text(
                      isArabic ? S.of(context)!.arabic : S.of(context)!.english,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: KTextColor,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 98.h,
                  width: 125.w,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                S.of(context)!.resetpass,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KTextColor,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16.h),

              Text(
                S.of(context)!.newpass,
                style: TextStyle(
                  color: KTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
              CustomTextField(
                controller: _newPasswordController,
                hintText: '********',
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return S.of(context)!.passwordTooShort;
                  }
                  return null;
                },
              ),

              SizedBox(height: 10.h),

              Text(
                S.of(context)!.confirmpass,
                style: TextStyle(
                  color: KTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: '********',
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context)!.pleaseConfirmPassword;
                  }
                  if (value != _newPasswordController.text) {
                    return S.of(context)!.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),

              SizedBox(height: 20.h),

              CustomButton(
                ontap: _submitNewPassword,
                text: S.of(context)!.confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}