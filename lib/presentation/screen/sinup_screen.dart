// // ملف: sign_up_screen.dart

// import 'package:advertising_app/presentation/providers/auth_repository.dart';
// import 'package:advertising_app/presentation/widget/custom_text_field.dart';
// import 'package:advertising_app/router/local_notifier.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:advertising_app/constant/string.dart';
// import 'package:advertising_app/generated/l10n.dart';
// import 'package:advertising_app/presentation/widget/custom_button.dart';
// import 'package:advertising_app/presentation/widget/custom_elevated_button.dart';
// import 'package:advertising_app/presentation/widget/custom_phone_field.dart';

// class SignUpScreen extends StatefulWidget {
//   final LocaleChangeNotifier notifier;
//   const SignUpScreen({super.key, required this.notifier, required Null Function(dynamic locale) onLanguageChange});

//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }

// // الكود الكامل والمعدّل يبدأ من هنا
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _phoneController = TextEditingController(); // لا يزال يستخدم للتحكم في الحقل
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _referralController = TextEditingController();

//   bool showEmailField = false;
//   bool isChecked = false;

//   // ✨ 1. أضفنا هذا المتغير لتخزين الرقم الكامل بالتنسيق الدولي
//   String _fullPhoneNumber = '';

//   Future<void> _submitSignUp() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (!isChecked) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(S.of(context)!.agreeTermsValidation),
//           backgroundColor: Colors.orange));
//       return;
//     }

//     final authProvider = context.read<AuthProvider>();

//     final emailToSend = showEmailField ? _emailController.text : "";

//     // ✨ 3. استخدمنا المتغير الجديد (_fullPhoneNumber) عند إرسال البيانات للـ API
//     final success = await authProvider.signUp(
//       username: _usernameController.text,
//       email: emailToSend,
//       password: _passwordController.text,
//       phone: _fullPhoneNumber, // <--- التغيير الأهم هنا
//       role: 'user',
//     );

//     if (!mounted) return;
//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(S.of(context)!.accountCreatedSuccessfully),
//           backgroundColor: Colors.green));
//       context.go('/home');
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content:
//               Text(authProvider.errorMessage ?? S.of(context)!.unknownError),
//           backgroundColor: Colors.red));
//     }
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _referralController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final locale = widget.notifier.locale;
//     final isTablet = MediaQuery.of(context).size.width >= 600;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             padding: EdgeInsets.symmetric(horizontal: isTablet ? 40.w : 18.w),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 5.h),
//                 Align(
//                   alignment: locale.languageCode == 'ar'
//                       ? Alignment.topLeft
//                       : Alignment.topRight,
//                   child: GestureDetector(
//                     onTap: () {
//         // --- هذا هو التصحيح ---
//         // 1. نحدد اللغة الجديدة. إذا كانت الحالية 'en'، نغيرها إلى 'ar' والعكس.
//         final currentLocale = widget.notifier.locale;
//         final newLocale = currentLocale.languageCode == 'en'
//             ? const Locale('ar')
//             : const Locale('en');

//         // 2. نستدعي الدالة الصحيحة باللغة الجديدة
//         widget.notifier.changeLocale(newLocale);
//     },
//                     child: Text(
//                       locale.languageCode == 'ar'
//                           ? S.of(context)!.arabic
//                           : S.of(context)!.english,
//                       style: TextStyle(
//                           fontSize: 16.sp,
//                           fontWeight: FontWeight.w500,
//                           color: KTextColor),
//                     ),
//                   ),
//                 ),
//                 Center(
//                   child: Image.asset('assets/images/logo.png',
//                       fit: BoxFit.contain, height: 85.h, width: 125.w),
//                 ),
//                 SizedBox(height: 5.h),
//                 Center(
//                   child: Text(
//                     S.of(context)!.signUp,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                         color: KTextColor,
//                         fontSize: 22.sp,
//                         fontWeight: FontWeight.w500),
//                   ),
//                 ),
//                 SizedBox(height: 5.h),
//                 Text(
//                   '${S.of(context)!.userName}*',
//                   style: TextStyle(
//                       color: KTextColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 16.sp),
//                 ),
//                 CustomTextField(
//                   controller: _usernameController,
//                   hintText: "Ralph Edwards",
//                   validator: (v) => v!.trim().isEmpty
//                       ? S.of(context)!.pleaseEnterUsername
//                       : null,
//                 ),
//                 SizedBox(height: 5.h),
//                 Text(
//                   '${S.of(context)!.phone}*',
//                   style: TextStyle(
//                       color: KTextColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 16.sp),
//                 ),
//                 Stack(
//                   children: [
//                     CustomPhoneField(
//                       controller: _phoneController,
//                       onCountryChanged: (code) {
//                         setState(() {
//                           showEmailField = code != 'AE';
//                         });
//                       },
//                       // ✨ 2. استقبلنا الرقم الكامل من CustomPhoneField وقمنا بتخزينه
//                       onPhoneNumberChanged: (fullNumber) {
//                         setState(() {
//                           _fullPhoneNumber = fullNumber;
//                         });
//                       },
//                     ),
//                     IgnorePointer(
//                       child: TextFormField(
//                         controller: _phoneController,
//                         validator: (v) =>
//                             v!.isEmpty ? S.of(context)!.pleaseEnterPhone : null,
//                         decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             contentPadding: EdgeInsets.zero,
//                             errorBorder: InputBorder.none),
//                         readOnly: true,
//                         style: const TextStyle(
//                             height: 0, color: Colors.transparent),
//                         buildCounter: (context,
//                                 {required currentLength,
//                                 required isFocused,
//                                 maxLength}) =>
//                             null,
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (showEmailField)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: 5.h),
//                       Text(
//                         '${S.of(context)!.email}*',
//                         style: TextStyle(
//                             color: KTextColor,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 16.sp),
//                       ),
//                       CustomTextField(
//                         controller: _emailController,
//                         hintText: "admin@dubisale.com",
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (value) {
//                           if (showEmailField &&
//                               (value == null || !value.contains('@'))) {
//                             return S.of(context)!.pleaseEnterValidEmail;
//                           }
//                           return null;
//                         },
//                       ),
//                     ],
//                   ),
//                 SizedBox(height: 5.h),
//                 Text(
//                   "${S.of(context)!.password}*",
//                   style: TextStyle(
//                       color: KTextColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 16.sp),
//                 ),
//                 CustomTextField(
//                   controller: _passwordController,
//                   hintText: '12345678',
//                   isPassword: true,
//                   validator: (v) =>
//                       v!.length < 6 ? S.of(context)!.passwordTooShort : null,
//                 ),
//                 SizedBox(height: 5.h),
//                 Text(
//                   S.of(context)!.referralCode,
//                   style: TextStyle(
//                       color: KTextColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 16.sp),
//                 ),
//                 CustomTextField(
//                     controller: _referralController, hintText: "XXXX"),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: isChecked,
//                       onChanged: (value) => setState(() => isChecked = value!),
//                       activeColor: const Color.fromRGBO(1, 84, 126, 1),
//                       checkColor: Colors.white,
//                     ),
//                     Expanded(
//                       child: Text(
//                         S.of(context)!.agreeTerms,
//                         style: TextStyle(
//                             fontSize: 14.sp,
//                             color: KTextColor,
//                             fontWeight: FontWeight.w500),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10.h),
//                 if (authProvider.isLoading)
//                   const Center(child: CircularProgressIndicator())
//                 else
//                   CustomButton(
//                       text: S.of(context)!.register, ontap: _submitSignUp),
//                 SizedBox(height: 4.h),
//                 Center(
//                   child: Text(
//                     S.of(context)!.or,
//                     style: TextStyle(
//                         color: KTextColor,
//                         fontWeight: FontWeight.w500,
//                         fontSize: 16.sp),
//                   ),
//                 ),
//                 SizedBox(height: 4.h),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Flexible(
//                       child: CustomElevatedButton(
//                         onpress: () => context.go('/emailsignup'),
//                         text: S.of(context)!.emailSignUp,
//                       ),
//                     ),
//                     SizedBox(width: 16.w),
//                     Flexible(
//                       child: CustomElevatedButton(
//                         onpress: () {
//                          // context.go("/home");
//                         },
//                         text: S.of(context)!.guestLogin,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 4.h),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       S.of(context)!.haveAccount,
//                       style: TextStyle(color: KTextColor, fontSize: 14.sp),
//                     ),
//                     SizedBox(width: 4.w),
//                     GestureDetector(
//                       onTap: () => context.go('/login'),
//                       child: Text(
//                         S.of(context)!.login,
//                         style: TextStyle(
//                           decoration: TextDecoration.underline,
//                           decorationColor: KTextColor,
//                           decorationThickness: 1.5,
//                           color: KTextColor,
//                           fontWeight: FontWeight.w500,
//                           fontSize: 14.sp,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 20.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



// // import 'package:advertising_app/presentation/providers/auth_repository.dart';
// // import 'package:advertising_app/presentation/widget/custom_text_field.dart';
// // import 'package:advertising_app/router/local_notifier.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:provider/provider.dart';
// // import 'package:advertising_app/constant/string.dart';
// // import 'package:advertising_app/generated/l10n.dart';
// // import 'package:advertising_app/presentation/widget/custom_button.dart';
// // import 'package:advertising_app/presentation/widget/custom_elevated_button.dart';
// // import 'package:advertising_app/presentation/widget/custom_phone_field.dart';

// // class SignUpScreen extends StatefulWidget {
// //   final LocaleChangeNotifier notifier;
// //   const SignUpScreen({super.key, required this.notifier});

// //   @override
// //   State<SignUpScreen> createState() => _SignUpScreenState();
// // }

// // class _SignUpScreenState extends State<SignUpScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _usernameController = TextEditingController();
// //   final _phoneController = TextEditingController();
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();
// //   final _referralController = TextEditingController();

// //    String _fullPhoneNumber = '';

// //   bool showEmailField = false;
// //   bool isChecked = false;

// //   Future<void> _submitSignUp() async {
// //     if (!_formKey.currentState!.validate()) return;
// //     if (!isChecked) {
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //           content: Text(S.of(context)!.agreeTermsValidation),
// //           backgroundColor: Colors.orange));
// //       return;
// //     }

// //     final authProvider = context.read<AuthProvider>();

// //     final emailToSend = showEmailField ? _emailController.text : "";

// //     final success = await authProvider.signUp(
// //       username: _usernameController.text,
// //       email: emailToSend,
// //       password: _passwordController.text,
// //       phone: _phoneController.text,
// //       role: 'user',
// //     );

// //     if (!mounted) return;
// //     if (success) {
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //           content: Text(S.of(context)!.accountCreatedSuccessfully),
// //           backgroundColor: Colors.green));
// //       context.go('/home');
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //           content:
// //               Text(authProvider.errorMessage ?? S.of(context)!.unknownError),
// //           backgroundColor: Colors.red));
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _usernameController.dispose();
// //     _phoneController.dispose();
// //     _emailController.dispose();
// //     _passwordController.dispose();
// //     _referralController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final authProvider = context.watch<AuthProvider>();
// //     final locale = widget.notifier.locale;
// //     final isTablet = MediaQuery.of(context).size.width >= 600;

// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: SafeArea(
// //         child: Form(
// //           key: _formKey,
// //           child: SingleChildScrollView(
// //             padding: EdgeInsets.symmetric(horizontal: isTablet ? 40.w : 18.w),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 SizedBox(height: 5.h),
// //                 Align(
// //                   alignment: locale.languageCode == 'ar'
// //                       ? Alignment.topLeft
// //                       : Alignment.topRight,
// //                   child: GestureDetector(
// //                     onTap: widget.notifier.toggleLocale,
// //                     child: Text(
// //                       locale.languageCode == 'ar'
// //                           ? S.of(context)!.arabic
// //                           : S.of(context)!.english,
// //                       style: TextStyle(
// //                           fontSize: 16.sp,
// //                           fontWeight: FontWeight.w500,
// //                           color: KTextColor),
// //                     ),
// //                   ),
// //                 ),
// //                 Center(
// //                   child: Image.asset('assets/images/logo.png',
// //                       fit: BoxFit.contain, height: 85.h, width: 125.w),
// //                 ),
// //                 SizedBox(height: 5.h),
// //                 Center(
// //                   child: Text(
// //                     S.of(context)!.signUp,
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                         color: KTextColor,
// //                         fontSize: 22.sp,
// //                         fontWeight: FontWeight.w500),
// //                   ),
// //                 ),
// //                 SizedBox(height: 5.h),
// //                 Text(
// //                   '${S.of(context)!.userName}*',
// //                   style: TextStyle(
// //                       color: KTextColor,
// //                       fontWeight: FontWeight.w500,
// //                       fontSize: 16.sp),
// //                 ),
// //                 CustomTextField(
// //                   controller: _usernameController,
// //                   hintText: "Ralph Edwards",
// //                   validator: (v) => v!.trim().isEmpty
// //                       ? S.of(context)!.pleaseEnterUsername
// //                       : null,
// //                 ),
// //                 SizedBox(height: 5.h),
// //                 Text(
// //                   '${S.of(context)!.phone}*',
// //                   style: TextStyle(
// //                       color: KTextColor,
// //                       fontWeight: FontWeight.w500,
// //                       fontSize: 16.sp),
// //                 ),
// //                 Stack(
// //                   children: [
// //                     CustomPhoneField(
// //                       controller: _phoneController,
// //                       onCountryChanged: (code) {
// //                         setState(() {
// //                           showEmailField = code != 'AE';
// //                         });
// //                       },
// //                     ),
// //                     IgnorePointer(
// //                       child: TextFormField(
// //                         controller: _phoneController,
// //                         validator: (v) =>
// //                             v!.isEmpty ? S.of(context)!.pleaseEnterPhone : null,
// //                         decoration: const InputDecoration(
// //                             border: InputBorder.none,
// //                             contentPadding: EdgeInsets.zero,
// //                             errorBorder: InputBorder.none),
// //                         readOnly: true,
// //                         style: const TextStyle(
// //                             height: 0, color: Colors.transparent),
// //                         buildCounter: (context,
// //                                 {required currentLength,
// //                                 required isFocused,
// //                                 maxLength}) =>
// //                             null,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 if (showEmailField)
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       SizedBox(height: 5.h),
// //                       Text(
// //                         '${S.of(context)!.email}*',
// //                         style: TextStyle(
// //                             color: KTextColor,
// //                             fontWeight: FontWeight.w500,
// //                             fontSize: 16.sp),
// //                       ),
// //                       CustomTextField(
// //                         controller: _emailController,
// //                         hintText: "admin@dubisale.com",
// //                         keyboardType: TextInputType.emailAddress,
// //                         validator: (value) {
// //                           if (showEmailField &&
// //                               (value == null || !value.contains('@'))) {
// //                             return S.of(context)!.pleaseEnterValidEmail;
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                     ],
// //                   ),
// //                 SizedBox(height: 5.h),
// //                 Text(
// //                   "${S.of(context)!.password}*",
// //                   style: TextStyle(
// //                       color: KTextColor,
// //                       fontWeight: FontWeight.w500,
// //                       fontSize: 16.sp),
// //                 ),
// //                 CustomTextField(
// //                   controller: _passwordController,
// //                   hintText: '1234567',
// //                   isPassword: true,
// //                   validator: (v) =>
// //                       v!.length < 6 ? S.of(context)!.passwordTooShort : null,
// //                 ),
// //                 SizedBox(height: 5.h),
// //                 Text(
// //                   S.of(context)!.referralCode,
// //                   style: TextStyle(
// //                       color: KTextColor,
// //                       fontWeight: FontWeight.w500,
// //                       fontSize: 16.sp),
// //                 ),
// //                 CustomTextField(
// //                     controller: _referralController, hintText: "XXXX"),
// //                 Row(
// //                   children: [
// //                     Checkbox(
// //                       value: isChecked,
// //                       onChanged: (value) => setState(() => isChecked = value!),
// //                       activeColor: const Color.fromRGBO(1, 84, 126, 1),
// //                       checkColor: Colors.white,
// //                     ),
// //                     Expanded(
// //                       child: Text(
// //                         S.of(context)!.agreeTerms,
// //                         style: TextStyle(
// //                             fontSize: 14.sp,
// //                             color: KTextColor,
// //                             fontWeight: FontWeight.w500),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 SizedBox(height: 10.h),
// //                 if (authProvider.isLoading)
// //                   const Center(child: CircularProgressIndicator())
// //                 else
// //                   CustomButton(
// //                       text: S.of(context)!.register, ontap: _submitSignUp),
// //                 SizedBox(height: 4.h),
// //                 Center(
// //                   child: Text(
// //                     S.of(context)!.or,
// //                     style: TextStyle(
// //                         color: KTextColor,
// //                         fontWeight: FontWeight.w500,
// //                         fontSize: 16.sp),
// //                   ),
// //                 ),
// //                 SizedBox(height: 4.h),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Flexible(
// //                       child: CustomElevatedButton(
// //                         onpress: () => context.go('/emailsignup'),
// //                         text: S.of(context)!.emailSignUp,
// //                       ),
// //                     ),
// //                     SizedBox(width: 16.w),
// //                     Flexible(
// //                       child: CustomElevatedButton(
// //                         onpress: () {
// //                          // context.go("/home");
// //                         },
// //                         text: S.of(context)!.guestLogin,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 SizedBox(height: 4.h),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Text(
// //                       S.of(context)!.haveAccount,
// //                       style: TextStyle(color: KTextColor, fontSize: 14.sp),
// //                     ),
// //                     SizedBox(width: 4.w),
// //                     GestureDetector(
// //                       onTap: () => context.go('/login'),
// //                       child: Text(
// //                         S.of(context)!.login,
// //                         style: TextStyle(
// //                           decoration: TextDecoration.underline,
// //                           decorationColor: KTextColor,
// //                           decorationThickness: 1.5,
// //                           color: KTextColor,
// //                           fontWeight: FontWeight.w500,
// //                           fontSize: 14.sp,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 SizedBox(height: 20.h),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
