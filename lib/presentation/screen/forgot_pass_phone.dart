import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:advertising_app/presentation/widget/custom_phone_field.dart';
import 'package:advertising_app/presentation/widget/custom_text_field.dart';
import 'package:advertising_app/router/local_notifier.dart';

class ForgotPassPhone extends StatefulWidget {
  final LocaleChangeNotifier notifier;

  const ForgotPassPhone({super.key, required this.notifier});

  @override
  State<ForgotPassPhone> createState() => _ForgotPassPhoneState();
}

class _ForgotPassPhoneState extends State<ForgotPassPhone> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool showEmailField = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  void _sendCode() {
    if (_formKey.currentState!.validate()) {
      // TODO: Call Provider to send verification code
      print("Phone number is valid. Sending code...");
      context.push('/phonecode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.notifier.locale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  // --- هنا تم التعديل على زر الرجوع ---
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: KTextColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Image.asset('assets/images/logo.png', fit: BoxFit.contain, height: 98, width: 125),
              const SizedBox(height: 10),
              Text(
                S.of(context)!.forgetyourpass,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KTextColor, fontSize: 20, fontWeight: FontWeight.w500),
                maxLines: 1,
              ),
              const SizedBox(height: 15),
              Text(
                S.of(context)!.enterphone,
                style: const TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16),
              ),
              const SizedBox(height: 3),

              // --- هنا تم إصلاح حقل الهاتف ---
              Stack(
                children: [
                  CustomPhoneField(
                    controller: _phoneController,
                    onCountryChanged: (code) {
                      setState(() { showEmailField = code != 'AE'; });
                    },
                  ),
                  IgnorePointer(
                    child: TextFormField(
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          // تأكد من أن هذه الرسالة صحيحة للترجمة
                          return S.of(context)!.pleaseEnterPhone;
                        }
                        return null;
                      },
                      readOnly: true,
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, errorBorder: InputBorder.none),
                      style: const TextStyle(height: 0, color: Colors.transparent),
                       buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    ),
                  ),
                ],
              ),

              if (showEmailField)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: CustomTextField(
                    controller: _emailController,
                    hintText: S.of(context)!.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                       if (value == null || !value.contains('@')) {
                        return S.of(context)!.pleaseEnterValidEmail;
                       }
                       return null;
                    },
                  ),
                ),
              const SizedBox(height: 20),

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