// lib/presentation/screens/real_estate_ad_screen.dart

import 'dart:io';

import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/presentation/providers/real_estate_info_provider.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
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
import 'package:geocoding/geocoding.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class RealEstateAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const RealEstateAdScreen({Key? key, required this.onLanguageChange})
      : super(key: key);
  @override
  State<RealEstateAdScreen> createState() => _RealEstateAdScreenState();
}

class _RealEstateAdScreenState extends State<RealEstateAdScreen> {
  // --- Controllers & Keys ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController =
      TextEditingController(text: '');
  final TextEditingController _descriptionController =
      TextEditingController(text: '');
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // --- متغيرات الحالة لحفظ الاختيارات ---
  String? selectedEmirate;
  String? selectedDistrict;
  String? selectedContractType;
  String? selectedPropertyType;
  String? selectedAdvertiserName;
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;

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
      final storage = const FlutterSecureStorage();
      final authToken = await storage.read(key: 'auth_token');

      if (mounted) {
        // التحقق من بيانات البروفايل
        final authProvider = context.read<AuthProvider>();
        await _checkUserProfileData(authProvider);
        
        context.read<RealEstateInfoProvider>().fetchAllData(token: authToken);

        // محاولة تحويل العنوان النصي إلى إحداثيات وتحريك الخريطة إن لم تكن محددة
        if (selectedLocation.isNotEmpty && selectedLatLng == null) {
          try {
            final results = await locationFromAddress(selectedLocation);
            if (results.isNotEmpty) {
              final first = results.first;
              selectedLatLng = LatLng(first.latitude, first.longitude);
              final mapsProvider = context.read<GoogleMapsProvider>();
              await mapsProvider.moveCameraToLocation(first.latitude, first.longitude, zoom: 14.0);
              mapsProvider.addMarker(
                'selected_location',
                LatLng(first.latitude, first.longitude),
                title: 'الموقع المحدد',
                snippet: selectedLocation,
              );
            }
          } catch (e) {
            debugPrint('Geocoding failed: $e');
          }
        }
      }
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

    // تعيين موقع المستخدم المحفوظ إذا كان متوفراً وغير فارغ
    if (user.advertiserLocation != null && user.advertiserLocation!.trim().isNotEmpty) {
      setState(() {
        selectedLocation = user.advertiserLocation!;
      });
    }

    List<String> missingFields = [];

    // التحقق من الحقول المطلوبة
    if (user.phone.trim().isEmpty) {
      missingFields.add('phone number');
    }
    if ((user.advertiserLocation == null || user.advertiserLocation!.trim().isEmpty) &&
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
        return WillPopScope(
          onWillPop: () async {
            // عند الضغط على زر الرجوع، الخروج من الصفحة بالكامل
            Navigator.of(context).pop(); // إغلاق الـ dialog
            Navigator.of(context).pop(); // العودة إلى الشاشة السابقة
            return false;
          },
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Incomplete profile",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: KTextColor,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You must complete the following fields in your profile before adding the advertisement:',
                  style: TextStyle(
                    fontSize: 16,
                    color: KTextColor,
                  ),
                ),
                const SizedBox(height: 15),
                ...missingFields
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
                    context.push('/editprofile');
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
                  child: const Text(
                    'Go to Profile',
                    style: TextStyle(
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            
            
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    _priceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _mainImage = File(image.path));
  }

  Future<void> _pickThumbnailImages() async {
    const int maxTotalImages = 9;
    final int mainImageCount = _mainImage != null ? 1 : 0;
    final int remainingSlots = maxTotalImages - mainImageCount - _thumbnailImages.length;
    
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'You have already added the maximum of $maxTotalImages images (including main image).')));
      return;
    }
    
    // Allow user to select any number of images, but we'll take only what we need
    final List<XFile> pickedImages = await _picker.pickMultiImage(imageQuality: 85);
    
    if (pickedImages.isNotEmpty) {
      // Take only the number of images we can accommodate (up to remainingSlots)
      final List<XFile> imagesToAdd = pickedImages.take(remainingSlots).toList();
      
      setState(() {
        _thumbnailImages.addAll(imagesToAdd.map((img) => File(img.path)));
      });
      
      // Show message if user selected more images than we could add
      if (pickedImages.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'You selected ${pickedImages.length} images, but only the first $remainingSlots were added to reach the maximum of $maxTotalImages images.'
          ),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  void _removeThumbnailImage(int index) {
    setState(() => _thumbnailImages.removeAt(index));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.orange));
      return;
    }
    if (_mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please add a main image.'),
          backgroundColor: Colors.orange));
      return;
    }
    if (selectedLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a location on the map.'),
          backgroundColor: Colors.orange));
      return;
    }
    if (selectedPhoneNumber == null || selectedPhoneNumber!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a phone number.'),
          backgroundColor: Colors.orange));
      return;
    }

    final infoProvider = context.read<RealEstateInfoProvider>();
    final adData = {
      'adType': 'real_estate',
      'title': _titleController.text,
      'description': _descriptionController.text,
      'emirate': infoProvider.getEmirateNameFromDisplayName(selectedEmirate),
      'district': selectedDistrict,
      'area': _areaController.text,
      'price': _priceController.text,
      'contract_type': selectedContractType,
      'property_type': selectedPropertyType,
      'advertiser_name': selectedAdvertiserName,
      'phone_number': PhoneNumberFormatter.formatForApi(selectedPhoneNumber!),
      'whatsapp_number':
          selectedWhatsAppNumber != null && selectedWhatsAppNumber!.isNotEmpty
              ? PhoneNumberFormatter.formatForApi(selectedWhatsAppNumber!)
              : null,
      'address': selectedLocation, // Address from map
      'mainImage': _mainImage,
      'thumbnailImages': _thumbnailImages,
    };

    context.push('/placeAnAd', extra: adData);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<RealEstateInfoProvider>(
        builder: (context, infoProvider, child) {
          if (infoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (infoProvider.error != null) {
            return Center(child: Text('Error: ${infoProvider.error}'));
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
                        child: Text(s.realEstateAds,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 24.sp,
                                color: KTextColor))),
                    SizedBox(height: 10.h),
                    _buildFormRow([
                      _buildSingleSelectField(
                          context,
                          s.emirate,
                          selectedEmirate,
                          infoProvider.emirateDisplayNames,
                          (selection) => setState(() {
                                selectedEmirate = selection;
                                selectedDistrict = null;
                              }),
                          isRequired: true),
                      _buildSingleSelectField(
                          context,
                          s.district,
                          selectedDistrict,
                          infoProvider.getDistrictsForEmirate(selectedEmirate),
                          (selection) =>
                              setState(() => selectedDistrict = selection),
                          isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildTitledTextFormField(
                          s.area, _areaController, borderColor, currentLocale,
                          isRequired: true, hintText: 'area'),
                      _buildTitledTextFormField(
                          s.price, _priceController, borderColor, currentLocale,
                          hintText: '120,000',
                          isNumber: true,
                          isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildSingleSelectField(
                          context,
                          s.contractType,
                          selectedContractType,
                          infoProvider.contractTypes,
                          (selection) =>
                              setState(() => selectedContractType = selection),
                          isRequired: true),
                      _buildSingleSelectField(
                          context,
                          s.propertyType,
                          selectedPropertyType,
                          infoProvider.propertyTypes,
                          (selection) =>
                              setState(() => selectedPropertyType = selection),
                          isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildTitledTextFormField(
                        s.title, _titleController, borderColor, currentLocale,
                          minLines: 3, maxLines: 4, isRequired: true, hintText: 'enter your title'),
                    const SizedBox(height: 7),
                    TitledSelectOrAddField(
                        title: s.advertiserName,
                        value: selectedAdvertiserName,
                        items: infoProvider.advertiserNames,
                        onChanged: (newValue) =>
                            setState(() => selectedAdvertiserName = newValue),
                        onAddNew: (value) async {
                          final token = await const FlutterSecureStorage()
                              .read(key: 'auth_token');
                          if (token != null) {
                            final success = await infoProvider.addContactItem(
                                'advertiser_names', value,
                                token: token);
                            if (success && mounted)
                              setState(() => selectedAdvertiserName = value);
                          }
                        }),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      TitledSelectOrAddField(
                          title: s.phoneNumber,
                          value: selectedPhoneNumber,
                          items: infoProvider.phoneNumbers,
                          onChanged: (newValue) =>
                              setState(() => selectedPhoneNumber = newValue),
                          isNumeric: true,
                          onAddNew: (value) async {
                            final storage = const FlutterSecureStorage();
                            final token = await storage.read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem(
                                  'phone_numbers', value,
                                  token: token);
                              if (success && mounted)
                                setState(() => selectedPhoneNumber = value);
                            }
                          }),
                      TitledSelectOrAddField(
                          title: s.whatsApp,
                          value: selectedWhatsAppNumber,
                          items: infoProvider.whatsappNumbers,
                          onChanged: (newValue) =>
                              setState(() => selectedWhatsAppNumber = newValue),
                          isNumeric: true,
                          onAddNew: (value) async {
                            final storage = const FlutterSecureStorage();
                            final token = await storage.read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem(
                                  'whatsapp_numbers', value,
                                  token: token);
                              if (success && mounted)
                                setState(() => selectedWhatsAppNumber = value);
                            }
                          }),
                    ]),
                    const SizedBox(height: 7),
                    TitledDescriptionBox(
                        title: s.description,
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
                        '${s.add9Images} (${(_thumbnailImages.length)}/9)',
                        Icons.add_photo_alternate_outlined,
                        borderColor,
                        onPressed: _pickThumbnailImages),
                    if (_thumbnailImages.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                          onTap: () =>
                                              _removeThumbnailImage(idx),
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  shape: BoxShape.circle),
                                              child: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 16))))
                                ]);
                              }).toList())),
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
                                      : "noLocationSelected",
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))))),
                    const SizedBox(height: 20)
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
      int? maxLines}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLines != null && maxLines > 1 ? 100 : null,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: (value) {
            if (maxWords != null || maxLines != null) {
              final lines = value.split('\n');
              final words = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

              // Check if exceeds max lines
              if (maxLines != null && lines.length > maxLines) {
                final truncatedLines = lines.take(maxLines).join('\n');
                controller.value = controller.value.copyWith(
                  text: truncatedLines,
                  selection: TextSelection.collapsed(offset: truncatedLines.length),
                );
                return;
              }

              // Check if exceeds max words
              if (maxWords != null && words > maxWords) {
                final wordsList = value.trim().split(RegExp(r'\s+'));
                final truncatedText = wordsList.take(maxWords).join(' ');
                controller.value = controller.value.copyWith(
                  text: truncatedText,
                  selection: TextSelection.collapsed(offset: truncatedText.length),
                );
                return;
              }
            }
          },
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            if (maxWords != null) {
              final words = value?.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length ?? 0;
              if (words > maxWords) {
                return 'Maximum $maxWords words allowed';
              }
            }
            if (maxLines != null) {
              final lines = value?.split('\n').length ?? 0;
              if (lines > maxLines) {
                return 'Maximum $maxLines lines allowed';
              }
            }
            return null;
          },
          decoration: InputDecoration(
              hintText: hintText,
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
              counterText: "",
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
      {bool isRequired = false, double? titleFontSize}) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: KTextColor,
              fontSize: titleFontSize ?? 14.sp)),
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
                  onTap: allItems.isEmpty
                      ? null
                      : () async {
                          final result = await _showSingleSelectPicker(context,
                              title: title, items: allItems);
                          onConfirm(result);
                          state.didChange(result);
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
                    child: Text(selectedValue ?? s.chooseAnOption,
                        style: TextStyle(
                            fontWeight: selectedValue == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                            color: selectedValue == null
                                ? Colors.grey.shade500
                                : KTextColor,
                            fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
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
            _SingleSelectBottomSheet(title: title, items: items));
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
                              target: selectedLatLng ??
                                  const LatLng(25.2048, 55.2708),
                              zoom: 12.0),
                          onMapCreated: mapsProvider.onMapCreated,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          onTap: (pos) async {
                            final address =
                                await mapsProvider.getAddressFromCoordinates(
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
                                      markerId:
                                          const MarkerId('selected_location'),
                                      position: selectedLatLng!)
                                },
                          gestureRecognizers: <Factory<
                              OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer())
                          })),
              Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Row(children: [
                    Expanded(
                        child: ElevatedButton(
                            onPressed:
                                _isLoadingLocation ? null : _getCurrentLocation,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _isLoadingLocation
                                    ? Colors.grey
                                    : KPrimaryColor,
                                minimumSize: const Size(double.infinity, 43),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)))
                                : const Text('Locate Me',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: _navigateToLocationPicker,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF01547E),
                                minimumSize: const Size(double.infinity, 43),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: const Text('Pick Location',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.5)))),
                  ])),
            ])));
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
                maxLength: 15000,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: KTextColor,
                    fontSize: 14.sp),
                decoration: const InputDecoration(
                    hintText: 'enter your description',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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
                            '${controller.text.length}/15000',
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
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _SearchableSelectOrAddBottomSheet(
                  title: title,
                  items: items,
                  isNumeric: isNumeric,
                  onAddNew: onAddNew));
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
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(
                    value ?? s.chooseAnOption,
                    style: TextStyle(
                        fontWeight:
                            value == null ? FontWeight.normal : FontWeight.w500,
                        color:
                            value == null ? Colors.grey.shade500 : KTextColor,
                        fontSize: 12.sp),
                    overflow: TextOverflow.ellipsis,
                  ))
                ])),
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        isExpanded: true)),
                const SizedBox(width: 8)
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
                      minimumSize: const Size(60, 48)))
            ])
          ]),
        ));
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
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7),
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
                          borderSide: const BorderSide(
                              color: KPrimaryColor, width: 2)))),
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
            ])));
  }
}
