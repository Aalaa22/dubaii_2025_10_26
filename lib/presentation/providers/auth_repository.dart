import 'dart:io';

import 'package:advertising_app/data/model/user_model.dart';
import 'package:advertising_app/data/repository/auth_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter/material.dart';
// <-- تأكد 100% من وجود هذا الـ import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  // إنشاء نسخة واحدة وثابتة من الـ storage لاستخدامها في كل الدوال
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  
  AuthProvider(this._authRepository);

  // دالة للتحقق من وجود جلسة مخزنة
  Future<bool> checkStoredSession() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      final userType = await _storage.read(key: 'user_type');
      final userPhone = await _storage.read(key: 'user_phone'); // قراءة رقم الهاتف المحفوظ
      final verifyAccountStr = await _storage.read(key: 'verify_account');
      // قراءة بيانات الموقع المحفوظة محلياً (إن وجدت)
      final savedLatStr = await _storage.read(key: 'user_latitude');
      final savedLngStr = await _storage.read(key: 'user_longitude');
      final savedAddress = await _storage.read(key: 'user_address');
      final double? savedLat = savedLatStr != null ? double.tryParse(savedLatStr) : null;
      final double? savedLng = savedLngStr != null ? double.tryParse(savedLngStr) : null;
      
      if (userId != null && userType != null) {
        _userId = int.tryParse(userId);
        _userType = userType;
        _verifyAccount = verifyAccountStr == 'true';
        
        // إنشاء UserModel من البيانات المحفوظة مع رقم الهاتف
        _user = UserModel(
          id: _userId ?? 0,
          username: '', // يمكن إضافة هذه البيانات لاحقاً إذا كانت مطلوبة
          email: '',
          phone: userPhone ?? '', // استخدام رقم الهاتف المحفوظ
          whatsapp: '',
          role: _userType ?? '',
          userType: _userType ?? '',
          // تضمين بيانات الموقع المحفوظة في نموذج المستخدم
          latitude: savedLat,
          longitude: savedLng,
          address: savedAddress,
          advertiserLocation: savedAddress,
        );
        
        print("Stored session found - User ID: $_userId, User Type: $_userType, Phone: $userPhone, Verify Account: $_verifyAccount, Address: $savedAddress, Lat: $savedLat, Lng: $savedLng");
        print("User model created: ${_user?.toJson()}");
        notifyListeners(); // إشعار الواجهة بالتحديث
        return true;
      }
      return false;
    } catch (e) {
      print("Error in checkStoredSession: $e");
      // إذا فشل في قراءة البيانات، نحذف البيانات المعطوبة
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_type');
      await _storage.delete(key: 'user_phone');
      await _storage.delete(key: 'verify_account');
      return false;
    }
  }

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserModel? _user;
  UserModel? get user => _user;

  // إضافة متغيرات جديدة لحفظ user_type و id
  String? _userType;
  int? _userId;
  String? get userType => _userType;
  int? get userId => _userId;

  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  String? _profileError;
  String? get profileError => _profileError;

   bool _isUpdating = false;
  String? _updateError;
  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;

  // إضافة متغير verify_account
  bool? _verifyAccount;
  bool get verifyAccount => _verifyAccount ?? false;

  

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
  }
  
  Future<bool> login({required String phone}) async {
    _setError(null);
    _setLoading(true);
    try {
      print("Starting login with phone: $phone");
      final response = await _authRepository.login(phone: phone);
      print("Login response received: $response");
      // لا نقوم بحفظ أي توكن عند تسجيل الدخول؛ التوكن يُحفظ بعد التحقق من OTP فقط
      
      // استخراج البيانات من الاستجابة الجديدة
      final userData = response['user'];
      if (userData != null) {
        _userId = userData['id'];
        _userType = userData['user_type'];
        _verifyAccount = false; // افتراضياً false عند تسجيل الدخول
        
        print("Extracted user data - ID: $_userId, Type: $_userType");
        
        // حفظ البيانات في secure storage بما في ذلك رقم الهاتف
        await _storage.write(key: 'user_id', value: _userId.toString());
        await _storage.write(key: 'user_type', value: _userType!);
        await _storage.write(key: 'user_phone', value: phone); // حفظ رقم الهاتف
      //  await _storage.write(key: 'verify_account', value: 'false');
        // حفظ موقع المعلن القادم من الـ API إن توفر
        if (userData['advertiser_location'] != null && (userData['advertiser_location'] as String).trim().isNotEmpty) {
          await _storage.write(key: 'user_address', value: (userData['advertiser_location'] as String).trim());
        }
        if (userData['latitude'] != null) {
          await _storage.write(key: 'user_latitude', value: userData['latitude'].toString());
        }
        if (userData['longitude'] != null) {
          await _storage.write(key: 'user_longitude', value: userData['longitude'].toString());
        }
        
        print("Data saved to secure storage including phone: $phone");
        
        // إنشاء UserModel من البيانات المستلمة
        _user = UserModel.fromJson(userData);
        
        print("User logged in successfully!");
        print("User ID: $_userId");
        print("User Type: $_userType");
        print("Verify Account: $_verifyAccount");
        print("User model: ${_user?.toJson()}");
        
        notifyListeners(); // إشعار الواجهة بالتحديث
      }
      
      _setLoading(false);
      return true; 
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // دالة تسجيل الدخول للمعلنين مع كلمة المرور
  Future<bool> loginWithPassword({required String phone, required String password}) async {
    _setError(null);
    _setLoading(true);
    try {
      print("Starting advertiser login with phone: $phone");
      final response = await _authRepository.loginWithPassword(phone: phone, password: password);
      print("Advertiser login response received: $response");
      
      // استخراج البيانات من الاستجابة
      final userData = response['user'];
      final token = response['token']; // استخراج التوكن
      
      if (userData != null && token != null) {
        _userId = userData['id'];
        _userType = userData['user_type'];
        _verifyAccount = true; // المعلنون يكونون محققين بعد تسجيل الدخول بكلمة المرور
        
        print("Extracted advertiser data - ID: $_userId, Type: $_userType, Token: ${token.substring(0, 20)}...");
        
        // حفظ البيانات في secure storage بما في ذلك التوكن
        await _storage.write(key: 'user_id', value: _userId.toString());
        await _storage.write(key: 'user_type', value: _userType!);
        await _storage.write(key: 'user_phone', value: phone);
        await _storage.write(key: 'verify_account', value: 'true');
        await _storage.write(key: 'auth_token', value: token); // حفظ التوكن
        
        // حفظ موقع المعلن القادم من الـ API إن توفر
        if (userData['advertiser_location'] != null && (userData['advertiser_location'] as String).trim().isNotEmpty) {
          await _storage.write(key: 'user_address', value: (userData['advertiser_location'] as String).trim());
        }
        if (userData['latitude'] != null) {
          await _storage.write(key: 'user_latitude', value: userData['latitude'].toString());
        }
        if (userData['longitude'] != null) {
          await _storage.write(key: 'user_longitude', value: userData['longitude'].toString());
        }
        
        print("Advertiser data saved to secure storage including token");
        
        // إنشاء UserModel من البيانات المستلمة
        _user = UserModel.fromJson(userData);
        
        print("Advertiser logged in successfully!");
        print("User ID: $_userId");
        print("User Type: $_userType");
        print("Verify Account: $_verifyAccount");
        print("User model: ${_user?.toJson()}");
        
        notifyListeners(); // إشعار الواجهة بالتحديث
      }
      
      _setLoading(false);
      return true; 
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
   
   
   // دالة signUp - تم إزالتها لأنها لم تعد مطلوبة في النظام الجديد
   // Future<bool> signUp({
   //   required String username,
   //   required String email,
   //   required String password,
   //   required String phone,
   //   required String role,
   // }) async {
   //   _setError(null);
   //   _setLoading(true);
   //   try {
   //     await _authRepository.signUp(
   //       username: username,
   //       email: email,
   //       password: password,
   //       phone: phone,
   //       whatsapp: phone,
   //       role: role,
   //     );
   //     _setLoading(false);
   //     return true;
   //   } catch (e) {
   //     _setError(e.toString());
   //     _setLoading(false);
   //     return false;
   //   }
   // }


  Future<void> _clearSavedLocation() async {
    try {
      await _storage.delete(key: 'user_latitude');
      await _storage.delete(key: 'user_longitude');
      await _storage.delete(key: 'user_address');
      print('Saved location cleared from secure storage.');
    } catch (e) {
      print('Error clearing saved location: $e');
    }
  }

 Future<bool> logout() async {
    _setError(null);
    _setLoading(true);
    
    await _clearSavedLocation();
    try {
      // حذف البيانات المحفوظة محلياً
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_type');
      await _storage.delete(key: 'verify_account');
      await _storage.delete(key: 'auth_token'); // حذف التوكن من التحقق
      await _storage.delete(key: 'login_token'); // حذف التوكن من تسجيل الدخول
      
      // مسح البيانات من المتغيرات
      _userId = null;
      _userType = null;
      _user = null;
      _verifyAccount = null;
      
      print("User logged out successfully!");
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      
      // كإجراء احترازي، قم بحذف البيانات المحلية حتى لو فشل شيء ما
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_type');
      await _storage.delete(key: 'verify_account');
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'login_token');
      _userId = null;
      _userType = null;
      _user = null;
      _verifyAccount = null;
      
      return false;
    }
  }

  Future<void> fetchUserProfile() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();
    try {
      // تمرير auth_token لضمان المصادقة وتجنب 401
      final authToken = await _storage.read(key: 'auth_token');
      final userProfile = await _authRepository.getUserProfile(token: authToken);
      _user = userProfile;

    } catch (e) {
      _profileError = e.toString();
      print("Error fetching profile: $e");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }


  Future<bool> updateUserProfile({
    required String username, required String email, required String phone,
    String? whatsapp, String? advertiserName, String? advertiserType,
    String? referralCode, File? advertiserLogoFile,
    double? latitude, double? longitude, String? address, String? advertiserLocation,
  }) async {
    _isUpdating = true; 
    _updateError = null;
    notifyListeners();
    try {
      // الاعتماد حصراً على auth_token كما طلبتِ
      final authToken = await _storage.read(key: 'auth_token');

      if (authToken == null) {
        _updateError = 'Not authenticated. Missing auth_token.';
        throw Exception('Not authenticated.');
      }

      print("Using auth_token for profile update: ${authToken.substring(0, 20)}...");
      final updatedUser = await _authRepository.updateProfile(
        token: authToken,
        username: username,
        email: email,
        phone: phone,
        whatsapp: whatsapp,
        advertiserName: advertiserName,
        advertiserType: advertiserType,
        advertiserLogoFile: advertiserLogoFile,
        referralCode: referralCode,
        latitude: latitude,
        longitude: longitude,
        address: address,
        advertiserLocation: advertiserLocation,
      );
      _user = updatedUser;
      
      // Refresh user profile from server to ensure we have latest data
      await fetchUserProfile();
      
      return true;
    } catch (e) {
      _updateError = e.toString();
      return false;
    } finally {
      _isUpdating = false; notifyListeners();
    }
  }

  Future<bool> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    try {
       // الاعتماد حصراً على auth_token
       final authToken = await _storage.read(key: 'auth_token');
       if (authToken == null) throw Exception('Not authenticated.');
       
       await _authRepository.updatePassword(token: authToken, currentPassword: currentPassword, newPassword: newPassword);
       return true;
    } catch(e) {
      _updateError = e.toString();
      return false;
    } finally {
       _isUpdating = false; notifyListeners();
    }
  }

  Future<bool> uploadLogo(String logoPath) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    try {
      // Validate supported image extensions before calling API
      final String ext = logoPath.split('.').last.toLowerCase();
      const allowed = ['jpg', 'jpeg', 'png', 'gif'];
      if (!allowed.contains(ext)) {
        _updateError = 'صيغة الصورة غير مدعومة. الرجاء اختيار JPG/PNG/GIF.';
        return false;
      }
      // الاعتماد حصراً على auth_token
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) throw Exception('Not authenticated.');
      
      final updatedUser = await _authRepository.uploadLogo(
        token: authToken,
        logoPath: logoPath,
      );
      
      _user = updatedUser;
      return true;
    } catch (e) {
      _updateError = e.toString();
      final msg = _updateError?.toLowerCase() ?? '';
      if (msg.contains('validation_error') && msg.contains('advertiser_logo')) {
        _updateError = 'صيغة الصورة غير مدعومة. الرجاء اختيار JPG/PNG/GIF.';
      }
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLogo() async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    try {
      // الاعتماد حصراً على auth_token
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) throw Exception('Not authenticated.');
      
      final updatedUser = await _authRepository.deleteLogo(token: authToken);
      _user = updatedUser;
      return true;
    } catch (e) {
      _updateError = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // دالة لتحديث حالة verify_account
  // Future<void> setVerifyAccount(bool value) async {
  //   _verifyAccount = value;
  //   await _storage.write(key: 'verify_account', value: value.toString());
  //   notifyListeners();
  // }

  // // Convert user to advertiser
  // Future<bool> convertToAdvertiser() async {
  //   try {
  //     print('🔄 convertToAdvertiser: Starting conversion process...');
  //     _setLoading(true);
  //     _setError(null);

  //     // Get current user ID
  //     if (_user == null) {
  //       print('❌ convertToAdvertiser: No user data available');
  //       throw Exception('User data not available');
  //     }
      
  //     final userId = _user!.id;
  //     print('👤 convertToAdvertiser: User ID = $userId');
      
  //     final endpoint = '/api/convert-to-advertiser/$userId';
  //     print('🌐 convertToAdvertiser: Making POST request to: $endpoint');

  //     final response = await _apiService.post(
  //       endpoint,
  //       data: {},
  //     );

  //     print('✅ convertToAdvertiser: API call successful');
  //     print('📄 convertToAdvertiser: Response = $response');
      
  //     _setLoading(false);
  //     return true;
  //   } catch (e) {
  //     print('❌ convertToAdvertiser: Error occurred = $e');
  //     _setError(e.toString());
  //     _setLoading(false);
  //     return false;
  //   }
  // }

  // // Verify OTP
  // Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
  //   try {
  //     _setLoading(true);
  //     _setError(null);

  //     final response = await _apiService.put('/api/verify', data: {
  //       'phone': phoneNumber,
  //       'otp': otpCode,
  //     });

  //     if (response['access_token'] != null) {
  //       // حفظ التوكن
  //       await _storage.write(key: 'auth_token', value: response['access_token']);

  //       // استخراج بيانات المستخدم من الاستجابة (داخل المفتاح 'user')
  //       final Map<String, dynamic>? userData =
  //           response['user'] is Map<String, dynamic> ? response['user'] as Map<String, dynamic> : null;

  //       // قراءة القيم بأمان
  //       final int? idFromResponse = userData != null
  //           ? (userData['id'] is int
  //               ? userData['id'] as int
  //               : int.tryParse(userData['id']?.toString() ?? ''))
  //           : null;
  //       final String userTypeFromResponse = (userData?['user_type'] ?? userData?['role'] ?? '')
  //           .toString();

  //       // كتابة القيم في التخزين الآمن
  //       await _storage.write(key: 'user_id', value: (idFromResponse?.toString() ?? ''));
  //       await _storage.write(key: 'user_type', value: userTypeFromResponse);
  //       await _storage.write(key: 'user_phone', value: phoneNumber); // حفظ رقم الهاتف المستخدم في التحقق
  //       await _storage.write(key: 'verify_account', value: 'true'); // تحديث حالة التحقق

  //       // تحديث حالة AuthProvider مباشرة
  //       _userId = idFromResponse;
  //       _userType = userTypeFromResponse;
  //       _verifyAccount = true;

  //       // إنشاء UserModel محدث بدون فرض ! على قيم قد تكون فارغة
  //       _user = UserModel(
  //         id: _userId ?? 0,
  //         username: (userData?['username'] ?? '').toString(),
  //         email: (userData?['email'] ?? '').toString(),
  //         phone: (userData?['phone'] ?? phoneNumber).toString(),
  //         whatsapp: (userData?['whatsapp'] ?? '').toString(),
  //         role: (userData?['role'] ?? _userType ?? '').toString(),
  //         userType: (_userType ?? '').toString(),
  //       );

  //       print("OTP verified successfully - User ID: $_userId, User Type: $_userType, Phone: $phoneNumber");
  //       print("Updated user model: ${_user?.toJson()}");
  //       notifyListeners(); // إشعار الواجهة بالتحديث
  //     }

  //     _setLoading(false);
  //     return true;
  //   } catch (e) {
  //     _setError(e.toString());
  //     _setLoading(false);
  //     return false;
  //   }
  // }

  // /// دالة إعادة إرسال OTP باستخدام endpoint منفصل
  // Future<bool> resendOTP(String phoneNumber) async {
  //   try {
  //     _setLoading(true);
  //     _setError(null);

  //     print("🔄 resendOTP: Starting resend OTP for phone: $phoneNumber");

  //     // استدعاء API لإعادة إرسال OTP
  //     final response = await _apiService.post(
  //       '/api/resend-otp',
  //       data: {
  //         'phone': phoneNumber,
  //       },
  //     );

  //     print("✅ resendOTP: API call successful");
  //     print("📄 resendOTP: Response = $response");

  //     // التحقق من نجاح العملية بناءً على وجود الاستجابة
  //     if (response != null) {
  //       print("✅ resendOTP: OTP resent successfully for phone: $phoneNumber");
  //       _setLoading(false);
  //       return true;
  //     } else {
  //       final errorMessage = 'فشل في إعادة إرسال الرمز';
  //       print("❌ resendOTP: Failed - $errorMessage");
  //       _setError(errorMessage);
  //       _setLoading(false);
  //       return false;
  //     }
  //   } catch (e) {
  //     print("❌ resendOTP: Error occurred = $e");
  //     _setError(e.toString());
  //     _setLoading(false);
  //     return false;
  //   }
  // }



}
