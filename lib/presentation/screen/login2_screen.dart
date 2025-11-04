// ملف: login2.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:advertising_app/presentation/widget/custom_elevated_button.dart';
import 'package:advertising_app/presentation/widget/custom_phone_field.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/router/local_notifier.dart';
import 'package:advertising_app/core/scaffold_messenger_key.dart';

class Login2 extends StatefulWidget {
  final LocaleChangeNotifier notifier;
  // تم حذف المعامل الثاني لأنه لم يكن مستخدماً، ولكن تم الإبقاء على notifier
  // لأنه مستخدم في تغيير لغة الواجهة
  const Login2({super.key, required this.notifier});

  @override
  State<Login2> createState() => _Login2State();
}

class _Login2State extends State<Login2> {
  final _phoneController = TextEditingController();
  final _passwordController =
      TextEditingController(); // إضافة controller لكلمة المرور
  String _fullPhoneNumber = '';
  bool _isPasswordVisible = false; // للتحكم في إظهار/إخفاء كلمة المرور
  bool _showPasswordField = false; // للتحكم في إظهار حقل كلمة المرور

  @override
  void initState() {
    super.initState();
    // إضافة listener لمراقبة تغيير رقم الهاتف
    _phoneController.addListener(_onPhoneNumberChanged);
  }

  // دالة لمراقبة تغيير رقم الهاتف وتحديد نوع المستخدم
  void _onPhoneNumberChanged() {
    setState(() {
      _showPasswordField = _isAdvertiserPhone(_fullPhoneNumber);
    });
  }

  // دالة للتحقق من أن رقم الهاتف خاص بمعلن (Terminal#937-937)
  bool _isAdvertiserPhone(String phoneNumber) {
    // إزالة المسافات والرموز الإضافية
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // التحقق من أن الرقم ينتهي بـ 937-937 (أو يحتوي على هذا النمط)
    return cleanPhone.contains('937937') || cleanPhone.endsWith('937937');
  }

  // تنظيف نصوص الأخطاء لإزالة كلمة Exception وأي بادئات مزعجة
  String _sanitizeErrorMessage(String? raw, String fallback) {
    try {
      if (raw == null) return fallback;
      var text = raw;
      // أزل بادئة Exception: (غير حساس لحالة الأحرف) وأي مسافات لاحقة
      text = text
          .replaceAll(RegExp('exception:?\\s*', caseSensitive: false), '')
          .trim();
      // أزل بادئة Error: (غير حساس لحالة الأحرف)
      text = text
          .replaceAll(RegExp('^error:\\s*', caseSensitive: false), '')
          .trim();
      // في حال كان النص يتضمن هيكل {message: ...}
      final lower = text.toLowerCase();
      final msgIndex = lower.indexOf('message:');
      if (msgIndex != -1) {
        final after = text.substring(msgIndex + 'message:'.length).trim();
        // اقتطع حتى أول فاصلة أو قوس
        final stopChars = [',', '}'];
        int cut = after.length;
        for (final ch in stopChars) {
          final i = after.indexOf(ch);
          if (i != -1 && i < cut) cut = i;
        }
        final extracted = after.substring(0, cut).trim();
        if (extracted.isNotEmpty) return extracted;
      }
      return text.isNotEmpty ? text : fallback;
    } catch (_) {
      // في حال حدوث أي خطأ أثناء التنظيف، أعِد النص البديل الآمن
      return fallback;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose(); // تنظيف controller كلمة المرور
    super.dispose();
  }

  // دالة للتعامل مع تسجيل الدخول
  Future<void> _handleLogin() async {
    final s = S.of(context);
    if (_fullPhoneNumber.isEmpty) {
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(s.enterphone),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من كلمة المرور للمعلنين
    if (_showPasswordField && _passwordController.text.trim().isEmpty) {
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(s.pleaseEnterPassword),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      bool success = false;

      // إرسال البيانات حسب نوع المستخدم
      if (_showPasswordField) {
        print('=== LOGIN WITH PASSWORD ===');
        // إذا كان حقل كلمة المرور ظاهر، استخدم loginWithPassword
        success = await authProvider.loginWithPassword(
            phone: _fullPhoneNumber, password: _passwordController.text.trim());
        print('Login with password result: $success');
        print('Auth provider error: ${authProvider.errorMessage}');
      } else {
        print('=== REGULAR LOGIN ATTEMPT ===');
        // محاولة تسجيل الدخول العادي أولاً
        success = await authProvider.login(phone: _fullPhoneNumber);
        print('Regular login result: $success');
        print('Auth provider error: ${authProvider.errorMessage}');

        // إذا فشل تسجيل الدخول العادي، تحقق من سبب الفشل
        if (!success && authProvider.errorMessage != null) {
          print('=== CHECKING ERROR MESSAGE ===');
          print('Error message: "${authProvider.errorMessage}"');

          // تحقق من أن الخطأ يتعلق بطلب كلمة المرور
          final errorMsg = authProvider.errorMessage!.toLowerCase();
          print('Error message (lowercase): "$errorMsg"');

          // فحص محسن للأخطاء - البحث عن رسائل كلمة المرور في النص الكامل
          bool isPasswordRequired = false;

          // فحص الرسالة الأصلية للبحث عن أخطاء التحقق
          if (errorMsg.contains('validation_error:')) {
            // استخراج البيانات من رسالة الخطأ
            final errorData = authProvider.errorMessage!.substring(
                authProvider.errorMessage!.indexOf('validation_error:') + 17);
            print('Validation error data: $errorData');
            isPasswordRequired = errorData.contains('password') &&
                errorData.contains('required');
          } else {
            // الفحص التقليدي
            isPasswordRequired = errorMsg.contains('password') ||
                errorMsg.contains('required') ||
                errorMsg.contains('the password field is required') ||
                errorMsg.contains('كلمة المرور') ||
                errorMsg.contains('مطلوب');
          }

          print('Is password required: $isPasswordRequired');

          if (isPasswordRequired) {
            print('=== SHOWING PASSWORD FIELD ===');
            // إظهار حقل كلمة المرور تلقائياً
            if (!mounted) return;
            setState(() {
              _showPasswordField = true;
            });

            // عرض رسالة توضيحية للمستخدم
            rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(s.passwordRequiredToCompleteLogin),
                backgroundColor: Color.fromRGBO(1, 84, 126, 1),
              ),
            );
            return; // الخروج من الدالة لإعطاء المستخدم فرصة لإدخال كلمة المرور
          }
        }
      }

      if (success) {
        print('=== LOGIN SUCCESS ===');
        if (!mounted) return;
        final String userType =
            (authProvider.userType ?? authProvider.user?.userType ?? '')
                .toLowerCase();
        print('User type: $userType');
        // تأخير التنقل لتجنب مشاكل السياق مع التخلص من الواجهة
        Future.microtask(() {
          if (!mounted) return;
          if (userType == 'advertiser') {
            context.push('/home');
          } else {
            context.go('/');
          }
        });
      } else {
        print('=== LOGIN FAILED ===');
        // عرض رسالة خطأ عامة فقط إذا لم تكن متعلقة بكلمة المرور
        if (authProvider.errorMessage != null) {
          final errorMsg = authProvider.errorMessage!.toLowerCase();
          bool isPasswordError = errorMsg.contains('password') ||
              errorMsg.contains('required') ||
              errorMsg.contains('كلمة المرور') ||
              errorMsg.contains('مطلوب');

          if (!isPasswordError) {
            final clean = _sanitizeErrorMessage(authProvider.errorMessage, s.loginError);
            rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(clean),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('=== EXCEPTION CAUGHT ===');
      print('Exception: $e');
      if (!mounted) return; // التحقق من أن الواجهة لا تزال مركبة
      // التعامل مع الأخطاء غير المتوقعة
      final clean = _sanitizeErrorMessage(e.toString(), s.loginError);
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(clean),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.notifier.locale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: ListView(
          children: [
            SizedBox(height: 24.h),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: GestureDetector(
               onTap: () {
                  // تم الإبقاء على هذا لأنه تغيير في حالة الـ UI المحلية فقط
                  final currentLocale = widget.notifier.locale;
                  final newLocale = currentLocale.languageCode == 'en'
                      ? const Locale('ar')
                      : const Locale('en');
                  widget.notifier.changeLocale(newLocale);
                },
                child: Text(
                  locale.languageCode == 'ar'
                      ? S.of(context).arabic
                      : S.of(context).english,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: KTextColor),
                ),
              ),
            ),
            SizedBox(height: 50.h),
            Image.asset('assets/images/logo.png',
                fit: BoxFit.contain, height: 115.h, width: 135.w),
            // SizedBox(height: 3.h),
            Text(S.of(context).enjoyFreeAds,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: KTextColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 10.h),
            Text(S.of(context).login,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: KTextColor,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 10.h),
            Text(S.of(context).phone,
                style: TextStyle(
                    color: KTextColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp)),

            // حقل الهاتف مع callback لحفظ الرقم الكامل
            CustomPhoneField(
              controller: _phoneController,
              onPhoneNumberChanged: (fullNumber) {
                _fullPhoneNumber = fullNumber;
                // تحديث حالة إظهار حقل كلمة المرور عند تغيير الرقم
                setState(() {
                  _showPasswordField = _isAdvertiserPhone(fullNumber);
                });
              },
            ),

            SizedBox(height: 8.h),

            // إضافة حقل كلمة المرور للمعلنين فقط
            if (_showPasswordField) ...[
              Text(
                S.of(context).password,
                style: TextStyle(
                  color: KTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 3.h),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(
                    color: KTextColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: S.of(context).enterpassword,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.sp,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              // جملة Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // TODO: إضافة منطق نسيان كلمة المرور
                    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                    rootScaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(S.of(context).passwordResetComingSoon),
                      ),
                    );
                  },
                  child: Text(
                    S.of(context).forgotPassword,
                    style: TextStyle(
                      color: KTextColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],

            SizedBox(height: 5.h),

            // جملة الموافقة على الشروط والأحكام

            // زر تسجيل الدخول مع منطق كامل
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return CustomButton(
                  ontap: authProvider.isLoading ? null : _handleLogin,
                  text: authProvider.isLoading
                      ? S.of(context).loggingIn
                      : S.of(context).login,
                );
              },
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Directionality(
                    textDirection: locale.languageCode == 'ar' 
                        ? TextDirection.rtl 
                        : TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).byContinueIAgreeTo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: KTextColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          S.of(context).termsAndConditions,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: KTextColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Directionality(
                      textDirection: locale.languageCode == 'ar' 
                          ? TextDirection.rtl 
                          : TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            S.of(context).and,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: KTextColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            S.of(context).privacyPolicy,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: KTextColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // SizedBox(height: 14.h),
            // Row(
            //   children: [
            //     const Expanded(
            //         child: Divider(color: KTextColor, thickness: 2)),
            //     Padding(
            //         padding: EdgeInsets.symmetric(horizontal: 10.w),
            //         child: Text(S.of(context).or,
            //             style: TextStyle(
            //                 color: KTextColor,
            //                 fontWeight: FontWeight.w500,
            //                 fontSize: 16.sp))),
            //     const Expanded(
            //         child: Divider(color: KTextColor, thickness: 2)),
            //   ],
            // ),
            // SizedBox(height: 16.h),
            // Row(
            //   children: [
            //     Expanded(
            //         child: CustomElevatedButton(
            //             onpress: () {
            //                // UI Only - No Logic
            //             },
            //             text: S.of(context).emailLogin)),
            //     SizedBox(width: 16.w),
            //     Expanded(
            //         child: CustomElevatedButton(
            //             onpress: () {
            //                // UI Only - No Logic
            //             },
            //             text: S.of(context).guestLogin)),
            //   ],
            // ),
            // SizedBox(height: 16.h),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Text(S.of(context).dontHaveAccount,
            //         style: TextStyle(color: KTextColor, fontSize: 13.sp)),
            //     SizedBox(width: 4.w),
            //     GestureDetector(
            //       onTap: () {
            //          // UI Only - No Logic
            //       },
            //       child: Text(S.of(context).createAccount,
            //           style: TextStyle(
            //               decoration: TextDecoration.underline,
            //               decorationColor: KTextColor,
            //               decorationThickness: 1.5,
            //               color: KTextColor,
            //               fontWeight: FontWeight.w500,
            //               fontSize: 13.sp)),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
