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

// class EmailSignUpScreen extends StatefulWidget {
//   final LocaleChangeNotifier notifier;

//   const EmailSignUpScreen({
//     super.key,
//     required this.notifier,
//   });

//   @override
//   State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
// }

// class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _referralController = TextEditingController();

//   bool isChecked = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _referralController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _submitSignUp() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (!isChecked) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(S.of(context)!.agreeTermsValidation),
//         backgroundColor: Colors.orangeAccent,
//       ));
//       return;
//     }

//     final authProvider = context.read<AuthProvider>();
//     final placeholderPhone = _emailController.text.hashCode.toString();

//     final success = await authProvider.signUp(
//       username: _nameController.text,
//       email: _emailController.text,
//       password: _passwordController.text,
//       phone: placeholderPhone,
//       role: 'user',
//     );
    
//     if (!mounted) return;
//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(S.of(context)!.accountCreatedSuccessfully),
//         backgroundColor: Colors.green,
//       ));
//       context.go('/home');
//     } else {
//       // --- هنا هو الإصلاح ---
//       // استخدام errorMessage بدلاً من createAdError
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(authProvider.errorMessage ?? S.of(context)!.unknownError),
//         backgroundColor: Colors.red,
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // استخدام isLoading الخاص بـ AuthProvider
//     final authProvider = context.watch<AuthProvider>();
//     final locale = widget.notifier.locale;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(horizontal: 18.w),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 16.h),
//                 Align(
//                   alignment: locale.languageCode == 'ar' ? Alignment.topLeft : Alignment.topRight,
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
//                       locale.languageCode == 'ar' ? S.of(context)!.arabic : S.of(context)!.english,
//                       style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: KTextColor),
//                     ),
//                   ),
//                 ),
//                 Center(child: Image.asset('assets/images/logo.png', fit: BoxFit.contain, height: 98.h, width: 125.w)),
//                 SizedBox(height: 10.h),
//                 Center(
//                   child: Text(
//                     S.of(context)!.signUp,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: KTextColor, fontSize: 24.sp, fontWeight: FontWeight.w500),
//                   ),
//                 ),
//                 SizedBox(height: 7.h),
//                 Text(" ${S.of(context)!.userName}*", style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp)),
//                 CustomTextField(
//                   controller: _nameController,
//                   hintText: "Ralph Edwards",
//                   validator: (v) => v!.trim().isEmpty ? S.of(context)!.pleaseEnterUsername : null,
//                 ),
//                 SizedBox(height: 5.h),
//                 Text("${S.of(context)!.email}*", style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp)),
//                 CustomTextField(
//                   controller: _emailController,
//                   hintText: "Yourname@Example.Com",
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (v) => v == null || !v.contains('@') ? S.of(context)!.pleaseEnterValidEmail : null,
//                 ),
//                 SizedBox(height: 5.h),
//                 Text("${S.of(context)!.password}*", style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp)),
//                 CustomTextField(
//                   controller: _passwordController,
//                   hintText: '1234567',
//                   isPassword: true,
//                   validator: (v) => v!.length < 6 ? S.of(context)!.passwordTooShort : null,
//                 ),
//                 SizedBox(height: 5.h),
//                 Text(S.of(context)!.referralCode, style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp)),
//                 CustomTextField(
//                   controller: _referralController,
//                   hintText: "XXXX",
//                 ),
//                 SizedBox(height: 2.h),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: isChecked,
//                       onChanged: (value) => setState(() { isChecked = value!; }),
//                       activeColor: const Color.fromRGBO(1, 84, 126, 1),
//                       checkColor: Colors.white,
//                     ),
//                     Expanded(
//                       child: Text(
//                         S.of(context)!.agreeTerms,
//                         style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10.h),
//                 // استخدام isLoading الخاص بـ AuthProvider
//                 if (authProvider.isLoading)
//                   const Center(child: CircularProgressIndicator())
//                 else
//                   CustomButton(
//                     text: S.of(context)!.register,
//                     ontap: _submitSignUp,
//                   ),
//                 SizedBox(height: 4.h),
//                 Center(child: Text(S.of(context)!.or, style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp))),
//                 SizedBox(height: 8.h),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Flexible(child: CustomElevatedButton(onpress: () => context.go('/signup'), text: S.of(context)!.phonesignup)),
//                     SizedBox(width: 16.w),
//                     Flexible(child: CustomElevatedButton(onpress: () => context.go("/home"), text: S.of(context)!.guestLogin)),
//                   ],
//                 ),
//                 SizedBox(height: 8.h),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(S.of(context)!.haveAccount, style: TextStyle(color: KTextColor, fontSize: 14.sp)),
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
//                 SizedBox(height: 30.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }