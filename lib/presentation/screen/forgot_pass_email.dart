import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:advertising_app/presentation/widget/custom_text_field.dart';
import 'package:advertising_app/router/local_notifier.dart';
import 'package:go_router/go_router.dart';

// 1. تحويل الويدجت إلى StatefulWidget
class ForgotPassEmail extends StatefulWidget {
  final LocaleChangeNotifier notifier;

  const ForgotPassEmail({super.key, required this.notifier});

  @override
  State<ForgotPassEmail> createState() => _ForgotPassEmailState();
}

class _ForgotPassEmailState extends State<ForgotPassEmail> {
  // 2. تعريف الـ Form Key والـ Controller
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    // 3. التخلص من الـ Controller
    _emailController.dispose();
    super.dispose();
  }
  
  // 4. دالة لإرسال الكود بعد التحقق
  void _sendCode() {
    if (_formKey.currentState!.validate()) {
      // TODO: استدعاء دالة من Provider لإرسال الكود إلى البريد الإلكتروني
      print("Email is valid. Sending code to: ${_emailController.text}");
      context.push('/emailcode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.notifier.locale;
    final isArabic = locale.languageCode == 'ar';

    // لا حاجة لـ Directionality أو AnimatedBuilder هنا
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        // 5. استخدام Form
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
                      locale.languageCode == 'ar' ? S.of(context)!.arabic : S.of(context)!.english,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: KTextColor),
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
                S.of(context)!.forgetyourpass,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KTextColor,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16.h),
              Text(
                S.of(context)!.enteremail,
                style: TextStyle(
                  color: KTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 3.h),

              // 6. تحديث حقل الإدخال
              CustomTextField(
                controller: _emailController,
                hintText: 'Yourname@Example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty || !value.contains('@')) {
                    return S.of(context)!.pleaseEnterValidEmail;
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              
              // 7. تحديث زر الإرسال
              CustomButton(
                ontap: _sendCode,
                text: S.of(context)!.sendcode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}