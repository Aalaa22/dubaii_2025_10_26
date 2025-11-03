import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/router/local_notifier.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/presentation/widget/custom_text_field.dart';

class SettingScreen extends StatefulWidget {
  final LocaleChangeNotifier notifier;

  const SettingScreen({super.key, required this.notifier});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isInvisible = true;
  bool _isNotificationsEnabled = true;
  
  // Add properties for advertiser check functionality
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final baseHeight = screenHeight < 700 ? screenHeight : 700;
    final scaleFactor = screenHeight / baseHeight;

    final logoHeight = 110.0 * scaleFactor;
    final logoWidth = logoHeight * 2;
    final tileHeight = 52.0 * scaleFactor;
    final fontSize = 14.0 * scaleFactor;
    final iconSize = 22.0 * scaleFactor;

    return AnimatedBuilder(
      animation: widget.notifier,
      builder: (context, _) {
        final locale = widget.notifier.locale;

        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: CustomBottomNav(currentIndex: 4),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10 * scaleFactor),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: logoHeight,
                    width: logoWidth,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 10 * scaleFactor),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                      _buildTile(
                        context: context,
                        height: tileHeight,
                        fontSize: fontSize,
                        iconSize: iconSize,
                        customLeading: SvgPicture.asset(
                          'assets/icons/profile.svg',
                          width: iconSize,
                          height: iconSize,
                        ),
                        title: S.of(context).myProfile,
                        ontap: () => _checkAdvertiserAndNavigateToProfile(),
                      ),
                      SizedBox(height: 7 * scaleFactor),
                      _buildTile(
                        context: context,
                        height: tileHeight,
                        fontSize: fontSize,
                        iconSize: iconSize,
                        customLeading: SvgPicture.asset(
                          'assets/icons/numder.svg',
                          width: iconSize * 0.6,
                          height: iconSize * 0.6,
                        ),
                        title: S.of(context).createAgentCode,
                      ),
                      SizedBox(height: 7 * scaleFactor),
                      _buildNotificationSwitch(
                          context, screenWidth, tileHeight, fontSize, iconSize),
                      // _buildInvisibleSwitch(
                      //     context, screenWidth, tileHeight, fontSize, iconSize),
                      _buildTile(
                        context: context,
                        height: tileHeight,
                        fontSize: fontSize,
                        iconSize: iconSize,
                        customLeading: SvgPicture.asset(
                          'assets/icons/language.svg',
                          width: iconSize,
                          height: iconSize,
                        ),
                        title: S.of(context).language,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                                locale.languageCode == 'ar'
                                    ? S.of(context).arabic
                                    : S.of(context).english,
                                style: TextStyle(
                                  color: const Color.fromRGBO(8, 194, 201, 1),
                                  fontWeight: FontWeight.w500,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: fontSize + 2,
                              color: KTextColor,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 7 * scaleFactor),
                      _buildTile(
                        context: context,
                        height: tileHeight,
                        fontSize: fontSize,
                        iconSize: iconSize,
                        customLeading: SvgPicture.asset(
                          'assets/icons/terms.svg',
                          width: iconSize,
                          height: iconSize,
                        ),
                        title: S.of(context).termsAndConditions,
                      ),
                      SizedBox(height: 7 * scaleFactor),
                      _buildTile(
                        context: context,
                        height: tileHeight,
                        fontSize: fontSize,
                        iconSize: iconSize,
                        icon: Icons.lock_outline,
                        title: S.of(context).privacySecurity,
                      ),
                      SizedBox(height: 7 * scaleFactor),
                      _buildTile(
                        context: context,
                        height: tileHeight,
                        fontSize: fontSize,
                        iconSize: iconSize,
                        customLeading: SvgPicture.asset(
                          'assets/icons/contact-us.svg',
                          width: iconSize,
                          height: iconSize,
                        ),
                        title: S.of(context).contactUs,
                      ),
                      SizedBox(height: 7 * scaleFactor),
                      Container(
                        height: tileHeight,
                        margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          leading: Icon(
                            Icons.logout,
                            color: Colors.red,
                            size: iconSize,
                          ),
                          title: Text(
                            S.of(context).logout,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: fontSize,
                            ),
                          ),
                          onTap: () async {
                final authProvider = context.read<AuthProvider>();
                final success = await authProvider.logout();

                if (!mounted) return;

                if (success) {
                  // استخدم .go لمسح كل الصفحات السابقة والانتقال إلى شاشة الدخول
                  context.go('/login');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? "Logout failed"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvisibleSwitch(BuildContext context, double screenWidth,
      double height, double fontSize, double iconSize) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      // child: ListTile(
      //   contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),

      //   leading: Icon(
      //     _isInvisible ? Icons.visibility_off : Icons.visibility,
      //     color: const Color.fromRGBO(8, 194, 201, 1),
      //     size: iconSize,
      //   ),
      //   title: Row(
      //     children: [
      //       Text(
      //         S.of(context).invisibleTitle,
      //         style: TextStyle(
      //           color: KTextColor,
      //           fontWeight: FontWeight.w500,
      //           fontSize: fontSize,
      //         ),
      //       ),
      //     ],
      //   ),
      //   trailing: Transform.scale(
      //     scale: 0.8,
      //     child: Switch(
      //       value: _isInvisible,
      //       onChanged: (val) {
      //         setState(() => _isInvisible = val);
      //         _showToast(
      //           context,
      //           val ?  'Invisible Mode Disabled':'Invisible Mode Enabled',
      //         );
      //       },
      //       activeColor: Colors.white,
      //       activeTrackColor: const Color.fromRGBO(8, 194, 201, 1),
      //       inactiveThumbColor: Colors.white,
      //       inactiveTrackColor: Colors.grey[300],
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildNotificationSwitch(
    BuildContext context,
    double screenWidth,
    double height,
    double fontSize,
    double iconSize,
  ) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        leading: Icon(
          _isNotificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off_outlined,
          color: const Color.fromRGBO(8, 194, 201, 1),
          size: iconSize + 4,
        ),
        title: Text(
          S.of(context).notifications,
          style: TextStyle(
            color: KTextColor,
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _isNotificationsEnabled,
            onChanged: (bool value) {
              setState(() => _isNotificationsEnabled = value);
              _showToast(
                context,
                value ? 'Notifications Enabled' : 'Notifications Disabled',
              );
            },
            activeColor: Colors.white,
            activeTrackColor: const Color.fromRGBO(8, 194, 201, 1),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    IconData? icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? ontap,
    Widget? customLeading,
    required double height,
    required double fontSize,
    required double iconSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        leading: customLeading ??
            Icon(
              icon,
              color: const Color.fromRGBO(8, 194, 201, 1),
              size: iconSize,
            ),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xFF001E5B),
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: const Color.fromRGBO(8, 194, 201, 1),
                  fontSize: fontSize,
                ),
              )
            : null,
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: fontSize + 2,
              color: KTextColor,
            ),
        onTap: ontap,
      ),
    );
  }

  // Method to check if user is advertiser and navigate to profile
  Future<void> _checkAdvertiserAndNavigateToProfile() async {
    try {
      final userType = await _storage.read(key: 'user_type');
      print('User type from storage: $userType');
      
      if (userType == 'advertiser') {
        // User is already an advertiser, navigate to profile
        if (mounted) {
          context.push('/editprofile');
        }
      } else {
        // User is not an advertiser, show password dialog
        _showNonAdvertiserDialog();
      }
    } catch (e) {
      print('Error checking user type: $e');
      // On error, show the dialog to be safe
      _showNonAdvertiserDialog();
    }
  }

  // Method to set password and upgrade to advertiser
  Future<void> _setPassword() async {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(S.of(context).please_select_all_fields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).passwordsDoNotMatch),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID from storage
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
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        },
        token: authToken,
      );
      if (response['token'] != null) {
        await _storage.write(key: 'auth_token', value: response['token']);
      }

      // Success - Update user_type in cache to advertiser
      await _storage.write(key: 'user_type', value: 'advertiser');
      // Ensure global auth state reflects the new advertiser role immediately
      await context.read<AuthProvider>().checkStoredSession();
      
      Navigator.of(context).pop(); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(S.of(context).passwordSetSuccessUpgraded),
          backgroundColor: Colors.green,
        ),
      );

      // Clear controllers
      _passwordController.clear();
      _confirmPasswordController.clear();

      // Navigate to profile after successful upgrade
      if (mounted) {
        context.push('/editprofile');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).errorSettingPassword +'${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNonAdvertiserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                S.of(context).searchCountry,
                style: TextStyle(
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
                      S.of(context).setPasswordToUpgradeDescription, style: TextStyle(
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
                      hintText:  S.of(context).enterpassword,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1B365D)),
                    ),
                    const SizedBox(height: 15),
                    
                    // Confirm Password field
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText:  S.of(context).confirmpass,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1B365D)),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        },
                        style: TextButton.styleFrom(
                           backgroundColor: Color.fromRGBO(1, 84, 126, 1),
                        
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            //side: const BorderSide(color: Color(0xFF1B365D)),
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
                            : Text(
                                 S.of(context).setPassword,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
