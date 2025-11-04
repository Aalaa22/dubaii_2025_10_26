import 'dart:ui';

import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/screen/all_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/presentation/widget/custom_text_field.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/core/scaffold_messenger_key.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;

  const CustomBottomNav({required this.currentIndex});

  @override
  _CustomBottomNavState createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  int? _pendingNavIndex;

  void _showTopMessage(String message, {Color backgroundColor = Colors.red, Duration duration = const Duration(seconds: 2)}) {
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) {
      // Fallback to global scaffold messenger
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final locale = Localizations.localeOf(context).languageCode;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SafeArea(
        child: Directionality(
          textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8.r),
                color: backgroundColor,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        backgroundColor == Colors.red ? Icons.error_outline : Icons.check_circle,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          message,
                          style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration, () {
      entry.remove();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    // Validate passwords
    if (_passwordController.text.trim().isEmpty) {
      _showTopMessage(S.of(context).pleaseEnterPassword, backgroundColor: Colors.red);
      return;
    }

    if (_confirmPasswordController.text.trim().isEmpty) {
      _showTopMessage(S.of(context).pleaseConfirmPassword, backgroundColor: Colors.red);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showTopMessage(S.of(context).passwordsDoNotMatch, backgroundColor: Colors.red);
      return;
    }

    // Password strength validation
    final password = _passwordController.text;
    if (password.length < 8) {
      _showTopMessage(S.of(context).passwordTooShort, backgroundColor: Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get userId from storage
      final userIdStr = await _storage.read(key: 'user_id');
      if (userIdStr == null) {
        throw Exception('User ID not found');
      }

      final userId = int.parse(userIdStr);

      // Get auth token
      final authToken = await _storage.read(key: 'auth_token');

      // Make API call
      final response = await _apiService.post(
        '/api/set-password',
        data: {
          'userId': userId,
          'password': password,
          'password_confirmation': _confirmPasswordController.text,
        },
        token: authToken,
      );

      // Success - Update user_type in cache to advertiser
      await _storage.write(key: 'user_type', value: 'advertiser');
      
      // حفظ التوكن الجديد إذا كان موجوداً في الاستجابة
      if (response['token'] != null) {
        await _storage.write(key: 'auth_token', value: response['token']);
      }
      
      Navigator.of(context).pop(); // Close dialog
      _showTopMessage(S.of(context).passwordSetSuccessUpgraded, backgroundColor: Colors.green, duration: const Duration(seconds: 3));

      // تحديث حالة AuthProvider من التخزين لضمان قراءة userType الجديد فوراً
      await context.read<AuthProvider>().checkStoredSession();

      // فتح الصفحة المقصودة مباشرة إذا كانت مُحددة
      if (_pendingNavIndex == 2) {
        context.push('/postad');
      } else if (_pendingNavIndex == 3) {
        context.push('/manage');
      }
      _pendingNavIndex = null;

      // Clear controllers
      _passwordController.clear();
      _confirmPasswordController.clear();

    } catch (e) {
      _showTopMessage('${S.of(context).errorSettingPassword}: ${e.toString()}', backgroundColor: Colors.red, duration: const Duration(seconds: 3));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
 void _showNonAdvertiserDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final locale = Localizations.localeOf(context).languageCode;
        return Directionality(
          textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                S.of(context).secureYourAccount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B365D),
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.of(context).setPasswordToUpgradeDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Password field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: S.of(context).enterpassword,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return S.of(context).passwordRequiredToCompleteLogin;
                      }
                      if (value.length < 8) {
                        return S.of(context).passwordTooShort;
                      }
                      return null;
                    },
                  ),
                    const SizedBox(height: 15),
                    
                    // Confirm password field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: S.of(context).confirmpass,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return S.of(context).pleaseConfirmPassword;
                      }
                      if (value != _passwordController.text) {
                        return S.of(context).passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.of(context).pop();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color.fromRGBO(1, 84, 126, 1),
                         
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            
                           // side: const BorderSide(color: Color(0xFF1B365D)),
                          ),
                        ),
                        child:  Text(
                          S.of(context).cancel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _setPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(1, 84, 126, 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            :  Text(
                                S.of(context).setPassword, 
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        );
      },
    );
  }

 
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor:Colors.white, 
      currentIndex: widget.currentIndex,
      showUnselectedLabels: true, 
      selectedItemColor: Color(0xFF01547E),
      unselectedItemColor:Color.fromRGBO( 5, 194, 201,1),
      onTap: (index) async {
        switch (index) {
          case 0:
            context.push('/home');
            break;
          case 1:
            context.push('/favorite');
            break;
          case 2: {
            final auth = context.read<AuthProvider>();
            String? userType = auth.userType?.toLowerCase();

            // Fallback to secure storage in case provider state is stale
            if (userType != 'advertiser') {
              final storedUserType = await _storage.read(key: 'user_type');
              if ((storedUserType ?? '').toLowerCase() == 'advertiser') {
                await auth.checkStoredSession();
                userType = 'advertiser';
              }
            }

            if (userType == 'advertiser') {
              context.push('/postad');
            } else {
              _pendingNavIndex = 2;
              _showNonAdvertiserDialog();
            }
            break;
          }
          case 3: {
            final auth = context.read<AuthProvider>();
            String? userType = auth.userType?.toLowerCase();

            // Fallback to secure storage in case provider state is stale
            if (userType != 'advertiser') {
              final storedUserType = await _storage.read(key: 'user_type');
              if ((storedUserType ?? '').toLowerCase() == 'advertiser') {
                await auth.checkStoredSession();
                userType = 'advertiser';
              }
            }

            if (userType == 'advertiser') {
              context.push('/manage');
            } else {
              _pendingNavIndex = 3;
              _showNonAdvertiserDialog();
            }
            break;
          }
           

          case 4:
            context.push('/setting');
            break;
        }
      },
       items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            "assets/icons/home.svg",
               width: 26.w,
              height: 26,
              color: widget.currentIndex == 0
        ? const Color(0xFF01547E) // لون المختار
        : const Color.fromRGBO(5, 194, 201, 1), // لون غير المختار
  
                 ),
        label:S.of(context).home,
        ),
         BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.heart),
          label:S.of(context).favorites,
        ),

       
        BottomNavigationBarItem(
          icon: Center(
            child: Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                 gradient: LinearGradient(
            colors: [
              const Color(0xFFC9F8FE),
              const Color(0xFF08C2C9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
                    ),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.plus,
                  color: Colors.red, // لون الزائد
                  size: 18,
                ),
              ),
            ),
          ),
          label: S.of(context).post,
        ),

         BottomNavigationBarItem(
          icon: SvgPicture.asset(
            "assets/icons/folder_edit_icon.svg",
               width: 26,
              height: 26,
              color: widget.currentIndex == 3
        ? const Color(0xFF01547E)
        : const Color.fromRGBO(5, 194, 201, 1),
  
                 ),
                 label:S.of(context).manage,
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.gear),
          label:S.of(context).srtting,
        ),
      ],
    );
  }
}
