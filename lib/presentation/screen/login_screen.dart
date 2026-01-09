// // ملف: login_screen.dart
// import 'package:advertising_app/presentation/providers/auth_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:advertising_app/constant/string.dart';
// import 'package:advertising_app/generated/l10n.dart';
// import 'package:advertising_app/presentation/widget/custom_button.dart';
// import 'package:advertising_app/presentation/widget/custom_elevated_button.dart';
// import 'package:advertising_app/presentation/widget/custom_phone_field.dart';
// import 'package:advertising_app/presentation/widget/custom_text_field.dart';
// import 'package:advertising_app/router/local_notifier.dart';

// class LoginScreen extends StatefulWidget {
//   final LocaleChangeNotifier notifier;
//   const LoginScreen({super.key, required this.notifier, required Null Function(dynamic locale) onLanguageChange});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();

//   // ✨ 1. أضف متغير جديد لتخزين الرقم الكامل
//   String _fullPhoneNumber = '';

//   Future<void> _submitLogin() async {
//     if (!_formKey.currentState!.validate()) return;

//     final authProvider = context.read<AuthProvider>();

//     // ✨ 3. استخدم المتغير الجديد هنا بدلاً من _phoneController.text
//     final success = await authProvider.login(
//       identifier: _fullPhoneNumber, // <--- التغيير الأهم
//       password: _passwordController.text,
//     );

//     if (!mounted) return;
//     if (success) {
//       context.go('/home');
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(authProvider.errorMessage ?? S.of(context)!.unknownError),
//         backgroundColor: Colors.red,
//       ));
//     }
//   }

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final locale = widget.notifier.locale;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 18.w),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               SizedBox(height: 24.h),
//               Align(
//                 alignment: locale.languageCode == 'ar'
//                     ? Alignment.topLeft
//                     : Alignment.topRight,
//                 child: GestureDetector(
//                  onTap: () {
//         // --- هذا هو التصحيح ---
//         // 1. نحدد اللغة الجديدة. إذا كانت الحالية 'en'، نغيرها إلى 'ar' والعكس.
//         final currentLocale = widget.notifier.locale;
//         final newLocale = currentLocale.languageCode == 'en'
//             ? const Locale('ar')
//             : const Locale('en');

//         // 2. نستدعي الدالة الصحيحة باللغة الجديدة
//         widget.notifier.changeLocale(newLocale);
//     },
//                   child: Text(
//                     locale.languageCode == 'ar'
//                         ? S.of(context)!.arabic
//                         : S.of(context)!.english,
//                     style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                         color: KTextColor),
//                   ),
//                 ),
//               ),
//               Image.asset('assets/images/logo.png',
//                   fit: BoxFit.contain, height: 98.h, width: 125.w),
//               SizedBox(height: 10.h),
//               Text(S.of(context)!.login,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                       color: KTextColor,
//                       fontSize: 24.sp,
//                       fontWeight: FontWeight.w500)),
//               SizedBox(height: 10.h),
//               Text(S.of(context)!.phone,
//                   style: TextStyle(
//                       color: KTextColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 16.sp)),
//               Stack(
//                 children: [
//                   CustomPhoneField(
//                     controller: _phoneController,
//                     // ✨ 2. استخدم الـ callback لتحديث المتغير بالرقم الكامل
//                     onPhoneNumberChanged: (fullNumber) {
//                       setState(() {
//                         _fullPhoneNumber = fullNumber;
//                       });
//                     },
//                   ),
//                   IgnorePointer(
//                     child: TextFormField(
//                       controller: _phoneController,
//                       validator: (v) => v!.trim().isEmpty
//                           ? S.of(context)!.pleaseEnterPhone
//                           : null,
//                       decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           errorBorder: InputBorder.none,
//                           contentPadding: EdgeInsets.zero),
//                       readOnly: true,
//                       style:
//                           const TextStyle(height: 0, color: Colors.transparent),
//                       buildCounter: (context,
//                               {required currentLength,
//                               required isFocused,
//                               maxLength}) =>
//                           null,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 5.h),
//               Text(S.of(context)!.password,
//                   style: TextStyle(
//                       color: KTextColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 16.sp)),
//               CustomTextField(
//                 controller: _passwordController,
//                 hintText: '12345678',
//                 isPassword: true,
//                 validator: (v) => (v == null || v.length < 6)
//                     ? S.of(context)!.passwordTooShort
//                     : null,
//               ),
//               SizedBox(height: 20.h),
//               if (authProvider.isLoading)
//                 const Center(child: CircularProgressIndicator())
//               else
//                 CustomButton(ontap: _submitLogin, text: S.of(context)!.login),
//               SizedBox(height: 8.h),
//               GestureDetector(
//                 onTap: () => context.push('/passphonelogin'),
//                 child: Text(S.of(context)!.forgotPassword,
//                     textAlign: TextAlign.end,
//                     style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         fontSize: 14.sp,
//                         decoration: TextDecoration.underline,
//                         decorationThickness: 1.5,
//                         color: KTextColor)),
//               ),
//               SizedBox(height: 14.h),
//               Row(
//                 children: [
//                   const Expanded(
//                       child: Divider(color: KTextColor, thickness: 2)),
//                   Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 10.w),
//                       child: Text(S.of(context)!.or,
//                           style: TextStyle(
//                               color: KTextColor,
//                               fontWeight: FontWeight.w500,
//                               fontSize: 16.sp))),
//                   const Expanded(
//                       child: Divider(color: KTextColor, thickness: 2)),
//                 ],
//               ),
//               SizedBox(height: 16.h),
//               Row(
//                 children: [
//                   Expanded(
//                       child: CustomElevatedButton(
//                           onpress: () => context.push('/emaillogin'),
//                           text: S.of(context)!.emailLogin)),
//                   SizedBox(width: 16.w),
//                   Expanded(
//                       child: CustomElevatedButton(
//                           onpress: () {
//                            // context.go('/home');
//                           },
//                           text: S.of(context)!.guestLogin)),
//                 ],
//               ),
//               SizedBox(height: 16.h),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(S.of(context)!.dontHaveAccount,
//                       style: TextStyle(color: KTextColor, fontSize: 13.sp)),
//                   SizedBox(width: 4.w),
//                   GestureDetector(
//                     onTap: () => context.go('/signup'),
//                     child: Text(S.of(context)!.createAccount,
//                         style: TextStyle(
//                             decoration: TextDecoration.underline,
//                             decorationColor: KTextColor,
//                             decorationThickness: 1.5,
//                             color: KTextColor,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 13.sp)),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 30.h),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }