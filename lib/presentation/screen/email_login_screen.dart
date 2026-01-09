// import 'package:advertising_app/presentation/providers/auth_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:advertising_app/constant/string.dart';
// import 'package:advertising_app/generated/l10n.dart';
// import 'package:advertising_app/presentation/widget/custom_button.dart';
// import 'package:advertising_app/presentation/widget/custom_elevated_button.dart';
// import 'package:advertising_app/presentation/widget/custom_text_field.dart';
// import 'package:advertising_app/router/local_notifier.dart';

// class EmailLoginScreen extends StatefulWidget {
//   final LocaleChangeNotifier notifier;

//   const EmailLoginScreen({
//     super.key,
//     required this.notifier,
//   });

//   @override
//   State<EmailLoginScreen> createState() => _EmailLoginScreenState();
// }

// class _EmailLoginScreenState extends State<EmailLoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _submitLogin() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     final authProvider = context.read<AuthProvider>();

//     // استدعاء دالة login بالبيانات الصحيحة
//     final success = await authProvider.login(
//       identifier: _emailController.text,
//       password: _passwordController.text,
//     );
    
//     if (!mounted) return;

//     if (success) {
//       context.go('/home');
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(authProvider.errorMessage ?? S.of(context)!.unknownError),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final locale = widget.notifier.locale;
//     final isArabic = locale.languageCode == 'ar';

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
//                 alignment: isArabic ? Alignment.topLeft : Alignment.topRight,
//                 child: GestureDetector(
//                   onTap: () {
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
//                     isArabic ? S.of(context)!.arabic : S.of(context)!.english,
//                     style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: KTextColor),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 12.h),
//               Center(
//                 child: Image.asset(
//                   'assets/images/logo.png',
//                   height: 98.h,
//                   width: 125.w,
//                 ),
//               ),
//               SizedBox(height: 10.h),
//               Text(
//                 S.of(context)!.login,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: KTextColor, fontSize: 24.sp, fontWeight: FontWeight.w500),
//               ),
//               SizedBox(height: 18.h),
//               Text(
//                 S.of(context)!.emailLogin,
//                 style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp),
//               ),
//               CustomTextField(
//                 controller: _emailController,
//                 hintText: 'YourName@Example.Com',
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || !value.contains('@')) {
//                     return S.of(context)!.pleaseEnterValidEmail;
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 8.h),
//               Text(
//                 S.of(context)!.password,
//                 style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp),
//               ),
//               CustomTextField(
//                 controller: _passwordController,
//                 hintText: '********',
//                 isPassword: true,
//                 validator: (value) {
//                   if (value == null || value.length < 6) {
//                     return S.of(context)!.passwordTooShort;
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20.h),
//               if (authProvider.isLoading)
//                 const Center(child: CircularProgressIndicator())
//               else
//                 CustomButton(
//                   text: S.of(context)!.login,
//                   ontap: _submitLogin,
//                 ),
//               SizedBox(height: 8.h),
//               GestureDetector(
//                 onTap: () => context.push('/forgetpassemail'),
//                 child: Text(
//                   S.of(context)!.forgotPassword,
//                   textAlign: TextAlign.end,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     fontSize: 14.sp,
//                     decoration: TextDecoration.underline,
//                     decorationThickness: 1.5,
//                     color: KTextColor,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 14.h),
//               Row(
//                 children: [
//                   const Expanded(child: Divider(color: KTextColor, thickness: 2)),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 10.w),
//                     child: Text(
//                       S.of(context)!.or,
//                       style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp),
//                     ),
//                   ),
//                   const Expanded(child: Divider(color: KTextColor, thickness: 2)),
//                 ],
//               ),
//               SizedBox(height: 16.h),
//               Row(
//                 children: [
//                   Expanded(
//                     child: CustomElevatedButton(
//                       onpress: () => context.go('/login'),
//                       text: S.of(context)!.phoneLogin,
//                     ),
//                   ),
//                   SizedBox(width: 16.w),
//                   Expanded(
//                     child: CustomElevatedButton(
//                       onpress: () => context.go('/home'),
//                       text: S.of(context)!.guestLogin,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16.h),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     S.of(context)!.dontHaveAccount,
//                     style: TextStyle(color: KTextColor, fontSize: 13.sp),
//                   ),
//                   SizedBox(width: 4.w),
//                   GestureDetector(
//                     onTap: () => context.go('/signup'),
//                     child: Text(
//                       S.of(context)!.createAccount,
//                       style: TextStyle(
//                         decoration: TextDecoration.underline,
//                         decorationColor: KTextColor,
//                         decorationThickness: 1.5,
//                         color: KTextColor,
//                         fontWeight: FontWeight.w500,
//                         fontSize: 13.sp,
//                       ),
//                     ),
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