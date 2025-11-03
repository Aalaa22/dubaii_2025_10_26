// lib/presentation/screens/cars_rent_ad_screen.dart

import 'dart:io';
import 'package:advertising_app/presentation/providers/car_rent_info_provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class CarsRentAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const CarsRentAdScreen({Key? key, required this.onLanguageChange})
      : super(key: key);
  @override
  State<CarsRentAdScreen> createState() => _CarsRentAdScreenState();
}

class _CarsRentAdScreenState extends State<CarsRentAdScreen> {
  // --- Controllers and Keys ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController =
      TextEditingController(text: ''); // Default text
  final TextEditingController _descriptionController =
      TextEditingController(text: ''); // Default text
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dayRentController = TextEditingController();
  final TextEditingController _monthRentController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  // --- متغيرات الحالة لحفظ الاختيارات ---
  String? selectedEmirate;
  String? selectedMake;
  String? selectedModel;
  String? selectedTrim;
  final TextEditingController yearController = TextEditingController();
  String? selectedCarType;
  String? selectedTransType;
  String? selectedFuelType;
  String? selectedColor;
  String? selectedInteriorColor;
  String? selectedSeats;
  String? selectedAdvertiserName;
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;
  String? selectedAdvertiserLocation;

  // --- متغيرات الصور والموقع ---
  File? _mainImage;
  final List<File> _thumbnailImages = [];
  final ImagePicker _picker = ImagePicker();
  String selectedLocation = '';
  LatLng? selectedLatLng;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token != null && mounted) {
        context.read<CarRentInfoProvider>().fetchAllData(token: token);

        // التحقق من بيانات البروفايل
        final authProvider = context.read<AuthProvider>();
        await _checkUserProfileData(authProvider);

        // تطبيق العنوان المختار لتحريك الخريطة عند فتح الصفحة
        await _applySelectedLocationAddress();
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _dayRentController.dispose();
    _monthRentController.dispose();
    _areaController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    yearController.dispose();
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

  Future<void> _pickMainImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _mainImage = File(image.path));
  }

  Future<void> _pickThumbnailImages() async {
    const int maxImages = 10;
    final int remainingSlots = maxImages - _thumbnailImages.length;
    if (remainingSlots <= 0) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic ? 'لقد وصلت للحد الأقصى وهو $maxImages صور' : 'You have reached the maximum of $maxImages images'),
        backgroundColor: KPrimaryColor,
      ));
      return;
    }

    try {
      final List<XFile> pickedImages =
          await _picker.pickMultiImage(imageQuality: 85, limit: remainingSlots);

      if (pickedImages.isNotEmpty) {
        // التأكد من عدم تجاوز الحد الأقصى
        final int totalAfterAdding =
            _thumbnailImages.length + pickedImages.length;
        if (totalAfterAdding > maxImages) {
          final int allowedCount = maxImages - _thumbnailImages.length ;
          final List<XFile> allowedImages =
              pickedImages.take(allowedCount).toList();
          setState(() => _thumbnailImages
              .addAll(allowedImages.map((img) => File(img.path))));
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                isArabic ? 'تم إضافة $allowedCount صور فقط. الحد الأقصى هو $maxImages صور' : 'Added only $allowedCount images. Maximum is $maxImages images'),
            backgroundColor: KPrimaryColor,
          ));
        } else {
          setState(() => _thumbnailImages
              .addAll(pickedImages.map((img) => File(img.path))));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم إضافة ${pickedImages.length} صور بنجاح'),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حدث خطأ أثناء اختيار الصور: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _removeThumbnailImage(int index) {
    setState(() => _thumbnailImages.removeAt(index));
  }

  // دالة للتحقق من بيانات البروفايل المطلوبة
  Future<void> _checkUserProfileData(AuthProvider authProvider) async {
    // جلب بيانات المستخدم إذا لم تكن متاحة
    if (authProvider.user == null) {
      await authProvider.fetchUserProfile();
    }

    final user = authProvider.user;
    if (user == null) return;

    // تعيين موقع المستخدم المحفوظ إذا كان متوفراً وغير فارغ
    if (user.advertiserLocation != null &&
        user.advertiserLocation!.trim().isNotEmpty) {
      setState(() {
        selectedLocation = user.advertiserLocation!;
      });
    }

    List<String> missingFields = [];

    // التحقق من الحقول المطلوبة
    if (user.phone.trim().isEmpty) {
      missingFields.add('phone number');
    }
    if ((user.advertiserLocation == null ||
            user.advertiserLocation!.trim().isEmpty) &&
        (user.latitude == null || user.longitude == null)) {
      missingFields.add('your location');
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
          switch (field.trim().toLowerCase()) {
            case 'phone number':
              return s.phone;
            case 'your location':
              return s.advertiserLocation;
            default:
              return field;
          }
        }).toList();

        final String description = isArabic
            ? 'يجب عليك إكمال الحقول التالية في ملفك الشخصي قبل إضافة الإعلان:'
            : 'You must complete the following fields in your profile before adding the advertisement:';

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
            title: Text(
              s.editprof4,
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
                  description,
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Locating...'), backgroundColor: KPrimaryColor));
    try {
      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();
      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        await mapsProvider.moveCameraToLocation(
            latLng.latitude, latLng.longitude,
            zoom: 16.0);
        final address = await mapsProvider.getAddressFromCoordinates(
            latLng.latitude, latLng.longitude);
        setState(() {
          selectedLatLng = latLng;
          if (address != null) selectedLocation = address;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location found'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _navigateToLocationPicker() async {
    try {
      final result = await context
          .push('/location_picker', extra: {'initialLatLng': selectedLatLng});
      if (result != null && result is Map<String, dynamic>) {
        final LatLng? location = result['location'] as LatLng?;
        final String? address = result['address'] as String?;
        if (location != null) {
          setState(() {
            selectedLatLng = location;
            if (address != null) selectedLocation = address;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error picking location: $e'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _validateAndProceedToNext() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
          content: Text(S.of(context).please_fill_required_fields),
          backgroundColor: Color.fromRGBO(1, 84, 126, 1)));
      return;
    }

    // Additional validation for required fields
    List<String> missingFields = [];
    if (selectedCarType == null || selectedCarType!.isEmpty)
      missingFields.add('Car Type');
    if (selectedTransType == null || selectedTransType!.isEmpty)
      missingFields.add('Transmission Type');
    if (selectedFuelType == null || selectedFuelType!.isEmpty)
      missingFields.add('Fuel Type');
    if (selectedColor == null || selectedColor!.isEmpty)
      missingFields.add('Color');
    if (selectedInteriorColor == null || selectedInteriorColor!.isEmpty)
      missingFields.add('Interior Color');
    if (selectedSeats == null || selectedSeats!.isEmpty)
      missingFields.add('Seats Number');

    if (missingFields.isNotEmpty) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'الرجاء اختيار: ${missingFields.join(', ')}' : 'Please select: ${missingFields.join(', ')}'),
          backgroundColor: KPrimaryColor,
        ),
      );
      return;
    }

    if (_mainImage == null) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'الرجاء إضافة صورة رئيسية.' : 'Please add a main image.'),
          backgroundColor: KPrimaryColor));
      return;
    }
    if (selectedLocation.isEmpty) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'الرجاء تحديد موقع على الخريطة.' : 'Please select a location on the map.'),
          backgroundColor: KPrimaryColor));
      return;
    }

    final infoProvider = context.read<CarRentInfoProvider>();
    final adData = {
      'adType': 'car_rent',
      'emirate': infoProvider.getEmirateNameFromDisplayName(selectedEmirate),
      'make': selectedMake,
      'model': selectedModel,
      'trim': selectedTrim,
      'price': _priceController.text,
      'year': yearController.text,
      'day_rent': _dayRentController.text,
      'month_rent': _monthRentController.text,
      'title': _titleController.text,
      'car_type': selectedCarType,
      'trans_type': selectedTransType ?? '', // Ensure trans_type is never null
      'fuel_type': selectedFuelType,
      'color': selectedColor,
      'interior_color': selectedInteriorColor,
      'seats_no': selectedSeats,
      'area': _areaController.text,
      'phone_number': PhoneNumberFormatter.formatForApi(selectedPhoneNumber!),
      'whatsapp':
          selectedWhatsAppNumber != null && selectedWhatsAppNumber!.isNotEmpty
              ? PhoneNumberFormatter.formatForApi(selectedWhatsAppNumber!)
              : null,
      'advertiser_name': selectedAdvertiserName,
      'advertiser_location': selectedAdvertiserLocation,
      'description': _descriptionController.text,
      'location': selectedLocation,
      'mainImage': _mainImage,
      'thumbnailImages': _thumbnailImages,
    };

    print('=== Car Rent Ad Data Prepared ===');
    print('Ad Type: ${adData['adType']}');
    print('Emirate: ${adData['emirate']}');
    print('Make: ${adData['make']}');
    print('Model: ${adData['model']}');
    print('Trim: ${adData['trim']}');
    print('Price: ${adData['price']}');
    print('Year: ${adData['year']}');
    print('Day Rent: ${adData['day_rent']}');
    print('Month Rent: ${adData['month_rent']}');
    print('Title: ${adData['title']}');
    print('Car Type: ${adData['car_type']}');
    print('Trans Type: ${adData['trans_type']}');
    print('Fuel Type: ${adData['fuel_type']}');
    print('Color: ${adData['color']}');
    print('Interior Color: ${adData['interior_color']}');
    print('Seats No: ${adData['seats_no']}');
    print('Area: ${adData['area']}');
    print('Phone Number: ${adData['phone_number']}');
    print('WhatsApp: ${adData['whatsapp']}');
    print('Advertiser Name: ${adData['advertiser_name']}');
    print('Description: ${adData['description']}');
    print('Location: ${adData['location']}');
    print(
        'Main Image: ${adData['mainImage'] != null ? 'File provided' : 'No file'}');
    print(
        'Thumbnail Images: ${(adData['thumbnailImages'] as List?)?.length ?? 0} images');
    print('=== End Car Rent Ad Data ===');

    context.push('/placeAnAd', extra: adData);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<CarRentInfoProvider>(
        builder: (context, infoProvider, child) {
          if (infoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (infoProvider.error != null) {
            return Center(child: Text("Error: ${infoProvider.error}"));
          }
          return SingleChildScrollView(
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
                          Icon(Icons.arrow_back_ios,
                              color: KTextColor, size: 20.sp),
                          Transform.translate(
                              offset: Offset(-3.w, 0),
                              child: Text(s.back,
                                  style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                      color: KTextColor)))
                        ])),
                    SizedBox(height: 7.h),
                    Center(
                        child: Text(s.carsRentAds,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 24.sp,
                                color: KTextColor))),
                    SizedBox(height: 15.h),
                    _buildFormRow([
                      _buildSingleSelectField(
                          context,
                          s.emirate,
                          selectedEmirate,
                          infoProvider.emirateDisplayNames,
                          (selection) =>
                              setState(() => selectedEmirate = selection),
                          isRequired: true),
                      _buildSingleSelectField(context, s.make, selectedMake,
                          infoProvider.makeNamesForAds, (selection) async {
                        setState(() {
                          selectedMake = selection;
                          selectedModel = null;
                          selectedTrim = null;
                        });
                        if (selection != null) {
                          if (selection == 'Other') {
                            // عند اختيار Other في make، نقوم بمسح الـ models والـ trims ونضع قائمة فارغة
                            infoProvider.clearModelsAndTrims();
                          } else {
                            try {
                              final makeObject = infoProvider.makes
                                  .firstWhere((m) => m.name == selection);
                              await infoProvider.fetchModelsForMake(makeObject);
                            } catch (e) {
                              debugPrint(
                                  "Make object not found for $selection");
                            }
                          }
                        }
                      }, isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildSingleSelectField(
                          context,
                          s.model,
                          selectedModel,
                          selectedMake == 'Other'
                              ? ['Other']
                              : infoProvider.modelNamesForAds,
                          (selection) async {
                        setState(() {
                          selectedModel = selection;
                          selectedTrim = null;
                        });
                        if (selection != null && selectedMake != 'Other') {
                          try {
                            final modelObject = infoProvider.models
                                .firstWhere((m) => m.name == selection);
                            await infoProvider.fetchTrimsForModel(modelObject);
                          } catch (e) {
                            debugPrint("Model object not found for $selection");
                          }
                        }
                      },
                      isLoading: infoProvider.isLoadingModels),
                      _buildSingleSelectField(
                          context,
                          s.trim,
                          selectedTrim,
                          (selectedMake == 'Other' || selectedModel == 'Other')
                              ? ['Other']
                              : infoProvider.trimNames,
                          (selection) =>
                              setState(() => selectedTrim = selection),
                          isLoading: infoProvider.isLoadingTrims),
                      _buildTitledTextFormField(
                          s.year, yearController, borderColor, currentLocale,
                          hintText: '2020', isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildTitledTextFormField(
                          s.price, _priceController, borderColor, currentLocale,
                          hintText: s.totalPrice,
                          isNumber: true,
                          isRequired: true),
                      _buildTitledTextFormField(s.dayRent, _dayRentController,
                          borderColor, currentLocale,
                          hintText: '600', isNumber: true, isRequired: true),
                      _buildTitledTextFormField(s.monthRent,
                          _monthRentController, borderColor, currentLocale,
                          hintText: '12000', isNumber: true, isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildTitledTextFormField(
                        s.title, _titleController, borderColor, currentLocale,
                        hintText: null,
                        isRequired: true,
                        minLines: 3,
                        maxLines: 4),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildSingleSelectField(
                          context,
                          s.carType,
                          selectedCarType,
                          infoProvider.carTypes,
                          (selection) =>
                              setState(() => selectedCarType = selection)),
                      _buildSingleSelectField(
                          context,
                          s.transType,
                          selectedTransType,
                          infoProvider.transmissionTypes,
                          (selection) =>
                              setState(() => selectedTransType = selection)),
                      _buildSingleSelectField(
                          context,
                          s.fuelType,
                          selectedFuelType,
                          infoProvider.fuelTypes,
                          (selection) =>
                              setState(() => selectedFuelType = selection)),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildSingleSelectField(
                          context,
                          s.color,
                          selectedColor,
                          infoProvider.colors,
                          (selection) =>
                              setState(() => selectedColor = selection)),
                      _buildSingleSelectField(
                          context,
                          s.interiorColor,
                          selectedInteriorColor,
                          infoProvider.interiorColors,
                          (selection) => setState(
                              () => selectedInteriorColor = selection)),
                      _buildSingleSelectField(
                          context,
                          s.seatsNo,
                          selectedSeats,
                          infoProvider.seatNumbers,
                          (selection) =>
                              setState(() => selectedSeats = selection),
                          isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildTitledTextFormField(
                        s.area, _areaController, borderColor, currentLocale,
                        hintText: s.areaName, isRequired: true),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      TitledSelectOrAddField(
                          title: s.phoneNumber,
                          value: selectedPhoneNumber,
                          items: infoProvider.phoneNumbers,
                          onChanged: (newValue) =>
                              setState(() => selectedPhoneNumber = newValue),
                          isNumeric: true,
                          onAddNew: (newValue) async {
                            final token = await const FlutterSecureStorage()
                                .read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem(
                                  'phone_numbers', newValue,
                                  token: token);
                              if (success && mounted)
                                setState(() => selectedPhoneNumber = newValue);
                            }
                          }),
                      TitledSelectOrAddField(
                          title: s.whatsApp,
                          value: selectedWhatsAppNumber,
                          items: infoProvider.whatsappNumbers,
                          onChanged: (newValue) =>
                              setState(() => selectedWhatsAppNumber = newValue),
                          isNumeric: true,
                          onAddNew: (newValue) async {
                            final token = await const FlutterSecureStorage()
                                .read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem(
                                  'whatsapp_numbers', newValue,
                                  token: token);
                              if (success && mounted)
                                setState(
                                    () => selectedWhatsAppNumber = newValue);
                            }
                          }),
                    ]),
                    const SizedBox(height: 7),
                    TitledSelectOrAddField(
                        title: s.advertiserName,
                        value: selectedAdvertiserName,
                        items: infoProvider.advertiserNames,
                        onChanged: (newValue) =>
                            setState(() => selectedAdvertiserName = newValue),
                        onAddNew: (newValue) async {
                          final token = await const FlutterSecureStorage()
                              .read(key: 'auth_token');
                          if (token != null) {
                            final success = await infoProvider.addContactItem(
                                'advertiser_names', newValue,
                                token: token);
                            if (success && mounted)
                              setState(() => selectedAdvertiserName = newValue);
                          }
                        }),
                    const SizedBox(height: 7),
                    // TitledSelectOrAddField(
                    //   title: s.advertiserLocation, value: selectedAdvertiserLocation, items: infoProvider.advertiserLocations,
                    //   onChanged: (newValue) => setState(() => selectedAdvertiserLocation = newValue),
                    //    onAddNew: (newValue) async {
                    //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
                    //       if(token != null) {
                    //           final success = await infoProvider.addContactItem('advertiser_locations', newValue, token: token);
                    //           if(success && mounted) setState(() => selectedAdvertiserLocation = newValue);
                    //       }
                    //    }
                    // ),
                    // const SizedBox(height: 7),
                    TitledDescriptionBox(
                        title: s.describeYourCar,
                        controller: _descriptionController,
                        borderColor: borderColor),
                    const SizedBox(height: 10),
                    _buildImageButton(
                        s.addMainImage, Icons.add_a_photo_outlined, borderColor,
                        onPressed: _pickMainImage),
                    if (_mainImage != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_mainImage!,
                                      height: 150, fit: BoxFit.cover)))),
                    const SizedBox(height: 7),
                    _buildImageButton(
                        '(${_thumbnailImages.length}/10)',
                        Icons.add_photo_alternate_outlined,
                        borderColor,
                        onPressed: _pickThumbnailImages),
                    if (_thumbnailImages.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _thumbnailImages.asMap().entries.map((entry) {
                              int idx = entry.key;
                              File img = entry.value;
                              return Stack(children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(img,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover)),
                                Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                        onTap: () => _removeThumbnailImage(idx),
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.close,
                                                color: Colors.white,
                                                size: 16))))
                              ]);
                            }).toList(),
                          )),
                    const SizedBox(height: 7),
                    Text(s.location,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: KTextColor)),
                    SizedBox(height: 4.h),
                    Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(children: [
                          SvgPicture.asset('assets/icons/locationicon.svg',
                              width: 20.w, height: 20.h),
                          SizedBox(width: 8.w),
                          Expanded(
                              child: Text(
                                  selectedLocation.isNotEmpty
                                      ? selectedLocation
                                      : s.advertiserLocation,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: KTextColor,
                                      fontWeight: FontWeight.w500)))
                        ])),
                    SizedBox(height: 8.h),
                    _buildMapSection(context),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _validateAndProceedToNext,
                        child: Text(s.next,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: KPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormRow(List<Widget> children) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((child) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: child)))
            .toList());
  }

  Widget _buildTitledTextFormField(String title,
      TextEditingController controller, Color borderColor, String currentLocale,
      {bool isNumber = false,
      String? hintText,
      int minLines = 1,
      bool isRequired = false,
      int? maxWords,
      int? maxLines,
      int? maxLength}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines ?? (minLines > 1 ? minLines + 2 : 1),
          maxLength: (maxLines != null && maxLines > 1) ? 100 : null,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: title == S.of(context).title && maxLines == 2
              ? [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    // Count the number of lines in the new value
                    int lineCount = newValue.text.split('\n').length;
                    if (lineCount > 2) {
                      // If more than 2 lines, return the old value (prevent the input)
                      return oldValue;
                    }
                    return newValue;
                  })
                ]
              : null,
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            // Character count limit aligned with car sales screen
            if ((maxLines != null && maxLines > 1) && value != null && value.length > 100) {
              return 'Maximum 100 characters allowed';
            }
            if (maxWords != null && value != null) {
              int wordCount = value
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((word) => word.isNotEmpty)
                  .length;
              if (wordCount > maxWords) {
                return 'Maximum $maxWords words allowed';
              }
            }
            if (maxLines != null && value != null) {
              int lineCount = value.split('\n').length;
              if (lineCount > maxLines) {
                return 'Maximum $maxLines lines allowed';
              }
            }
            return null;
          },
          decoration: InputDecoration(
              counterText: "",
              hintText: hintText,
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: KPrimaryColor, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.white,
              filled: true))
    ]);
  }

  Widget _buildSingleSelectField(BuildContext context, String title,
      String? selectedValue, List<String> allItems, Function(String?) onConfirm,
      {bool isRequired = false, bool isLoading = false}) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      FormField<String>(
        validator: isRequired
            ? (value) {
                if (selectedValue == null) return 'Required';
                return null;
              }
            : null,
        builder: (FormFieldState<String> state) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: (allItems.isEmpty || isLoading)
                      ? null
                      : () async {
                          final result = await _showSingleSelectPicker(context,
                              title: title, items: allItems);
                          if (result != null) {
                            onConfirm(result);
                            state.didChange(result);
                          } else {
                            onConfirm(null);
                            state.didChange(null);
                          }
                        },
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                        color: allItems.isEmpty
                            ? Colors.grey.shade200
                            : Colors.white,
                        border: Border.all(
                            color: state.hasError ? Colors.red : borderColor),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedValue ?? s.chooseAnOption,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: selectedValue == null
                                    ? Colors.grey.shade500
                                    : KTextColor,
                                fontSize: 12.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLoading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                      padding: const EdgeInsets.only(top: 5, left: 10),
                      child: Text(state.errorText!,
                          style:
                              TextStyle(color: Colors.red, fontSize: 10.sp))),
              ]);
        },
      ),
    ]);
  }

  Future<String?> _showSingleSelectPicker(BuildContext context,
      {required String title, required List<String> items}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) =>
          _SingleSelectBottomSheet(title: title, items: items),
    );
  }

  Widget _buildImageButton(String title, IconData icon, Color borderColor,
      {required VoidCallback onPressed}) {
    return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
            icon: Icon(icon, color: KTextColor),
            label: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: KTextColor,
                    fontSize: 16.sp)),
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)))));
  }

  Widget _buildMapSection(BuildContext context) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(children: [
          Consumer<GoogleMapsProvider>(
            builder: (context, mapsProvider, child) => GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: selectedLatLng ?? const LatLng(25.2048, 55.2708),
                  zoom: 12.0),
              onMapCreated: mapsProvider.onMapCreated,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onTap: (pos) async {
                final address = await mapsProvider.getAddressFromCoordinates(
                    pos.latitude, pos.longitude);
                setState(() {
                  selectedLatLng = pos;
                  if (address != null) selectedLocation = address;
                });
              },
              markers: selectedLatLng == null
                  ? {}
                  : {
                      Marker(
                          markerId: const MarkerId('selected_location'),
                          position: selectedLatLng!)
                    },
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer())
              },
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(children: [
              Expanded(
                  child: ElevatedButton(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isLoadingLocation ? Colors.grey : KPrimaryColor,
                  minimumSize: const Size(double.infinity, 43),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)))
                    :  Text(S.of(context).locateMe,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton(
                onPressed: _navigateToLocationPicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01547E),
                  minimumSize: const Size(double.infinity, 43),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(S.of(context).pickLocation,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class TitledDescriptionBox extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final Color borderColor;
  const TitledDescriptionBox(
      {Key? key,
      required this.title,
      required this.controller,
      required this.borderColor})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor)),
          child: Column(children: [
            TextFormField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                maxLength: 5000,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: KTextColor,
                    fontSize: 14.sp),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    counterText: "")),
            Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: ListenableBuilder(
                        listenable: controller,
                        builder: (context, child) => Text(
                            '${controller.text.length}/5000',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            textDirection: TextDirection.ltr))))
          ]))
    ]);
  }
}

class TitledSelectOrAddField extends StatelessWidget {
  final String title;
  final String? value;
  final List<String> items;
  final Function(String) onChanged;
  final bool isNumeric;
  final Function(String)? onAddNew;
  const TitledSelectOrAddField(
      {Key? key,
      required this.title,
      required this.value,
      required this.items,
      required this.onChanged,
      this.isNumeric = false,
      this.onAddNew})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: Colors.white,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _SearchableSelectOrAddBottomSheet(
                title: title,
                items: items,
                isNumeric: isNumeric,
                onAddNew: onAddNew),
          );
          if (result != null && result.isNotEmpty) {
            onChanged(result);
          }
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
                child: Text(
              value ?? s.chooseAnOption,
              style: TextStyle(
                  fontWeight:
                      value == null ? FontWeight.normal : FontWeight.w500,
                  color: value == null ? Colors.grey.shade500 : KTextColor,
                  fontSize: 12.sp),
              overflow: TextOverflow.ellipsis,
            ))
          ]),
        ),
      )
    ]);
  }
}

class _SearchableSelectOrAddBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final bool isNumeric;
  final Function(String)? onAddNew;
  const _SearchableSelectOrAddBottomSheet(
      {required this.title,
      required this.items,
      this.isNumeric = false,
      this.onAddNew});
  @override
  _SearchableSelectOrAddBottomSheetState createState() =>
      _SearchableSelectOrAddBottomSheetState();
}

class _SearchableSelectOrAddBottomSheetState
    extends State<_SearchableSelectOrAddBottomSheet> {
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredItems =
        widget.items.where((i) => i.toLowerCase().contains(query)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: KTextColor)),
          const SizedBox(height: 16),
          TextFormField(
              controller: _searchController,
              style: const TextStyle(color: KTextColor),
              decoration: InputDecoration(
                  hintText: s.search,
                  prefixIcon: const Icon(Icons.search, color: KTextColor),
                  hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: KPrimaryColor, width: 2)))),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(s.noResultsFound,
                        style: const TextStyle(color: KTextColor)))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                          title: Text(item,
                              style: const TextStyle(color: KTextColor)),
                          onTap: () => Navigator.pop(context, item));
                    },
                  ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isNumeric) ...[
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                      value: _selectedCountryCode,
                      items: _countryCodes.entries
                          .map((entry) => DropdownMenuItem<String>(
                              value: entry.value,
                              child: Text(entry.value,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: KTextColor,
                                      fontSize: 12.sp))))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCountryCode = value!),
                      decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: KPrimaryColor, width: 2))),
                      isDense: true,
                      isExpanded: true),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                  child: TextFormField(
                      controller: _addController,
                      keyboardType: widget.isNumeric
                          ? TextInputType.number
                          : TextInputType.text,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: KTextColor,
                          fontSize: 12.sp),
                      decoration: InputDecoration(
                          hintText: widget.isNumeric ? s.phoneNumber : s.addNew,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: KPrimaryColor, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12)))),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () async {
                    String result = _addController.text.trim();
                    if (widget.isNumeric && result.isNotEmpty)
                      result = '$_selectedCountryCode$result';
                    if (result.isNotEmpty) {
                      if (widget.onAddNew != null)
                        await widget.onAddNew!(result);
                      Navigator.pop(context, result);
                    }
                  },
                  child: Text(s.add,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KPrimaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      minimumSize: const Size(60, 48))),
            ],
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _SingleSelectBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  const _SingleSelectBottomSheet({required this.title, required this.items});
  @override
  _SingleSelectBottomSheetState createState() =>
      _SingleSelectBottomSheetState();
}

class _SingleSelectBottomSheetState extends State<_SingleSelectBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredItems = widget.items
        .where((item) => item.toLowerCase().contains(query))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: KTextColor)),
          const SizedBox(height: 16),
          TextFormField(
              controller: _searchController,
              style: const TextStyle(color: KTextColor),
              decoration: InputDecoration(
                  hintText: s.search,
                  prefixIcon: const Icon(Icons.search, color: KTextColor),
                  hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: KPrimaryColor, width: 2)))),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(s.noResultsFound,
                          style: const TextStyle(color: KTextColor)))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                            title: Text(item,
                                style: const TextStyle(color: KTextColor)),
                            onTap: () => Navigator.pop(context, item));
                      })),
          const SizedBox(height: 16)
        ]),
      ),
    );
  }
}