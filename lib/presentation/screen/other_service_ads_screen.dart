// lib/presentation/screens/other_services_ad_screen.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:advertising_app/presentation/providers/other_services_info_provider.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:geocoding/geocoding.dart';

// تعريف الثوابت
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class OtherServicesAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const OtherServicesAdScreen({Key? key, required this.onLanguageChange})
      : super(key: key);
  @override
  State<OtherServicesAdScreen> createState() => _OtherServicesAdScreenState();
}

class _OtherServicesAdScreenState extends State<OtherServicesAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _serviceNameController = TextEditingController();

  String? selectedEmirate;
  String? selectedDistrict;
  String? selectedSectionType;
  String? selectedAdvertiserName;
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;

  XFile? _mainImage;
  Uint8List? _mainImageBytes;
  final ImagePicker _picker = ImagePicker();
  String selectedLocation = '';
  LatLng? selectedLatLng;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      context.read<OtherServicesInfoProvider>().fetchAllData(token: token);
      // After fetching, check user profile to set default location from contact info and show alert if needed
      final authProvider = context.read<AuthProvider>();
      await _checkUserProfileData(authProvider);
      await _applySelectedLocationAddress();
    });
  }

  Future<void> _checkUserProfileData(AuthProvider authProvider) async {
    if (authProvider.user == null) {
      await authProvider.fetchUserProfile();
    }
    final user = authProvider.user;
    if (user == null) return;

    if (user.advertiserLocation != null && user.advertiserLocation!.trim().isNotEmpty) {
      setState(() {
        selectedLocation = user.advertiserLocation!;
      });
    }

    List<String> missingFields = [];
    if (user.phone.trim().isEmpty) {
      missingFields.add('phone number');
    }
    if ((user.advertiserLocation == null || user.advertiserLocation!.trim().isEmpty) && (user.latitude == null || user.longitude == null)) {
      missingFields.add('your location');
    }

    if (missingFields.isNotEmpty && mounted) {
      _showProfileIncompleteDialog(missingFields);
    }
  }

  void _showProfileIncompleteDialog(List<String> missingFields) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
        final s = S.of(context);

        // ترجم عناصر الحقول الناقصة إلى اللغة المختارة
        final localizedMissingFields = missingFields.map((field) {
          switch (field) {
            case 'phone number':
              return s.phone; // "Phone"
            case 'your location':
              return s.advertiserLocation; // "Advertiser Location"
            default:
              return field;
          }
        }).toList();

        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            return false;
          },
          child: Directionality(
            textDirection: textDirection,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                s.editprof4,
                style: const TextStyle(fontWeight: FontWeight.bold, color: KTextColor, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.profileWarning,
                    style: const TextStyle(fontSize: 16, color: KTextColor),
                  ),
                  const SizedBox(height: 8),
                  ...localizedMissingFields.map(
                    (f) => Row(
                    
                                  
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red,size: 18,),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                                      color: Color(0xFFE74C3C),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/profile');
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KPrimaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  @override
  void dispose() {
    _areaController.dispose();
    _priceController.dispose();
    _serviceNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _mainImage = image;
        _mainImageBytes = bytes;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
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
        if (mounted)
          setState(() {
            selectedLatLng = latLng;
            if (address != null) selectedLocation = address;
          });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _navigateToLocationPicker() async {
    final result = await context
        .push('/location_picker', extra: {'initialLatLng': selectedLatLng});
    if (result != null && result is Map<String, dynamic>) {
      final LatLng? location = result['location'] as LatLng?;
      final String? address = result['address'] as String?;
      if (location != null)
        setState(() {
          selectedLatLng = location;
          if (address != null) selectedLocation = address;
        });
    }
  }

  Future<void> _validateAndProceedToNext() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).please_fill_required_fields),
          backgroundColor: KPrimaryColor));
      return;
    }
    if (_mainImageBytes == null || _mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'الرجاء إضافة صورة رئيسية.' : 'Please add a main image.'),
          backgroundColor: KPrimaryColor));
      return;
    }
    if (selectedLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'الرجاء تحديد موقع على الخريطة.' : 'Please select a location on the map.'),
          backgroundColor: KPrimaryColor));
      return;
    }

    final infoProvider = context.read<OtherServicesInfoProvider>();
    final adData = {
      'adType': 'other_service',
      'emirate': infoProvider.getEmirateNameFromDisplayName(selectedEmirate),
      'district': selectedDistrict,
      'area': _areaController.text,
      'price': _priceController.text,
      'service_name': _serviceNameController.text,
      'section_type': selectedSectionType,
      'title': _titleController.text,
      'advertiser_name': selectedAdvertiserName,
      'phone_number': PhoneNumberFormatter.formatForApi(selectedPhoneNumber!),
      'whatsapp_number':
          selectedWhatsAppNumber != null && selectedWhatsAppNumber!.isNotEmpty
              ? PhoneNumberFormatter.formatForApi(selectedWhatsAppNumber!)
              : null,
      'description': _descriptionController.text,
      'address': selectedLocation,
      'mainImage': File(_mainImage!.path),
    };

    context.push('/placeAnAd', extra: adData);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<OtherServicesInfoProvider>(
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
                        child: Text(s.otherServicesAds,
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
                          hintText: s.enterArea, isRequired: true),
                      _buildTitledTextFormField(
                          s.price, _priceController, borderColor, currentLocale,
                          hintText: '1000', isNumber: true, isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildTitledTextFormField(s.serviceName,
                          _serviceNameController, borderColor, currentLocale,
                          hintText: s.enterServiceName, isRequired: true),
                      _buildSingleSelectField(
                          context,
                          s.sectionType,
                          selectedSectionType,
                          infoProvider.sectionTypes,
                          (selection) =>
                              setState(() => selectedSectionType = selection),
                          isRequired: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildTitledTextFormField(
                        s.title, _titleController, borderColor, currentLocale,
                        minLines: 3,
                        hintText: s.enterTitle,
                        isRequired: true,
                        maxLength: 100),
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
                            if (success)
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
                            final token = await const FlutterSecureStorage()
                                .read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem(
                                  'phone_numbers', value,
                                  token: token);
                              if (success)
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
                            final token = await const FlutterSecureStorage()
                                .read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem(
                                  'whatsapp_numbers', value,
                                  token: token);
                              if (success)
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
                    if (_mainImageBytes != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                              child: Image.memory(_mainImageBytes!,
                                  height: 150, fit: BoxFit.cover))),
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
                          SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 20.h),
                          SizedBox(width: 8.w),
                          Expanded(child: Text(selectedLocation.isNotEmpty ? selectedLocation : S.of(context).advertiserLocation, style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500)))
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
                    SizedBox(height: 20.h)
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
      int? maxLength}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines > 1 ? minLines + 1 : 1,
        maxLength: maxLength,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                return null;
              }
            : null,
        decoration: InputDecoration(
            counterText: "",
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400),
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
            filled: true),
        style: TextStyle(
            fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
        textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
      )
    ]);
  }

  Widget _buildSingleSelectField(BuildContext context, String title,
      String? selectedValue, List<String> allItems, Function(String?) onConfirm,
      {double? titleFontSize, bool isRequired = false}) {
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
                              final result = await _showSingleSelectPicker(
                                  context,
                                  title: title,
                                  items: allItems);
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
                                  color: state.hasError
                                      ? Colors.red
                                      : borderColor),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(selectedValue ?? s.chooseAnOption,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: selectedValue == null
                                      ? Colors.grey.shade500
                                      : KTextColor,
                                  fontSize: 12.sp),
                              overflow: TextOverflow.ellipsis))),
                  if (state.hasError)
                    Padding(
                        padding: const EdgeInsets.only(top: 5, left: 10),
                        child: Text(state.errorText!,
                            style:
                                TextStyle(color: Colors.red, fontSize: 10.sp)))
                ]);
          })
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
                                :  Text(S.of(context).locateMe,
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
                            child:Text(S.of(context).pickLocation,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.5))))]))
            ])));
  }

  Future<void> _applySelectedLocationAddress() async {
    try {
      if (selectedLatLng == null && selectedLocation.isNotEmpty) {
        final locations = await locationFromAddress(selectedLocation);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          final latLng = LatLng(loc.latitude, loc.longitude);
          if (!mounted) return;
          setState(() {
            selectedLatLng = latLng;
          });
          final mapsProvider = context.read<GoogleMapsProvider>();
          await mapsProvider.moveCameraToLocation(latLng.latitude, latLng.longitude, zoom: 16.0);
        }
      }
    } catch (e) {
      debugPrint('Error geocoding selectedLocation: $e');
    }
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
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor)),
          child: Column(
            children: [
              TextFormField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                maxLength: 5000,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: KTextColor,
                    fontSize: 14.sp),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    counterText: "",
                    hintText: s.enterDescription,
                    hintStyle:
                        TextStyle(fontSize: 14, color: Colors.grey.shade400)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, child) => Text(
                      '${controller.text.length}/5000',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
              )
            ],
          ))
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
        right: 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: KTextColor,
              ),
            ),
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
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: KPrimaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        s.noResultsFound,
                        style: const TextStyle(color: KTextColor),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(
                            item,
                            style: const TextStyle(color: KTextColor),
                          ),
                          onTap: () => Navigator.pop(context, item),
                        );
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
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.value,
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: KTextColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCountryCode = value!),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: KPrimaryColor, width: 2),
                        ),
                      ),
                      isDense: true,
                      isExpanded: true,
                    ),
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
                      fontSize: 12.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.isNumeric ? s.phoneNumber : s.addNew,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: KPrimaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    String result = _addController.text.trim();
                    if (widget.isNumeric && result.isNotEmpty) {
                      result = '$_selectedCountryCode$result';
                    }
                    if (result.isNotEmpty) {
                      if (widget.onAddNew != null) {
                        await widget.onAddNew!(result);
                      }
                      Navigator.pop(context, result);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    minimumSize: const Size(60, 48),
                  ),
                  child: Text(
                    s.add,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
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


// moved into _OtherServicesAdScreenState
