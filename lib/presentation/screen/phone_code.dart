// import 'dart:async';
// import 'package:advertising_app/constant/string.dart';
// import 'package:advertising_app/generated/l10n.dart';
// import 'package:advertising_app/presentation/widget/custom_button.dart';
// import 'package:advertising_app/presentation/providers/auth_repository.dart';
// import 'package:advertising_app/router/local_notifier.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:provider/provider.dart';

// class VerifyPhoneCode extends StatefulWidget {
//   final LocaleChangeNotifier notifier;

//   const VerifyPhoneCode({super.key, required this.notifier});

//   @override
//   State<VerifyPhoneCode> createState() => _VerifyPhoneCodeState();
// }

// class _VerifyPhoneCodeState extends State<VerifyPhoneCode> {
//   String? phoneNumber;
//   String otpCode = "";
//   bool isLoading = false;
  
//   // متغيرات العد التنازلي لزر Resend
//   bool _canResend = true;
//   int _resendCountdown = 0;
//   Timer? _resendTimer;
//   bool _confirmationShown = false;

//   @override
//   void initState() {
//     super.initState();
//     _getUserPhoneNumber();
//     // After first frame, prompt user to confirm number and send WhatsApp code
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _showConfirmPhoneDialog();
//     });
//   }

//   @override
//   void dispose() {
//     _resendTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _getUserPhoneNumber() async {
//     final authProvider = context.read<AuthProvider>();
//     setState(() {
//       phoneNumber = authProvider.user?.phone ?? "+971 5737357344";
//     });
//   }

//   Future<void> _convertToAdvertiser() async {
//     final authProvider = context.read<AuthProvider>();
//     // Show loading while requesting conversion (sends WhatsApp OTP)
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );
//     try {
//       final success = await authProvider.convertToAdvertiser();
//       if (mounted) Navigator.of(context).pop();
//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('WhatsApp activation code has been sent.'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(authProvider.errorMessage ?? 'Failed to send activation code. Please try again.'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) Navigator.of(context).pop();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   void _showConfirmPhoneDialog() {
//     if (_confirmationShown) return;
//     _confirmationShown = true;
//     final number = phoneNumber ?? '';
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Verify Your Number'),
//           content: Text(
//             "We’re about to send a WhatsApp activation code to:\n$number\n\nIs this the correct number, or do you want to change it?",
//             style: TextStyle(color: KTextColor),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // Go back so the user can change the number
//                 if (Navigator.of(context).canPop()) {
//                   Navigator.of(context).pop();
//                 }
//               },
//               child: const Text('Change Number'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _convertToAdvertiser();
//               },
//               child: const Text('Confirm & Send'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: widget.notifier,
//       builder: (context, _) {
//         final locale = widget.notifier.locale;
//         final isArabic = locale.languageCode == 'ar';

//         return Directionality(
//           textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
//           child: Scaffold(
//             backgroundColor: Colors.white,
//             body: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18),
//               child: ListView(
//                 children: [
//                   const SizedBox(height: 20),

//                   /// Back + Language in one row
//                   Row(
//                     children: [
//                       Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       onTap: () => context.pop(),
//                       borderRadius: BorderRadius.circular(8), // لجعل التأثير دائريًا
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.arrow_back_ios, color: KTextColor, size: 16.sp),
//                              Transform.translate(
//                               offset: Offset(-5.w, 0), // قربنا النص من السهم
//                               child: Text(
//                                 S.of(context)!.back,
//                                 style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                       const Spacer(),
//                       GestureDetector(
//                         onTap: () {
//         // --- هذا هو التصحيح ---
//         // 1. نحدد اللغة الجديدة. إذا كانت الحالية 'en'، نغيرها إلى 'ar' والعكس.
//         final currentLocale = widget.notifier.locale;
//         final newLocale = currentLocale.languageCode == 'en'
//             ? const Locale('ar')
//             : const Locale('en');

//         // 2. نستدعي الدالة الصحيحة باللغة الجديدة
//         widget.notifier.changeLocale(newLocale);
//     },
//                         child: Text(
//                           locale.languageCode == 'ar'
//                               ? S.of(context)!.arabic : S.of(context)!.english,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                             color: KTextColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 12),

//                   /// Logo
//                   Center(
//                     child: Image.asset(
//                       'assets/images/logo.png',
//                       height: 98,
//                       width: 125,
//                       fit: BoxFit.contain,
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   /// Title
//                   Text(
//                     S.of(context)!.verifnum,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: KTextColor,
//                       fontSize: 20,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   /// Message
//                   Directionality(
//                     textDirection: TextDirection.ltr,
//                     child: Text(
//                       "We've sent an whatsApp with an activation code to your phone ${phoneNumber ?? 'جاري التحميل...'}",
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: KTextColor,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   /// Code Field
//                   PinCodeTextField(
//                     length: 4,
//                     appContext: context,
//                     textStyle: const TextStyle(color: KTextColor),
//                     onChanged: (value) {
//                       setState(() {
//                         otpCode = value;
//                       });
//                     },
//                     onCompleted: (value) {
//                       setState(() {
//                         otpCode = value;
//                       });
//                     },
//                     pinTheme: PinTheme(
//                       shape: PinCodeFieldShape.box,
//                       borderRadius: BorderRadius.circular(8),
//                       fieldHeight: 70,
//                       fieldWidth: 70,
//                       activeFillColor: Colors.white,
//                       selectedColor: Colors.blue,
//                       activeColor: const Color.fromRGBO(8, 194, 201, 1),
//                       inactiveColor: const Color.fromRGBO(8, 194, 201, 1),
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),

//                   const SizedBox(height: 18),



//                   /// Buttons Row - Verify and Resend
//                   SizedBox(
//                     height: 50,
//                     width: double.infinity,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: _canResend ? KTextColor : Colors.grey.shade300,
//                           width: 1.5,
//                         ),
//                         color: _canResend ? const Color.fromRGBO(1, 84, 126, 1) : Colors.grey.shade100,
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           onTap: _canResend ? _handleResendOTP : null,
//                           borderRadius: BorderRadius.circular(8),
//                           child: Center(
//                             child: Text(
//                               _canResend ? 'Resend' : 'Resend ($_resendCountdown)',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: _canResend ? Colors.white : Colors.grey.shade500,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   SizedBox(
//                     width: double.infinity,
//                     child: CustomButton(
//                       ontap: isLoading ? null : _verifyOTP,
//                       text: isLoading ? S.of(context)!.loading ?? 'جاري التحميل...' : S.of(context)!.verify,
//                     ),
//                   ),
                  
//                   const SizedBox(height: 12),
                    
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   /// دالة التحقق من رمز OTP
//   Future<void> _verifyOTP() async {
//     if (otpCode.length != 4) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('يرجى إدخال رمز التحقق المكون من 4 أرقام'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // التحقق من وجود رقم الهاتف مع معالجة أفضل للحالات الفارغة
//     if (phoneNumber == null || phoneNumber?.trim().isEmpty == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('خطأ في الحصول على رقم الهاتف'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final authProvider = context.read<AuthProvider>();
      
//       // استخدام phoneNumber مع التحقق الآمن
//       final phoneToUse = phoneNumber?.trim() ?? '';
      
//       if (phoneToUse.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('خطأ في الحصول على رقم الهاتف'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
      
//       // استدعاء API للتحقق من رمز OTP
//       final success = await authProvider.verifyOTP(phoneToUse, otpCode);
      
//       if (success) {
//         // إظهار رسالة نجاح خضراء مع الرسالة من الاستجابة
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('OTP verified successfully'),
//               backgroundColor: Colors.green,
//               duration: Duration(seconds: 2),
//             ),
//           );
          
//           // انتظار قصير لإظهار الرسالة ثم الانتقال للصفحة الرئيسية
//           await Future.delayed(const Duration(milliseconds: 1500));
//           if (mounted) {
//             context.go('/home');
//           }
//         }
//       } else {
//         // فحص نوع الخطأ من الـ provider
//         final errorMessage = authProvider.errorMessage ?? 'فشل في التحقق من رمز OTP';
        
//         if (mounted) {
//           // فحص إذا كانت الرسالة تحتوي على "OTP expired"
//           if (errorMessage.toLowerCase().contains('otp expired')) {
//             _showOTPExpiredDialog();
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(errorMessage),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         }
//       }
      
//     } catch (e) {
//       // إظهار رسالة خطأ
//       if (mounted) {
//         final errorString = e.toString();
//         // فحص إذا كان الخطأ يحتوي على "OTP expired"
//         if (errorString.toLowerCase().contains('otp expired')) {
//           _showOTPExpiredDialog();
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('فشل في التحقق: $errorString'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   /// إظهار حوار انتهاء صلاحية OTP مع خيار إعادة الإرسال
//   void _showOTPExpiredDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('انتهت صلاحية الرمز'),
//           content: const Text('OTP expired, reset otp'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('إلغاء'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _resendOTP();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromRGBO(1, 84, 126, 1),
//               ),
//               child: const Text('إعادة إرسال', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   /// دالة إعادة إرسال OTP
//   Future<void> _resendOTP() async {
//     // التحقق من وجود رقم الهاتف مع معالجة أفضل للحالات الفارغة
//     if (phoneNumber == null || phoneNumber?.trim().isEmpty == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('خطأ في الحصول على رقم الهاتف'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
    
//     setState(() {
//       isLoading = true;
//       otpCode = ""; // مسح الرمز السابق
//     });

//     try {
//       final authProvider = context.read<AuthProvider>();
      
//       // استخدام phoneNumber مع التحقق الآمن
//       final phoneToUse = phoneNumber?.trim() ?? '';
      
//       if (phoneToUse.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('خطأ في الحصول على رقم الهاتف'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
      
//       // إعادة تسجيل الدخول لإرسال OTP جديد
//       final success = await authProvider.login(phone: phoneToUse);
      
//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('تم إرسال رمز تحقق جديد'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(authProvider.errorMessage ?? 'فشل في إعادة إرسال الرمز'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('خطأ في إعادة الإرسال: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   /// دالة معالجة زر Resend مع العد التنازلي
//   Future<void> _handleResendOTP() async {
//     if (!_canResend) return;

//     // بدء العد التنازلي
//     setState(() {
//       _canResend = false;
//       _resendCountdown = 60;
//     });

//     // إظهار رسالة تنبيه
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('لا يمكنك إعادة الإرسال لمدة دقيقة واحدة'),
//         backgroundColor: Colors.orange,
//         duration: Duration(seconds: 3),
//       ),
//     );

//     // بدء المؤقت
//     _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _resendCountdown--;
//       });

//       if (_resendCountdown <= 0) {
//         timer.cancel();
//         setState(() {
//           _canResend = true;
//           _resendCountdown = 0;
//         });
//       }
//     });

//     // استدعاء API لإعادة الإرسال
//     await _callResendOTPAPI();
//   }

//   /// استدعاء API لإعادة إرسال OTP
//   Future<void> _callResendOTPAPI() async {
//     if (phoneNumber == null || phoneNumber?.trim().isEmpty == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('خطأ في الحصول على رقم الهاتف'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     try {
//       final authProvider = context.read<AuthProvider>();
//       final phoneToUse = phoneNumber?.trim() ?? '';

//       if (phoneToUse.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('خطأ في الحصول على رقم الهاتف'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }

//       // استدعاء endpoint الجديد لإعادة الإرسال
//       final success = await authProvider.resendOTP(phoneToUse);

//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('تم إرسال رمز تحقق جديد'),
//               backgroundColor: Colors.green,
//             ),
//           );
//           // مسح الرمز السابق
//           setState(() {
//             otpCode = "";
//           });
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(authProvider.errorMessage ?? 'فشل في إعادة إرسال الرمز'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('خطأ في إعادة الإرسال: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
// }