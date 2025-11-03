import 'dart:io';
import 'package:advertising_app/data/model/user_model.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_phone_field.dart';
import 'package:advertising_app/presentation/widget/custom_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _advertiserNameController = TextEditingController();
  String? _selectedAdvertiserType;
  final List<String> advertiserTypes = [
    'Dealer / Showroom', 'Personal Owner', 'Real Estate Agent', 'Recruiter'
  ];
  
  File? _logoImageFile;
  final ImagePicker _picker = ImagePicker();

  // Location-related state variables
   LatLng? _userLocation;
  String? _userAddress;
  bool _isLoadingLocation = false;
  
  // FlutterSecureStorage instance for saving location data
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // جلب البيانات وملء الحقول فور فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfileData();
      _loadLocationData();
       final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) {
        authProvider.fetchUserProfile();
      }
      // Load saved location data when the screen initializes
      _loadSavedLocation();
    });
    
  }

  Future<void> _saveLocationToStorage() async {
    if (_userLocation != null && _userAddress != null) {
      try {
        await _storage.write(key: 'user_latitude', value: _userLocation!.latitude.toString());
        await _storage.write(key: 'user_longitude', value: _userLocation!.longitude.toString());
        await _storage.write(key: 'user_address', value: _userAddress!);
        print('Location saved to secure storage successfully');
      } catch (e) {
        print('Error saving location to storage: $e');
      }
    }
  }

  // Load location data from FlutterSecureStorage
  Future<void> _loadSavedLocation() async {
    try {
      final latitude = await _storage.read(key: 'user_latitude');
      final longitude = await _storage.read(key: 'user_longitude');
      final address = await _storage.read(key: 'user_address');
      
      if (latitude != null && longitude != null && address != null) {
        setState(() {
          _userLocation = LatLng(double.parse(latitude), double.parse(longitude));
          _userAddress = address;
        });
        print('Location loaded from secure storage: $address');
      }
    } catch (e) {
      print('Error loading location from storage: $e');
    }
  }

  // Initialize user location automatically
  Future<void> _initializeUserLocation() async {
    if (_userLocation != null) return; // Already initialized
    
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();
      
      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        final address = await mapsProvider.getAddressFromCoordinates(
          locationData.latitude!, 
          locationData.longitude!
        );
        
        setState(() {
          _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
          _userAddress = address ?? 'Unknown location';
        });
      }
    } catch (e) {
      print('Error initializing location: $e');
      // Set default Dubai location if current location fails
      setState(() {
        _userLocation = const LatLng(25.2048, 55.2708);
        _userAddress = 'Dubai, UAE';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }


 
 Future<void> _saveLocationData() async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تحديد الموقع أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('جاري حفظ الموقع...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
    
    final success = await authProvider.updateUserProfile(
      username: user.username,
      email: user.email,
      phone: user.phone,
      whatsapp: user.whatsapp,
      advertiserName: user.advertiserName,
      advertiserType: user.advertiserType,
      latitude: _userLocation!.latitude,
      longitude: _userLocation!.longitude,
      address: _userAddress,
      advertiserLocation: _userAddress, // إرسال الموقع كـ advertiser_location
    );
    
    // Hide loading and show result
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم حفظ الموقع بنجاح!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Force refresh the UI to show updated location
      setState(() {});
    } else {
      String errorMessage = 'فشل في حفظ الموقع';
      if (authProvider.updateError != null) {
        if (authProvider.updateError!.contains('500')) {
          errorMessage = 'خطأ في الخادم، الرجاء المحاولة لاحقاً';
        } else if (authProvider.updateError!.contains('network')) {
          errorMessage = 'تحقق من اتصال الإنترنت';
        } else {
          errorMessage = 'حدث خطأ، الرجاء المحاولة مرة أخرى';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: () => _saveLocationData(),
          ),
        ),
      );
    }
  }

  // Show location help dialog
  void _showLocationHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('كيفية تفعيل خدمة الموقع'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'لتفعيل خدمة الموقع في المتصفح:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildHelpStep('Chrome:', '1. اضغط على أيقونة القفل 🔒 أو الموقع 📍 بجانب العنوان\n2. اختر "السماح" أو "Allow" للموقع\n3. أعد تحميل الصفحة'),
                const SizedBox(height: 8),
                _buildHelpStep('Firefox:', '1. اضغط على أيقونة الدرع أو القفل\n2. اختر "إيقاف الحماية" أو "Allow Location"\n3. أعد تحميل الصفحة'),
                const SizedBox(height: 8),
                _buildHelpStep('Safari:', '1. اذهب إلى Safari > Preferences > Websites\n2. اختر Location من القائمة\n3. اختر "Allow" للموقع'),
                const SizedBox(height: 8),
                _buildHelpStep('Edge:', '1. اضغط على أيقونة القفل بجانب العنوان\n2. اختر "السماح" للموقع\n3. أعد تحميل الصفحة'),
                const SizedBox(height: 12),
                const Text(
                  'إذا لم تنجح الطرق السابقة:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• تأكد من تفعيل خدمة الموقع في إعدادات الجهاز\n• أعد تشغيل المتصفح\n• جرب متصفح آخر\n• تأكد من اتصالك بالإنترنت',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('فهمت'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocation();
              },
              child: const Text('جرب الآن'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpStep(String browser, String steps) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            browser,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            steps,
            style: const TextStyle(fontSize: 13,color:KTextColor),
          ),
        ],
      ),
    );
  }

  // Get current location method
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();

      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        
        // Convert coordinates to address
        final address = await mapsProvider.getAddressFromCoordinates(
            locationData.latitude!, locationData.longitude!);
        
        setState(() {
          _userLocation = LatLng(
              locationData.latitude!, locationData.longitude!);
          _userAddress = address ?? 'موقع غير معروف';
        });

        // Move camera to current location
        await mapsProvider.moveCameraToLocation(
            locationData.latitude!, locationData.longitude!,
            zoom: 16.0);

        // Save location data
        await _saveLocationData();
        await _saveLocationToStorage();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديت الموقع بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحديد الموقع'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديد الموقع: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Open Google Maps method
  Future<void> _openGoogleMaps() async {
    try {
      // Get current location if available, otherwise use Dubai coordinates
      double lat = _userLocation?.latitude ?? 25.2048;
      double lng = _userLocation?.longitude ?? 55.2708;
      
      // Save current location data before opening maps
      if (_userLocation != null && _userAddress != null) {
        await _saveLocationData();
        await _saveLocationToStorage();
      }
      
      // Create Google Maps URL with better parameters
      final String googleMapsUrl = 'https://www.google.com/maps/place/$lat,$lng/@$lat,$lng,15z';
      final Uri url = Uri.parse(googleMapsUrl);
      
      // Try to launch Google Maps
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح خرائط جوجل وحفظ الموقع'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Fallback to web version
        final String webUrl = 'https://maps.google.com/?q=$lat,$lng&z=15';
        final Uri webUri = Uri.parse(webUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح خرائط جوجل (نسخة الويب) وحفظ الموقع'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في فتح خرائط جوجل: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Navigate to location picker screen
  Future<void> _navigateToLocationPicker() async {
    try {
      // Prepare initial location and address for the picker
      double? initialLat = _userLocation?.latitude;
      double? initialLng = _userLocation?.longitude;
      String? initialAddress = _userAddress;
      
      // Build the route with query parameters
      String route = '/location_picker';
      if (initialLat != null && initialLng != null) {
        route += '?lat=$initialLat&lng=$initialLng';
        if (initialAddress != null && initialAddress.isNotEmpty) {
          route += '&address=${Uri.encodeComponent(initialAddress)}';
        }
      }
      
      // Navigate to location picker and wait for result
      final result = await context.push(route);
      
      // Handle the returned location data
      if (result != null && result is Map<String, dynamic>) {
        final LatLng? location = result['location'] as LatLng?;
        final String? address = result['address'] as String?;
        
        if (location != null) {
          setState(() {
            _userLocation = location;
            if (address != null && address.isNotEmpty) {
              _userAddress = address;
            }
          });
          
          // Save the new location data to database and secure storage
          await _saveLocationData();
          await _saveLocationToStorage();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الموقع بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الموقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 







  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تجنّب إعادة ملء الحقول تلقائياً أثناء التحرير لمنع مسح النص
  }

  void _refreshProfileData() {
    final authProvider = context.read<AuthProvider>();
    authProvider.fetchUserProfile().then((_) {
      if (mounted && authProvider.user != null) {
        _updateTextFields(authProvider.user!);
      }
    });
  }

  void _updateTextFields(UserModel user) {
    if (_userNameController.text.isEmpty) {
      _userNameController.text = user.username ?? '';
    }
    if (_phoneController.text.isEmpty) {
      _phoneController.text = user.phone ?? '';
    }
    if (_whatsAppController.text.isEmpty) {
      _whatsAppController.text = user.whatsapp ?? '';
    }
    if (_emailController.text.isEmpty) {
      _emailController.text = user.email ?? '';
    }
    if (_advertiserNameController.text.isEmpty) {
      _advertiserNameController.text = user.advertiserName ?? '';
    }
    setState(() {
      _selectedAdvertiserType = user.advertiserType;
    });
  }

  // Location-related methods
  Future<void> _loadLocationData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user != null && user.latitude != null && user.longitude != null) {
      setState(() {
        _userLocation = LatLng(user.latitude!, user.longitude!);
        _userAddress = user.address ?? user.advertiserLocation ?? 'موقع غير معروف';
      });
    }
  }

  // Future<void> _getCurrentLocation() async {
  //   setState(() {
  //     _isLoadingLocation = true;
  //   });
    
  //   try {
  //     final mapsProvider = context.read<GoogleMapsProvider>();
  //     await mapsProvider.getCurrentLocation();

  //     if (mapsProvider.currentLocationData != null) {
  //       final locationData = mapsProvider.currentLocationData!;
        
  //       // Convert coordinates to address
  //       final address = await mapsProvider.getAddressFromCoordinates(
  //           locationData.latitude!, locationData.longitude!);
        
  //       setState(() {
  //         _userLocation = LatLng(
  //             locationData.latitude!, locationData.longitude!);
  //         _userAddress = address ?? 'موقع غير معروف';
  //       });

  //       // Move camera to current location
  //       await mapsProvider.moveCameraToLocation(
  //           locationData.latitude!, locationData.longitude!,
  //           zoom: 16.0);

  //       // Save location data
  //       await _saveLocationData();

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('تم تحديد الموقع بنجاح!'),
  //           backgroundColor: Colors.green,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('فشل في تحديد الموقع'),
  //           backgroundColor: Colors.red,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('خطأ في تحديد الموقع: ${e.toString()}'),
  //         backgroundColor: Colors.red,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   } finally {
  //     setState(() {
  //       _isLoadingLocation = false;
  //     });
  //   }
  // }

  // Future<void> _saveLocationData() async {
  //   if (_userLocation == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('الرجاء تحديد الموقع أولاً'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }
    
  //   final authProvider = context.read<AuthProvider>();
  //   final user = authProvider.user;
    
  //   if (user == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('الرجاء تسجيل الدخول أولاً'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }
    
  //   final success = await authProvider.updateUserProfile(
  //     username: user.username,
  //     email: user.email,
  //     phone: user.phone,
  //     whatsapp: user.whatsapp,
  //     advertiserName: user.advertiserName,
  //     advertiserType: user.advertiserType,
  //     latitude: _userLocation!.latitude,
  //     longitude: _userLocation!.longitude,
  //     address: _userAddress,
  //     advertiserLocation: _userAddress,
  //   );
    
  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Row(
  //           children: [
  //             Icon(Icons.check_circle, color: Colors.white),
  //             SizedBox(width: 8),
  //             Text('تم حفظ الموقع بنجاح!'),
  //           ],
  //         ),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
      
  //     setState(() {});
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(authProvider.updateError ?? 'فشل في حفظ الموقع'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // Future<void> _navigateToLocationPicker() async {
  //   final result = await context.push('/location-picker');
  //   if (result != null && result is Map<String, dynamic>) {
  //     setState(() {
  //       _userLocation = LatLng(result['latitude'], result['longitude']);
  //       _userAddress = result['address'] ?? 'موقع غير معروف';
  //     });
  //     await _saveLocationData();
  //   }
  // }


  

  // Helper method to extract phone number without country code
  String _extractPhoneNumber(String? fullPhone) {
    if (fullPhone == null || fullPhone.trim().isEmpty) {
      return '';
    }
    
    try {
      // Remove common prefixes like +, 00, and country codes
      String cleaned = fullPhone.trim().replaceAll(RegExp(r'^\+|^00'), '');
      
      // Extract country code from the full phone number
      String countryCode = _extractCountryCode(fullPhone);
      
      // Remove the detected country code if present
      if (countryCode.isNotEmpty) {
        cleaned = cleaned.replaceFirst(RegExp('^$countryCode'), '');
      }
      
      // Remove leading zero if present after country code removal
      cleaned = cleaned.replaceFirst(RegExp(r'^0'), '');
      
      // Return the cleaned number
      return cleaned;
    } catch (e) {
      return fullPhone.trim();
    }
  }

  // Method to extract country code from full phone number
  String _extractCountryCode(String? fullPhone) {
    if (fullPhone == null || fullPhone.trim().isEmpty) {
      return '971'; // Default to UAE
    }
    
    try {
      // Remove + and 00 prefixes
      String cleaned = fullPhone.trim().replaceAll(RegExp(r'^\+|^00'), '');
      
      // Common country codes mapping based on phone number patterns
      Map<String, String> countryCodePatterns = {
        '971': r'^971[1-9]', // UAE
        '966': r'^966[1-9]', // Saudi Arabia
        '965': r'^965[1-9]', // Kuwait
        '974': r'^974[1-9]', // Qatar
        '973': r'^973[1-9]', // Bahrain
        '968': r'^968[1-9]', // Oman
        '20': r'^20[1-9]',   // Egypt
        '962': r'^962[1-9]', // Jordan
        '961': r'^961[1-9]', // Lebanon
        '963': r'^963[1-9]', // Syria
        '964': r'^964[1-9]', // Iraq
        '212': r'^212[1-9]', // Morocco
        '213': r'^213[1-9]', // Algeria
        '216': r'^216[1-9]', // Tunisia
        '218': r'^218[1-9]', // Libya
      };
      
      // Find matching country code
      for (var entry in countryCodePatterns.entries) {
        if (RegExp(entry.value).hasMatch(cleaned)) {
          return entry.key;
        }
      }
      
      // Default to UAE if no match found
      return '971';
    } catch (e) {
      return '971'; // Default to UAE
    }
  }

  // Method to format phone number with country code based on detected country
  String _formatPhoneNumber(String? number, {String? defaultCountryCode}) {
    if (number == null || number.trim().isEmpty) {
      return '';
    }
    
    try {
      // Remove all non-digit characters
      String cleaned = number.trim().replaceAll(RegExp(r'[^0-9]'), '');
      
      // Remove leading zero if present
      cleaned = cleaned.replaceFirst(RegExp(r'^0'), '');
      
      // Use detected country code or provided default
      String countryCode = defaultCountryCode ?? _extractCountryCode(number);
      
      // Add country code if not already present
      if (cleaned.isNotEmpty && !cleaned.startsWith(countryCode)) {
        cleaned = '$countryCode$cleaned';
      }
      
      // Return formatted with + sign
      return cleaned.isNotEmpty ? '+$cleaned' : '';
    } catch (e) {
      return number.trim();
    }
  }
  
  @override
  void dispose() {
    _userNameController.dispose(); _phoneController.dispose(); _whatsAppController.dispose();
    _newPasswordController.dispose(); _currentPasswordController.dispose(); _emailController.dispose();
    _advertiserNameController.dispose();
    super.dispose();
  }

  // دالة الحفظ المحدثة (بدون validation)
  Future<void> _saveProfile() async {
    final provider = context.read<AuthProvider>();
    
    // Validate required fields
    if (_userNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required'), backgroundColor: Colors.red)
      );
      return;
    }
    
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required'), backgroundColor: Colors.red)
      );
      return;
    }
    
    // لم نعد نطلب البريد الإلكتروني في هذه الصفحة
    
    // Format phone numbers with country codes before sending
    // Use the country code from existing user data if available
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    String existingCountryCode = user?.phone != null && user!.phone!.isNotEmpty 
        ? _extractCountryCode(user.phone) 
        : '971';
    
    String formattedPhone = _formatPhoneNumber(_phoneController.text, defaultCountryCode: existingCountryCode);
    String formattedWhatsApp = _formatPhoneNumber(_whatsAppController.text, defaultCountryCode: existingCountryCode);
    
    // Ensure phone numbers are properly formatted
    if (formattedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number format'), backgroundColor: Colors.red)
      );
      return;
    }
    
    // تحديث البروفايل بالبيانات الحالية في الـ controllers (including location data)
    bool profileSuccess = await provider.updateUserProfile(
      username: _userNameController.text.trim(),
      email: (user?.email ?? '').trim(),
      phone: formattedPhone,
      whatsapp: formattedWhatsApp.isNotEmpty ? formattedWhatsApp : null,
      advertiserName: _advertiserNameController.text.trim().isNotEmpty ? _advertiserNameController.text.trim() : null,
      advertiserType: _selectedAdvertiserType,
      latitude: user?.latitude,
      longitude: user?.longitude,
      address: user?.address,
    );
    
    // تحديث كلمة المرور فقط إذا تم كتابة شيء في الحقول
    bool passwordSuccess = true;
    if (_newPasswordController.text.isNotEmpty || _currentPasswordController.text.isNotEmpty) {
      if (_newPasswordController.text.isEmpty || _currentPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Both current and new passwords are required to change password'), backgroundColor: Colors.red)
        );
        return;
      }
      
      passwordSuccess = await provider.updateUserPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
    }

    if (!mounted) return;
    if (profileSuccess && passwordSuccess) {
       // Refresh user data after successful update
       await provider.fetchUserProfile();
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green));
       context.pop();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.updateError ?? "Failed to save profile."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, provider, child) {
            // أثناء التحميل لأول مرة، نعرض مؤشر تحميل
            if (provider.isLoadingProfile && provider.user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // في حالة وجود خطأ عند التحميل الأول
            if (provider.profileError != null && provider.user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error: ${provider.profileError}", style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => provider.fetchUserProfile(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Ensure user data is available before rendering
            if (provider.user == null) {
              return const Center(child: Text('No user data available'));
            }

            // نعرض الواجهة دائمًا بمجرد وجود بيانات
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
                        Transform.translate(offset: Offset(-3.w, 0), child: Text(S.of(context).back, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: Text(S.of(context).myProfile, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500, color: KTextColor))),
                  const SizedBox(height: 5),

                  _buildLabel(S.of(context).userName),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: CustomTextField(controller: _userNameController, hintText: "Username")),

                  _buildLabel(S.of(context).phone),
                  _buildEditableField(_phoneController, () => context.push('/profile')),
                  
                  _buildLabel(S.of(context).whatsApp),
                  _buildEditableField(_whatsAppController, () => context.push('/profile')),
                  
                  _buildLabel("Current Password (for changing)"),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: CustomTextField(controller: _currentPasswordController, hintText: 'Current password', isPassword: true)),

                  _buildLabel("New Password (leave empty to not change)"),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: CustomTextField(controller: _newPasswordController, hintText: 'New password', isPassword: true)),
                  
                  _buildLabel(S.of(context).advertiserName),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: CustomTextField(controller: _advertiserNameController, hintText: S.of(context).optional)),
                  
                  _buildLabel(S.of(context).advertiserType),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: S.of(context).optional,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KTextColor, width: 1.5)),
                      ),
                      value: _selectedAdvertiserType, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: KTextColor),
                      items: advertiserTypes.map((v) => DropdownMenuItem<String>(value: v, child: Text(v, style: const TextStyle(color: KTextColor)))).toList(),
                      onChanged: (v) => setState(() => _selectedAdvertiserType = v),
                    ),
                  ),

                   _buildLabel(S.of(context).advertiserLogo),
                            if (_logoImageFile == null)
                              // If no image is selected, show the "Upload" button
                              _buildUploadButton()
                            else
                              // If an image is selected, show it with Edit/Delete buttons
                              _buildImagePreview(),
                            
                            const SizedBox(height: 10),
                            
                            Text(S.of(context).advertiserLocation, style: TextStyle(color: KTextColor, fontSize: 16.sp, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Text(
              _userAddress ?? S.of(context).address,
              style: TextStyle(color: KTextColor, fontSize: 16.sp, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
                            const SizedBox(height: 5),
                            
                           _buildMapSection(context),
                            
                            const SizedBox(height: 10),
                  
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                  //   child: Container(
                  //     height: 120,
                  //     width: 120,
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey[200],
                  //       borderRadius: BorderRadius.circular(60),
                  //       border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1), width: 2),
                  //     ),
                  //     child: const Center(
                  //       child: Icon(Icons.person, size: 50, color: Color.fromRGBO(8, 194, 201, 1)),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: Text(S.of(context).cancel), style: OutlinedButton.styleFrom(foregroundColor: KTextColor, side: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: provider.isUpdating
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(onPressed: _saveProfile, child: Text(S.of(context).save), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01547E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                        ),
                      ],
                    ),
                  ),
                   const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

   Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(text, style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp)));
 
 
  Widget _buildMapSection(BuildContext context) {
    final s = S.of(context);
    return Consumer<GoogleMapsProvider>(
      builder: (context, mapsProvider, child) {
        return Container(
          height: 200.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1)),
          ),
          child: _isLoadingLocation
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF01547E),
                  ),
                )
              : _userLocation == null
                  ? Stack(
                      children: [
                        // Background placeholder
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Press "Locate Me" to set your location',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Buttons at the bottom
                        Positioned(
                          bottom: 2,
                          left: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // Locate Me button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: _isLoadingLocation 
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                      label: Text(
                                        _isLoadingLocation ? 'جاري التحديد...' : s.locateMe,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                                      ),
                                      onPressed: _isLoadingLocation ? null : () async {
                                        await _getCurrentLocation();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isLoadingLocation ? Colors.grey : const Color(0xFF01547E),
                                        minimumSize: const Size(0, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Open Google Map button
                                  Expanded(
                                    child: 
                                    ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                  label: const Text(
                                    "Open Google Map",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    await _navigateToLocationPicker();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF01547E),
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                            ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Location Picker button
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: 
                              //   ElevatedButton.icon(
                              //     icon: const Icon(Icons.place, color: Colors.white, size: 20),
                              //     label: const Text(
                              //       'اختيار الموقع من الخريطة',
                              //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                              //     ),
                              //     onPressed: () async {
                              //       await _navigateToLocationPicker();
                              //     },
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: const Color(0xFF4CAF50),
                              //       minimumSize: const Size(0, 40),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _userLocation!,
                                zoom: 15.0,
                              ),
                              onMapCreated: (GoogleMapController controller) {
                                mapsProvider.onMapCreated(controller);
                              },
                              mapType: MapType.normal,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: true,
                              compassEnabled: true,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              onTap: (LatLng position) async {
                                 // Update user location when tapping on map
                                 setState(() {
                                   _userLocation = position;
                                 });
                                 
                                 // Get address for the new location
                                 final address = await mapsProvider.getAddressFromCoordinates(
                                   position.latitude,
                                   position.longitude,
                                 );
                                 
                                 if (address != null) {
                                   setState(() {
                                     _userAddress = address;
                                   });
                                 }
                                 
                                 // Save location data automatically
                                 await _saveLocationData();
                               },
                              markers: _userLocation != null
                                  ? {
                                      Marker(
                                        markerId: const MarkerId('user_location'),
                                        position: _userLocation!,
                                        draggable: true,
                                        onDragEnd: (LatLng position) async {
                                           setState(() {
                                             _userLocation = position;
                                           });
                                           
                                           // Get address for the new location
                                           final address = await mapsProvider.getAddressFromCoordinates(
                                             position.latitude,
                                             position.longitude,
                                           );
                                           
                                           if (address != null) {
                                             setState(() {
                                               _userAddress = address;
                                             });
                                           }
                                           
                                           // Save location data automatically
                                           await _saveLocationData();
                                         },
                                      ),
                                    }
                                  : {},
                            ),
                          ),
                        ),
                        // Buttons at the bottom when map is visible
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // Locate Me button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                      label: Text(
                                        s.locateMe,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                                      ),
                                      onPressed: () async {
                                        await _getCurrentLocation();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF01547E),
                                        minimumSize: const Size(0, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Open Google Map button
                                  Expanded(
                                    child:
                                   

                                     ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                  label: const Text(
                                    "Open Google Map",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    await _navigateToLocationPicker();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF01547E),
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Location Picker button
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: ElevatedButton.icon(
                              //     icon: const Icon(Icons.place, color: Colors.white, size: 20),
                              //     label: const Text(
                              //       'اختيار الموقع من الخريطة',
                              //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                              //     ),
                              //     onPressed: () async {
                              //       await _navigateToLocationPicker();
                              //     },
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: const Color(0xFF4CAF50),
                              //       minimumSize: const Size(0, 40),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              //     ),
                              //   ),
                              // ),
                           
                           
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  // Widget _buildMapSection(BuildContext context) {
  //   final s = S.of(context);
  //   return Consumer<GoogleMapsProvider>(
  //     builder: (context, mapsProvider, child) {
  //       return Container(
  //         height: 200.h,
  //         width: double.infinity,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1)),
  //         ),
  //         child: _isLoadingLocation
  //             ? const Center(
  //                 child: CircularProgressIndicator(
  //                   color: Color(0xFF01547E),
  //                 ),
  //               )
  //             : _userLocation == null
  //                 ? Stack(
  //                     children: [
  //                       // Background placeholder
  //                       Positioned.fill(
  //                         child: ClipRRect(
  //                           borderRadius: BorderRadius.circular(12),
  //                           child: Container(
  //                             color: Colors.grey[100],
  //                             child: const Center(
  //                               child: Column(
  //                                 mainAxisAlignment: MainAxisAlignment.center,
  //                                 children: [
  //                                   Icon(
  //                                     Icons.location_off,
  //                                     size: 48,
  //                                     color: Colors.grey,
  //                                   ),
  //                                   SizedBox(height: 8),
  //                                   Text(
  //                                     'اضغط "تحديد موقعي" لتعيين موقعك',
  //                                     style: TextStyle(color: Colors.grey, fontSize: 14),
  //                                     textAlign: TextAlign.center,
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                       // Buttons at the bottom
  //                       Positioned(
  //                         bottom: 16,
  //                         left: 16,
  //                         right: 16,
  //                         child: Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Row(
  //                               children: [
  //                                 // Locate Me button
  //                                 Expanded(
  //                                   child: ElevatedButton.icon(
  //                                     icon: _isLoadingLocation 
  //                                       ? const SizedBox(
  //                                           width: 20,
  //                                           height: 20,
  //                                           child: CircularProgressIndicator(
  //                                             strokeWidth: 2,
  //                                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //                                           ),
  //                                         )
  //                                       : const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
  //                                     label: Text(
  //                                       _isLoadingLocation ? 'جاري التحديد...' : s.locateMe,
  //                                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
  //                                     ),
  //                                     onPressed: _isLoadingLocation ? null : () async {
  //                                       await _getCurrentLocation();
  //                                     },
  //                                     style: ElevatedButton.styleFrom(
  //                                       backgroundColor: _isLoadingLocation ? Colors.grey : const Color(0xFF01547E),
  //                                       minimumSize: const Size(0, 40),
  //                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 8),
  //                                 // Open Google Map button
  //                                 Expanded(
  //                                   child: ElevatedButton.icon(
  //                                     icon: const Icon(Icons.map, color: Colors.white, size: 20),
  //                                     label: const Text(
  //                                       "فتح الخريطة",
  //                                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
  //                                     ),
  //                                     onPressed: () async {
  //                                       await _navigateToLocationPicker();
  //                                     },
  //                                     style: ElevatedButton.styleFrom(
  //                                       backgroundColor: const Color(0xFF01547E),
  //                                       minimumSize: const Size(0, 40),
  //                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   )
  //                 : Stack(
  //                     children: [
  //                       Positioned.fill(
  //                         child: ClipRRect(
  //                           borderRadius: BorderRadius.circular(12),
  //                           child: GoogleMap(
  //                             initialCameraPosition: CameraPosition(
  //                               target: _userLocation!,
  //                               zoom: 15.0,
  //                             ),
  //                             onMapCreated: (GoogleMapController controller) {
  //                               mapsProvider.onMapCreated(controller);
  //                             },
  //                             mapType: MapType.normal,
  //                             myLocationEnabled: false,
  //                             myLocationButtonEnabled: false,
  //                             zoomControlsEnabled: true,
  //                             compassEnabled: true,
  //                             zoomGesturesEnabled: true,
  //                             scrollGesturesEnabled: true,
  //                             tiltGesturesEnabled: true,
  //                             rotateGesturesEnabled: true,
  //                             onTap: (LatLng position) async {
  //                                // Update user location when tapping on map
  //                                setState(() {
  //                                  _userLocation = position;
  //                                });
                                 
  //                                // Get address for the new location
  //                                final address = await mapsProvider.getAddressFromCoordinates(
  //                                  position.latitude,
  //                                  position.longitude,
  //                                );
                                 
  //                                if (address != null) {
  //                                  setState(() {
  //                                    _userAddress = address;
  //                                  });
  //                                }
                                 
  //                                // Save location data automatically
  //                                await _saveLocationData();
  //                              },
  //                             markers: _userLocation != null
  //                                 ? {
  //                                     Marker(
  //                                       markerId: const MarkerId('user_location'),
  //                                       position: _userLocation!,
  //                                       draggable: true,
  //                                       onDragEnd: (LatLng position) async {
  //                                          setState(() {
  //                                            _userLocation = position;
  //                                          });
                                           
  //                                          // Get address for the new location
  //                                          final address = await mapsProvider.getAddressFromCoordinates(
  //                                            position.latitude,
  //                                            position.longitude,
  //                                          );
                                           
  //                                          if (address != null) {
  //                                            setState(() {
  //                                              _userAddress = address;
  //                                            });
  //                                          }
                                           
  //                                          // Save location data automatically
  //                                          await _saveLocationData();
  //                                        },
  //                                     ),
  //                                   }
  //                                 : {},
  //                           ),
  //                         ),
  //                       ),
  //                       // Buttons at the bottom when map is visible
  //                       Positioned(
  //                         bottom: 16,
  //                         left: 16,
  //                         right: 16,
  //                         child: Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Row(
  //                               children: [
  //                                 // Locate Me button
  //                                 Expanded(
  //                                   child: ElevatedButton.icon(
  //                                     icon: _isLoadingLocation 
  //                                       ? const SizedBox(
  //                                           width: 20,
  //                                           height: 20,
  //                                           child: CircularProgressIndicator(
  //                                             strokeWidth: 2,
  //                                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //                                           ),
  //                                         )
  //                                       : const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
  //                                     label: Text(
  //                                       _isLoadingLocation ? 'جاري التحديد...' : s.locateMe,
  //                                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
  //                                     ),
  //                                     onPressed: _isLoadingLocation ? null : () async {
  //                                       await _getCurrentLocation();
  //                                     },
  //                                     style: ElevatedButton.styleFrom(
  //                                       backgroundColor: _isLoadingLocation ? Colors.grey : const Color(0xFF01547E),
  //                                       minimumSize: const Size(0, 40),
  //                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 8),
  //                                 // Open Google Map button
  //                                 Expanded(
  //                                   child: ElevatedButton.icon(
  //                                     icon: const Icon(Icons.map, color: Colors.white, size: 20),
  //                                     label: const Text(
  //                                       "فتح الخريطة",
  //                                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
  //                                     ),
  //                                     onPressed: () async {
  //                                       await _navigateToLocationPicker();
  //                                     },
  //                                     style: ElevatedButton.styleFrom(
  //                                       backgroundColor: const Color(0xFF01547E),
  //                                       minimumSize: const Size(0, 40),
  //                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //       );
  //     },
  //   );
  // }
  
    Widget _buildUploadButton() {
    return GestureDetector(
     onTap: _pickLogoImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: KTextColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                S.of(context).uploadYourLogo,
                style: const TextStyle(color: KTextColor, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the image preview with overlay buttons (Edit/Delete).
  Widget _buildImagePreview() {
    final user = context.watch<AuthProvider>().user;
    
    return SizedBox(
      height: 200.h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The selected image or network image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _logoImageFile != null
                ? Image.file(_logoImageFile!, fit: BoxFit.cover)
                : (user?.advertiserLogo != null && user!.advertiserLogo!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ImageUrlHelper.getFullImageUrl(user.advertiserLogo!),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                      )
                    : const Center(child: Icon(Icons.person, size: 50, color: Colors.grey))),
          ),
          // A semi-transparent overlay to make buttons more visible
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          // The action buttons (Edit, Delete) in the center
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageActionButton(
                  icon: Icons.edit,
                  label: S.of(context).edit, // "Edit"
                  onTap: _pickLogoImage,
                  color: Colors.white,
                ),
                if (user?.advertiserLogo != null && user!.advertiserLogo!.isNotEmpty)
                  _buildImageActionButton(
                    icon: Icons.delete,
                    label: "delete", // "Delete"
                    onTap: _deleteLogoImage,
                    color: Colors.red.shade300,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogoImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final authProvider = context.read<AuthProvider>();
      final newLogoFile = File(pickedFile.path);
      
      final success = await authProvider.uploadLogo(newLogoFile.path);
      if (success) {
        setState(() {
          _logoImageFile = newLogoFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.updateError ?? 'Failed to upload logo'), backgroundColor: Colors.red),
        );
      }
    }
  }
 
   Future<void> _deleteLogoImage() async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.deleteLogo();
    if (success) {
      setState(() {
        _logoImageFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo deleted successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.updateError ?? 'Failed to delete logo'), backgroundColor: Colors.red),
      );
    }
  }

  
  Widget _buildImageActionButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28.sp),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  
  /// Builds a read-only text field that shows the edit popup on tap.
  Widget _buildEditableField(TextEditingController controller, VoidCallback onEdit, {bool isPassword = false}) {
    return GestureDetector(
      onTap: () => _showEditPopup(() => context.push('/profile')),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          obscureText: isPassword,
          style: TextStyle(color: KTextColor, fontSize: 14.sp, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1))),
          ),
        ),
      ),
    );
  }

  /// Shows the popup dialog asking the user to navigate to the edit page.
  void _showEditPopup(VoidCallback onEdit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF01547E)),
            const SizedBox(width: 8),
            Text(S.of(context).editing1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF01547E))),
          ],
        ),
        content: Text(S.of(context).editit2, style: TextStyle(fontSize: 16.sp, color: KTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01547E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(S.of(context).edit3),
          ),
        ],
      ),
    );
  }

  
}