// lib/presentation/screens/car_services_ad_screen.dart

import 'dart:io';

import 'package:advertising_app/presentation/providers/car_services_info_provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

class CarServicesAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;

  const CarServicesAdScreen({Key? key, required this.onLanguageChange}) : super(key: key);

  @override
  State<CarServicesAdScreen> createState() => _CarServicesAdScreenState();
}

class _CarServicesAdScreenState extends State<CarServicesAdScreen> {
  // --- Controllers لحقول الإدخال ---
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- متغيرات الحالة لحفظ الاختيارات ---
  String? selectedEmirate;
  String? selectedDistrict;
  String? selectedServiceType;
  String? selectedAdvertiserName;
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;
  
  // --- متغيرات لحفظ الصور ---
  File? _mainImage;
  final List<File> _thumbnailImages = [];
  final ImagePicker _picker = ImagePicker();

  // --- متغيرات للخريطة والموقع ---
  String selectedLocation = ''; 
  LatLng? selectedLatLng;
  bool _isLoadingLocation = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // جلب جميع البيانات اللازمة لهذه الشاشة (بيانات عامة لا تتطلب توكن)
      final infoProvider = context.read<CarServicesInfoProvider>();
      await infoProvider.fetchAllData();

      // طباعة البيانات المحملة للتحقق
      print('Advertiser Names Loaded: ${infoProvider.advertiserNames}');
      print('Phone Numbers Loaded: ${infoProvider.phoneNumbers}');
      print('Locations Loaded: ${infoProvider.locations}');

      // التحقق من بيانات البروفايل
      final authProvider = context.read<AuthProvider>();
      await _checkUserProfileData(authProvider);

      // تطبيق العنوان المختار لتحريك الخريطة عند فتح الصفحة
      await _applySelectedLocationAddress();
    });
  }
  
  @override
  void dispose() {
    _areaController.dispose();
    _serviceNameController.dispose();
    _priceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _applySelectedLocationAddress() async {
    try {
      if (selectedLocation.isNotEmpty && selectedLatLng == null) {
        final locations = await locationFromAddress(selectedLocation);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          final latLng = LatLng(loc.latitude, loc.longitude);
          setState(() => selectedLatLng = latLng);
          await context.read<GoogleMapsProvider>().moveCameraToLocation(
              latLng.latitude, latLng.longitude,
              zoom: 16.0);
        }
      }
    } catch (e) {
      debugPrint('Geocoding failed: $e');
    }
  }

  // --- دوال الصور (منسوخة من شاشة السيارات) ---
  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _mainImage = File(image.path));
  }

  Future<void> _pickThumbnailImages() async {
    const int maxImages = 3;
    final int remainingSlots = maxImages - _thumbnailImages.length;
    if (remainingSlots <= 0) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'لقد أضفت الحد الأقصى من الصور ($maxImages صور).' : 'You have added the maximum number of images ($maxImages total).'),
          backgroundColor: KPrimaryColor,
        ),
      );
      return;
    }
    final List<XFile> pickedImages = await _picker.pickMultiImage(imageQuality: 85);
    if (pickedImages.isNotEmpty) {
      int addedCount = 0;
      for (var img in pickedImages) {
        if (_thumbnailImages.length < maxImages) {
          _thumbnailImages.add(File(img.path));
          addedCount++;
        }
      }
      setState(() {});
      if (addedCount < pickedImages.length) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'تم الوصول للحد الأقصى. تم إضافة $addedCount من ${pickedImages.length} صورة فقط.'
                : 'Reached the maximum limit. Added $addedCount of ${pickedImages.length} images only.'),
            backgroundColor: KPrimaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة ${pickedImages.length} صورة بنجاح.'), backgroundColor: Colors.green));
      }
    }
  }

  // دالة لإزالة صورة مصغرة
  void _removeThumbnailImage(int index) {
    setState(() {
      _thumbnailImages.removeAt(index);
    });
  }

  // دالة للتحقق من بيانات البروفايل المطلوبة
  Future<void> _checkUserProfileData(AuthProvider authProvider) async {
    // جلب بيانات المستخدم إذا لم تكن متاحة
    if (authProvider.user == null) {
      await authProvider.fetchUserProfile();
    }

    final user = authProvider.user;
    if (user == null) return;

    // تحديد الموقع من بيانات المستخدم إذا كان متوفراً
    if (user.advertiserLocation != null && user.advertiserLocation!.trim().isNotEmpty) {
      setState(() {
        selectedLocation = user.advertiserLocation!;
      });
    }

    // تعيين إحداثيات الخريطة تلقائياً من البروفايل إن توفرت
    try {
      final hasCoords = user.latitude != null && user.longitude != null;
      if (hasCoords) {
        final latLng = LatLng(user.latitude!.toDouble(), user.longitude!.toDouble());
        setState(() => selectedLatLng = latLng);
        await context.read<GoogleMapsProvider>().moveCameraToLocation(
            latLng.latitude, latLng.longitude,
            zoom: 16.0);
      } else if (selectedLocation.isNotEmpty) {
        await _applySelectedLocationAddress();
      }
    } catch (e) {
      debugPrint('Failed to set default coordinates from profile: $e');
    }

    List<String> missingFields = [];

    // التحقق من الحقول المطلوبة
    if (user.phone.trim().isEmpty) {
      missingFields.add('رقم الهاتف');
    }
    if ((user.advertiserLocation == null || user.advertiserLocation!.trim().isEmpty) &&
        (user.latitude == null || user.longitude == null)) {
      missingFields.add('الموقع');
    }

    // إظهار التنبيه إذا كانت هناك حقول ناقصة
    if (missingFields.isNotEmpty && mounted) {
      _showProfileIncompleteDialog(missingFields);
    }
  }

  // دالة لإظهار تنبيه البيانات الناقصة
  void _showProfileIncompleteDialog(List<String> missingFields) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final s = S.of(context);
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        final List<String> localizedMissingFields = missingFields.map((field) {
          final lower = field.trim().toLowerCase();
          if (lower == 'phone number' || field == 'رقم الهاتف') {
            return s.phone;
          }
          if (lower == 'your location' || field == 'الموقع') {
            return s.advertiserLocation;
          }
          return field;
        }).toList();

        return WillPopScope(
          onWillPop: () async {
            // عند الضغط على زر الرجوع، الخروج من الصفحة بالكامل
            Navigator.of(context).pop(); // إغلاق الـ dialog
            Navigator.of(context).pop(); // العودة إلى الشاشة السابقة
            return false;
          },
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(s.editprof4,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: KTextColor,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.profileWarning,
                  style: const TextStyle(
                    fontSize: 16,
                    color: KTextColor,
                  ),
                ),
                const SizedBox(height: 15),
                ...localizedMissingFields
                    .map((field) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFE74C3C),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  field,
                                  style: const TextStyle(
                                    color: Color(0xFFE74C3C),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Future.microtask(() => context.push('/editprofile'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(1, 84, 126, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    s.myProfile,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            
              const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(1, 84, 126, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    s.cancel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

   // --- دوال الخريطة (منسوخة من شاشة السيارات مع تعديلات بسيطة) ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري تحديد الموقع...'), backgroundColor: KPrimaryColor));
    
    try {
      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();
      
      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        await mapsProvider.moveCameraToLocation(latLng.latitude, latLng.longitude, zoom: 16.0);
        final address = await mapsProvider.getAddressFromCoordinates(latLng.latitude, latLng.longitude);
        
        setState(() {
          selectedLatLng = latLng;
          if (address != null) selectedLocation = address;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديد الموقع بنجاح'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في تحديد الموقع: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _navigateToLocationPicker() async {
    final result = await context.push('/location_picker', extra: {'initialLatLng': selectedLatLng});
    if (result != null && result is Map<String, dynamic>) {
        final LatLng? location = result['location'] as LatLng?;
        final String? address = result['address'] as String?;
        if(location != null) {
          setState(() {
            selectedLatLng = location;
            if(address != null) selectedLocation = address;
          });
        }
    }
  }

  // دالة التحقق والانتقال
  Future<void> _validateAndProceedToNext() async {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      if (!_formKey.currentState!.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).please_fill_required_fields),
              backgroundColor: KPrimaryColor,
            ),
          );
          return;
      }
      
      // التحقق من الحقول المطلوبة
      if (selectedAdvertiserName == null || selectedAdvertiserName!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'الرجاء اختيار اسم المعلن.' : 'Please select advertiser name.'),
              backgroundColor: KPrimaryColor,
            ),
          );
          return;
      }
      
      if (selectedPhoneNumber == null || selectedPhoneNumber!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'الرجاء إدخال رقم الهاتف.' : 'Please enter phone number.'),
              backgroundColor: KPrimaryColor,
            ),
          );
          return;
      }
      
      if (_descriptionController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'الرجاء إدخال الوصف.' : 'Please enter description.'),
              backgroundColor: KPrimaryColor,
            ),
          );
          return;
      }
      
      if (_mainImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'الرجاء إضافة صورة رئيسية.' : 'Please add a main image.'),
              backgroundColor: KPrimaryColor,
            ),
          );
          return;
      }
      
      if (selectedLocation.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'الرجاء تحديد الموقع.' : 'Please select a location.'),
              backgroundColor: KPrimaryColor,
            ),
          );
          return;
      }
      
      final infoProvider = context.read<CarServicesInfoProvider>();
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      
      // إضافة الموقع إلى contact info إذا لم يكن موجوداً
      if (token != null && selectedLocation.isNotEmpty && !infoProvider.locations.contains(selectedLocation)) {
        await infoProvider.addContactItem('locations', selectedLocation, token: token);
      }

      // تحويل أسماء العرض إلى أسماء الـ API
      final serviceTypeName = infoProvider.getServiceNameFromDisplayName(selectedServiceType);
      final emirateName = infoProvider.getEmirateNameFromDisplayName(selectedEmirate);
      
      // تنسيق أرقام الهواتف
      String formattedPhone = PhoneNumberFormatter.formatForApi(selectedPhoneNumber!);
      String? formattedWhatsApp;
      if (selectedWhatsAppNumber != null && selectedWhatsAppNumber!.isNotEmpty) {
        formattedWhatsApp = PhoneNumberFormatter.formatForApi(selectedWhatsAppNumber!);
      }

      final adData = {
            'adType': 'car_service', 
          'title': _titleController.text,
          'description': _descriptionController.text,
          'emirate': emirateName,
          'district': selectedDistrict,
          'area': _areaController.text,
          'service_name': _serviceNameController.text,
          'service_type': serviceTypeName,
          'price': _priceController.text,
          'advertiser_name': selectedAdvertiserName,
          'phone_number': formattedPhone,
          'whatsapp': formattedWhatsApp,
          'advertiser_location': selectedLocation,
          'mainImage': _mainImage!,
          'thumbnailImages': _thumbnailImages.isNotEmpty ? _thumbnailImages : null,
      };

      // طباعة البيانات المرسلة
      print('=== Car Services Ad Data ===');
      print('adType: ${adData['adType']}');
      print('title: ${adData['title']}');
      print('description: ${adData['description']}');
      print('emirate: ${adData['emirate']}');
      print('district: ${adData['district']}');
      print('area: ${adData['area']}');
      print('service_name: ${adData['service_name']}');
      print('service_type: ${adData['service_type']}');
      print('price: ${adData['price']}');
      print('advertiser_name: ${adData['advertiser_name']}');
      print('phone_number: ${adData['phone_number']}');
      print('whatsapp: ${adData['whatsapp']}');
      print('advertiser_location: ${adData['advertiser_location']}');
      print('mainImage: ${adData['mainImage'] != null ? 'File selected' : 'null'}');
      print('thumbnailImages: ${adData['thumbnailImages'] != null ? '${(_thumbnailImages.length)} images' : 'null'}');
      print('plan_type: ${adData['plan_type']}');
      print('plan_days: ${adData['plan_days']}');
      print('plan_expires_at: ${adData['plan_expires_at']}');
      print('========================');

      context.push('/placeAnAd', extra: adData);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);
    
    // استخدام Consumer للوصول للـ provider وإعادة بناء الواجهة عند التغيير
    return Consumer<CarServicesInfoProvider>(
      builder: (context, infoProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: infoProvider.isLoading
            ? Center(child: CircularProgressIndicator())
            : infoProvider.error != null
              ? Center(child: Text("Error: ${infoProvider.error}"))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 25.h),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Row(children: [
                              SizedBox(width: 5.w),
                              Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                              Transform.translate(offset: Offset(-3.w, 0), child: Text(s.back, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: KTextColor))),
                            ]),
                          ),
                          SizedBox(height: 7.h),
                          Center(child: Text(s.carsServicesAds, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24.sp, color: KTextColor))),
                          SizedBox(height: 10.h),
                          
                          _buildFormRow([
                             _buildSingleSelectField(context, s.emirate, selectedEmirate, infoProvider.emirateNames, (selection) {
                               setState(() {
                                 selectedEmirate = selection;
                                 selectedDistrict = null; // إعادة تعيين المنطقة عند تغيير الإمارة
                               });
                             }, isRequired: true),
                             _buildSingleSelectField(context, s.district, selectedDistrict, infoProvider.getDistrictsForEmirate(selectedEmirate), (selection) {
                               setState(() => selectedDistrict = selection);
                             }, isRequired: true),
                           _buildTitledTextFormField(s.area, _areaController, borderColor, currentLocale, hintText: s.enterArea, isRequired: true),
               
                          
                          ]),
                          const SizedBox(height: 7),

                                   

                           _buildFormRow([
                            _buildSingleSelectField(context, s.serviceType, selectedServiceType, infoProvider.serviceTypeNames, (selection) {
                                setState(() => selectedServiceType = selection);
                             }, isRequired: true),
                            _buildTitledTextFormField(s.serviceName, _serviceNameController, borderColor, currentLocale, hintText: s.enterName, isRequired: true),
                          _buildTitledTextFormField(s.price, _priceController, borderColor, currentLocale, hintText: '300', isNumber: true, isRequired: true),
                
                         
                         
                         
                          ]),
                           const SizedBox(height: 7),
                          
                          _buildTitledTextFormField(s.title, _titleController, borderColor, currentLocale, hintText: s.enterTitle, minLines: 3, maxLines: 4, isRequired: true),
                          const SizedBox(height: 7),
                          
                           Consumer<CarServicesInfoProvider>(
                             builder: (context, provider, child) {
                               // التأكد من أن البيانات محملة
                               final advertiserNames = provider.advertiserNames ?? [];
                               print('Building advertiser field with ${advertiserNames.length} names: $advertiserNames');
                               
                               return TitledSelectOrAddField(
                                 title: s.advertiserName, 
                                 value: selectedAdvertiserName,
                                 items: advertiserNames,
                                 onChanged: (newValue) => setState(() => selectedAdvertiserName = newValue),
                                 onAddNew: (value) async {
                                    final token = await const FlutterSecureStorage().read(key: 'auth_token');
                                    if (token != null) {
                                      final success = await provider.addContactItem('advertiser_names', value, token: token);
                                      if (success) setState(() => selectedAdvertiserName = value);
                                    }
                                  },
                               );
                             },
                           ),
                           const SizedBox(height: 7),

                          _buildFormRow([
                             Consumer<CarServicesInfoProvider>(
                               builder: (context, provider, child) {
                                 final phoneNumbers = provider.phoneNumbers ?? [];
                                 print('Building phone field with ${phoneNumbers.length} numbers: $phoneNumbers');
                                 
                                 return TitledSelectOrAddField(
                                   title: s.phoneNumber, 
                                   value: selectedPhoneNumber,
                                   items: phoneNumbers,
                                   onChanged: (newValue) => setState(() => selectedPhoneNumber = newValue),
                                   onAddNew: (value) async {
                                     final token = await const FlutterSecureStorage().read(key: 'auth_token');
                                     if(token != null) {
                                       final success = await provider.addContactItem('phone_numbers', value, token: token);
                                       if(success) setState(() => selectedPhoneNumber = value);
                                     }
                                   },
                                   isNumeric: true
                                 );
                               },
                             ),
                             TitledSelectOrAddField(
                               title: s.whatsApp, 
                               value: selectedWhatsAppNumber,
                               items: infoProvider.whatsappNumbers,
                               onChanged: (newValue) => setState(() => selectedWhatsAppNumber = newValue),
                                onAddNew: (value) async {
                                 final token = await const FlutterSecureStorage().read(key: 'auth_token');
                                 if(token != null) {
                                   final success = await infoProvider.addContactItem('whatsapp_numbers', value, token: token);
                                   if(success) setState(() => selectedWhatsAppNumber = value);
                                 }
                               },
                               isNumeric: true
                             ),
                          ]),
                          const SizedBox(height: 7),
                          
                          TitledDescriptionBox(title: s.description, controller: _descriptionController, borderColor: borderColor),
                          const SizedBox(height: 10),
                          
                          _buildImageButton(s.addMainImage, Icons.add_a_photo_outlined, borderColor, onPressed: _pickMainImage),
                          if (_mainImage != null)
                             Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_mainImage!, height: 150, fit: BoxFit.cover)))),
                           const SizedBox(height: 7),

                          _buildImageButton('${s.add3Images} (${_thumbnailImages.length}/3)', Icons.add_photo_alternate_outlined, borderColor, onPressed: _pickThumbnailImages),
                           if (_thumbnailImages.isNotEmpty)
                             Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: _thumbnailImages.asMap().entries.map((entry) {
                                     int idx = entry.key;
                                     File img = entry.value;
                                     return Stack(
                                        children: [
                                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(img, width: 80, height: 80, fit: BoxFit.cover)),
                                          Positioned(
                                            top: 2, right: 2,
                                            child: GestureDetector(
                                              onTap: () => _removeThumbnailImage(idx),
                                              child: Container(
                                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                                child: Icon(Icons.close, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                  }).toList(),
                                )
                              ),
                           const SizedBox(height: 7),
                          
                          Text(s.location, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor)),
                           SizedBox(height: 4.h),
                          
                          Directionality(
                             textDirection: TextDirection.ltr,
                             child: Row(
                              children: [
                                SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 20.h),
                                SizedBox(width: 8.w),
                                Expanded(child: Text(selectedLocation.isNotEmpty ? selectedLocation : S.of(context).advertiserLocation, style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),
                           SizedBox(height: 8.h),
                          _buildMapSection(context),
                           const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _validateAndProceedToNext,
                              child: Text(s.next, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KPrimaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                           SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  // --- دوال المساعدة للواجهة (مع تعديلات لدعم isRequired) ---
  Widget _buildFormRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }
  Widget _buildTitledTextFormField(String title, TextEditingController controller, Color borderColor, String currentLocale, {bool isNumber = false, String? hintText, int minLines = 1, int maxLines =1, bool isRequired = false}) {
     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)), const SizedBox(height: 4),
        TextFormField(
            controller: controller,
            minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLines > 1 ? 100 : null,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
            style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
            textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: title == S.of(context).title && maxLines == 2 ? [
              TextInputFormatter.withFunction((oldValue, newValue) {
                // منع إدخال أكثر من سطرين عبر فواصل الأسطر
                final lineCount = newValue.text.split('\n').length;
                if (lineCount > 2) {
                  return oldValue;
                }
                return newValue;
              })
            ] : null,
            validator: isRequired ? (value) {
                if (value == null || value.trim().isEmpty) return 'This field is required';
                return null;
              } : null,
            decoration: InputDecoration(
              counterText: "",
              hintText: hintText, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.white, filled: true
            ),
        )
    ]);
  }
  Widget _buildSingleSelectField(BuildContext context, String title, String? selectedValue, List<String> allItems, Function(String?) onConfirm, {bool isRequired = false}) {
    final s = S.of(context);
    String displayText = selectedValue ?? s.chooseAnOption;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)), const SizedBox(height: 4),
        FormField<String>(
           validator: isRequired ? (value) {
                if (selectedValue == null) return 'Required'; // التحقق من القيمة المحفوظة في الـ state
                return null;
            } : null,
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await _showSingleSelectPicker(context, title: title, items: allItems);
                     onConfirm(result);
                     // إخبار FormField بوجود تغيير لتحديث حالة التحقق
                     if(result != null) state.didChange(result);
                  },
                  child: Container(
                    height: 48, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: state.hasError ? Colors.red : Color.fromRGBO(8, 194, 201, 1)), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      displayText, style: TextStyle(fontWeight: selectedValue == null ? FontWeight.normal : FontWeight.w500, color: selectedValue == null ? Colors.grey.shade500 : KTextColor, fontSize: 12.sp),
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                    ),
                  ),
                ),
                 if(state.hasError) Padding(padding: const EdgeInsets.only(top: 5, left: 10), child: Text(state.errorText!, style: TextStyle(color: Colors.red, fontSize: 10.sp))),
              ],
            );
          },
        ),
      ],
    );
  }
  Future<String?> _showSingleSelectPicker(BuildContext context, { required String title, required List<String> items}) {
    return showModalBottomSheet<String>( context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _SingleSelectBottomSheet(title: title, items: items),
    );
  }
  Widget _buildImageButton(String title, IconData icon, Color borderColor, {required VoidCallback onPressed}) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: Icon(icon, color: KTextColor), label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)), onPressed: onPressed, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
  }
  Widget _buildMapSection(BuildContext context) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
             Consumer<GoogleMapsProvider>(
                builder: (context, mapsProvider, child) => GoogleMap(
                    initialCameraPosition: CameraPosition(target: selectedLatLng ?? const LatLng(25.2048, 55.2708), zoom: 12.0),
                    onMapCreated: mapsProvider.onMapCreated,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    onTap: (pos) async {
                      final address = await mapsProvider.getAddressFromCoordinates(pos.latitude, pos.longitude);
                      setState(() {
                         selectedLatLng = pos;
                         if(address != null) selectedLocation = address;
                      });
                    },
                    markers: selectedLatLng == null ? {} : { Marker(markerId: MarkerId('selected_location'), position: selectedLatLng!)},
                     gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{ Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())},
                ),
            ),
             Positioned(
              bottom: 10, left: 10, right: 10,
              child: Row(
                children: [
                   Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoadingLocation ? Colors.grey : KPrimaryColor,
                        minimumSize: const Size(double.infinity, 43),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoadingLocation
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          :  Text(S.of(context).locateMe, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                    ),
                  ),
                   SizedBox(width: 10),
                   Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToLocationPicker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01547E),
                        minimumSize: const Size(double.infinity, 43),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child:  Text(S.of(context).pickLocation, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++        الودجت المساعدة المنقولة من الشاشات الأخرى    ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

class TitledSelectOrAddField extends StatelessWidget {
  final String title; final String? value; final List<String> items; final Function(String) onChanged; final bool isNumeric;
  final Function(String)? onAddNew;
  const TitledSelectOrAddField({ Key? key, required this.title, required this.value, required this.items, required this.onChanged, this.isNumeric = false, this.onAddNew}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    
    // طباعة البيانات للتحقق
    print('TitledSelectOrAddField - Title: $title, Items count: ${items.length}, Items: $items');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)), const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            print('Opening bottom sheet for $title with ${items.length} items');
            final result = await showModalBottomSheet<String>(
              context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _SearchableSelectOrAddBottomSheet(title: title, items: items, isNumeric: isNumeric, onAddNew: onAddNew),
            );
            if(result != null && result.isNotEmpty){ onChanged(result); }
          },
          child: Container(
            height: 48, padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: Text( value ?? s.chooseAnOption, style: TextStyle(fontWeight: value == null ? FontWeight.normal : FontWeight.w500, color: value == null ? Colors.grey.shade500 : KTextColor, fontSize: 12.sp), overflow: TextOverflow.ellipsis,)),],),),
        )
      ],
    );
  }
}

class _SearchableSelectOrAddBottomSheet extends StatefulWidget {
  final String title; final List<String> items; final bool isNumeric; final Function(String)? onAddNew;
  const _SearchableSelectOrAddBottomSheet({required this.title, required this.items, this.isNumeric = false, this.onAddNew});
  @override
  _SearchableSelectOrAddBottomSheetState createState() => _SearchableSelectOrAddBottomSheetState();
}
class _SearchableSelectOrAddBottomSheetState extends State<_SearchableSelectOrAddBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addController = TextEditingController();
  List<String> _filteredItems = [];
  String _selectedCountryCode = '+971';
  final Map<String, String> _countryCodes = PhoneNumberFormatter.countryCodes;
  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
    
    // طباعة البيانات في البداية
    print('_SearchableSelectOrAddBottomSheet initState - Title: ${widget.title}, Items: ${widget.items}');
  }
  @override
  void dispose() { _searchController.dispose(); _addController.dispose(); super.dispose(); }
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredItems = widget.items.where((i) => i.toLowerCase().contains(query)).toList());
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)), const SizedBox(height: 16),
            TextFormField(controller: _searchController, style: TextStyle(color: KTextColor), decoration: InputDecoration(hintText: s.search, prefixIcon: Icon(Icons.search, color: KTextColor), hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)))),
            const SizedBox(height: 8), const Divider(),
            Expanded(child: _filteredItems.isEmpty ? Center(child: Text(s.noResultsFound, style: TextStyle(color: KTextColor))) : ListView.builder(itemCount: _filteredItems.length, itemBuilder: (context, index) { final item = _filteredItems[index]; return ListTile(title: Text(item, style: TextStyle(color: KTextColor)), onTap: () => Navigator.pop(context, item)); }, ),),
            const Divider(), const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(widget.isNumeric)...[
                  SizedBox(width: 90, child: DropdownButtonFormField<String>(
                      value: _selectedCountryCode, items: _countryCodes.entries.map((entry) => DropdownMenuItem<String>(value: entry.value, child: Text(entry.value, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp)))).toList(), onChanged: (value) => setState(() => _selectedCountryCode = value!),
                      decoration: InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2))),
                      isDense: true, isExpanded: true),
                  ),
                   SizedBox(width: 8),
                ],
                Expanded(child: TextFormField(controller: _addController, keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp), decoration: InputDecoration(hintText: widget.isNumeric ? s.phoneNumber : s.addNew, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () async {
                  String result = _addController.text.trim();
                   if (widget.isNumeric && result.isNotEmpty) result = '$_selectedCountryCode$result';
                   if (result.isNotEmpty) {
                    if (widget.onAddNew != null) await widget.onAddNew!(result);
                     Navigator.pop(context, result);
                  }
                }, child: Text(s.add, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)), style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), minimumSize: const Size(60, 48))),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
class _SingleSelectBottomSheet extends StatefulWidget {
  final String title; final List<String> items;
  const _SingleSelectBottomSheet({required this.title, required this.items});
  @override
  _SingleSelectBottomSheetState createState() => _SingleSelectBottomSheetState();
}
class _SingleSelectBottomSheetState extends State<_SingleSelectBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  @override
  void initState() { super.initState(); _filteredItems = List.from(widget.items); _searchController.addListener(_filterItems); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList());
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context); final borderColor = Color.fromRGBO(8, 194, 201, 1);
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
      child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column( mainAxisSize: MainAxisSize.min, children: [
              Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)), const SizedBox(height: 16),
              TextFormField(controller: _searchController, style: TextStyle(color: KTextColor), decoration: InputDecoration(hintText: s.search, prefixIcon: Icon(Icons.search, color: KTextColor), hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),)),
              const SizedBox(height: 8), const Divider(),
              Expanded(child: _filteredItems.isEmpty ? Center(child: Text(s.noResultsFound, style: TextStyle(color: KTextColor))) : ListView.builder(itemCount: _filteredItems.length, itemBuilder: (context, index) { final item = _filteredItems[index]; return ListTile(title: Text(item, style: TextStyle(color: KTextColor)), onTap: () => Navigator.pop(context, item)); },),),
              const SizedBox(height: 16),
            ],
        ),
      ),
    );
  }
}
class TitledDescriptionBox extends StatelessWidget {
  final String title; final TextEditingController controller; final Color borderColor;
  const TitledDescriptionBox({Key? key, required this.title, required this.controller, required this.borderColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)), const SizedBox(height: 4),
      Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
        child: Column(
          children: [
            TextFormField(
              controller: controller, maxLines: 5, minLines: 3, maxLength: 5000, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), counterText: ""),
            ),
             Padding(padding: const EdgeInsets.only(right: 8.0, bottom: 8.0), child: Align(alignment: Alignment.bottomRight,
                  child: ListenableBuilder(listenable: controller, builder: (context, child) => Text('${controller.text.length}/5000', style: TextStyle(color: Colors.grey, fontSize: 12), textDirection: TextDirection.ltr)),),
            )
          ],
        ),
      ),
    ],);
  }
}


// Remove erroneous top-level function
// Future<void> _applySelectedLocationAddress() async {}
