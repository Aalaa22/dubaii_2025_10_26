import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/other_services_details_provider.dart';
import 'package:advertising_app/data/model/other_service_ad_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/presentation/providers/other_services_info_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:advertising_app/constant/image_url_helper.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
const Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class OtherServicesSaveAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  final int? adId;

  const OtherServicesSaveAdScreen({Key? key, required this.onLanguageChange, this.adId}) : super(key: key);

  @override
  State<OtherServicesSaveAdScreen> createState() => _OtherServicesSaveAdScreenState();
}

class _OtherServicesSaveAdScreenState extends State<OtherServicesSaveAdScreen> {
  // Editable fields
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedPhoneNumber;
  String? _selectedWhatsAppNumber;
  bool _didPopulateFields = false; // يمنع إعادة تعبئة الحقول عند كل إعادة بناء
  // Images
  final ImagePicker _picker = ImagePicker();
  File? _mainImageFile;

  @override
  void initState() {
    super.initState();
    if (widget.adId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OtherServicesDetailsProvider>().fetchAdDetails(widget.adId!);
        // تحميل قوائم أرقام الهاتف والواتساب من المزود
        context.read<OtherServicesInfoProvider>().fetchContactInfo();
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAd() async {
    if (widget.adId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد معرّف للإعلان للتحديث')));
      return;
    }

    final provider = context.read<OtherServicesDetailsProvider>();
    final ad = provider.adDetails;

    final String price = _priceController.text.trim();
    final String description = _descriptionController.text.trim();
    final String phone = (_selectedPhoneNumber?.trim().isNotEmpty ?? false)
        ? _selectedPhoneNumber!.trim()
        : (ad?.phoneNumber ?? '').trim();
    final String? whatsapp = (_selectedWhatsAppNumber?.trim().isNotEmpty ?? false)
        ? _selectedWhatsAppNumber!.trim()
        : (ad?.whatsappNumber?.trim().isNotEmpty ?? false)
            ? ad!.whatsappNumber!.trim()
            : null;

    try {
      final ok = await provider.updateOtherServiceAd(
        adId: widget.adId!,
        price: price,
        description: description,
        phoneNumber: phone.isNotEmpty ? phone : null,
        whatsappNumber: whatsapp,
        mainImage: _mainImageFile,
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الإعلان بنجاح')));
        Navigator.of(context).pop();
      } else {
        final err = provider.error ?? 'حدث خطأ أثناء التحديث';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = const Color.fromRGBO(8, 194, 201, 1);
    final infoProvider = context.watch<OtherServicesInfoProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<OtherServicesDetailsProvider>(
        builder: (context, provider, _) {
          final OtherServiceAdModel? ad = provider.adDetails;

          // Populate controllers once data is available
          if (ad != null && !_didPopulateFields) {
            _priceController.text = ad.price;
            _descriptionController.text = ad.description ?? '';
            _selectedPhoneNumber = ad.phoneNumber;
            _selectedWhatsAppNumber = ad.whatsappNumber;
            _didPopulateFields = true;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 25.h),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(children: [
                      SizedBox(width: 5.w),
                      Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                      Transform.translate(
                        offset: Offset(-3.w, 0),
                        child: Text(s.back, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: KTextColor)),
                      ),
                    ]),
                  ),
                  SizedBox(height: 7.h),

                  Center(
                    child: Text(s.otherServicesAds, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24.sp, color: KTextColor)),
                  ),

                  SizedBox(height: 10.h),

                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.error != null)
                    Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)))
                  else if (ad == null)
                    Center(child: Text(s.noResultsFound))
                  else ...[
                    _buildFormRow([
                      // Emirate (view-only, grey)
                      _buildTitledDropdownField(
                        context,
                        s.emirate,
                        [if (ad.emirate != null) ad.emirate!],
                        ad.emirate,
                        borderColor,
                        readOnly: true,
                      ),
                      // District (view-only, grey)
                      _buildTitledDropdownField(
                        context,
                        s.district,
                        [if (ad.district != null) ad.district!],
                        ad.district,
                        borderColor,
                        readOnly: true,
                      ),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      // Area (view-only)
                      _buildTitledTextField(s.area, ad.area ?? '', borderColor, currentLocale, isNumber: false, readOnly: true),
                      // Price (editable)
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.price, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
                          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KPrimaryColor, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      // Service name (view-only, grey)
                      _buildTitledTextField(s.serviceName, ad.serviceName ?? '', borderColor, currentLocale, readOnly: true),
                      // Section type (view-only, grey)
                      _buildTitledDropdownField(
                        context,
                        s.sectionType,
                        [if (ad.sectionType != null) ad.sectionType!],
                        ad.sectionType,
                        borderColor,
                        readOnly: true,
                      ),
                    ]),
                    const SizedBox(height: 7),

                    // Title (view-only)
                    _buildTitleBox(context, s.title, ad.title, borderColor, currentLocale),
                    const SizedBox(height: 7),

                    // Advertiser name (view-only, remove Add button)
                    _buildTitledTextField(
                      s.advertiserName,
                      ad.advertiserName,
                      borderColor,
                      currentLocale,
                      readOnly: true,
                    ),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      // Phone (editable, keep logic intact)
                      TitledSelectOrAddField(
                        title: s.phoneNumber,
                        value: _selectedPhoneNumber,
                        items: infoProvider.phoneNumbers,
                        onChanged: (v) => setState(() => _selectedPhoneNumber = v),
                        isNumeric: true,
                        onAddNew: (value) async {
                          final token = await const FlutterSecureStorage().read(key: 'auth_token');
                          if (token != null) {
                            final success = await infoProvider.addContactItem('phone_numbers', value, token: token);
                            if (success) setState(() => _selectedPhoneNumber = value);
                          }
                        },
                      ),
                      // WhatsApp (editable, keep logic intact)
                      TitledSelectOrAddField(
                        title: s.whatsApp,
                        value: _selectedWhatsAppNumber,
                        items: infoProvider.whatsappNumbers,
                        onChanged: (v) => setState(() => _selectedWhatsAppNumber = v),
                        isNumeric: true,
                        onAddNew: (value) async {
                          final token = await const FlutterSecureStorage().read(key: 'auth_token');
                          if (token != null) {
                            final success = await infoProvider.addContactItem('whatsapp_numbers', value, token: token);
                            if (success) setState(() => _selectedWhatsAppNumber = value);
                          }
                        },
                      ),
                    ]),
                    const SizedBox(height: 7),

                    // Description (editable)
                    TitledDescriptionBox(title: s.description, initialValue: ad.description ?? '', borderColor: borderColor, controller: _descriptionController),
                    const SizedBox(height: 10),

                    // Main image button (view-only, keep as is)
                    _buildImageButton(s.addMainImage, Icons.add_a_photo_outlined, borderColor),
                    if (_mainImageFile != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_mainImageFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ] else if (ad.mainImage != null && ad.mainImage!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Builder(
                          builder: (context) {
                            final mainUrl = ImageUrlHelper.getMainImageUrl(ad.mainImage!);
                            if (mainUrl.isNotEmpty) {
                              final uri = Uri.tryParse(mainUrl);
                              if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
                                return Image.network(
                                  mainUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/service.jpg',
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                );
                              }
                            }
                            return Image.asset(
                              'assets/images/service.jpg',
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),

                    // Location (view-only)
                    Text(s.location, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor)),
                    SizedBox(height: 4.h),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(children: [
                        SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 20.h),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '${ad.addres ?? ''}',
                            style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(height: 8.h),
                    _buildMapSection(context),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isUpdating ? null : _saveAd,
                        child: provider.isUpdating
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(s.save, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- دوال المساعدة المحدثة ---

  Widget _buildFormRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }

  Widget _buildTitledTextField(String title, String initialValue, Color borderColor, String currentLocale, {bool isNumber = false, bool readOnly = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
          initialValue: initialValue,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          readOnly: readOnly,
          decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
              filled: true))
    ]);
  }

  Widget _buildTitledDropdownField(
      BuildContext context, String title, List<String> items, String? value, Color borderColor,
      {double? titleFontSize, bool readOnly = false}) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: titleFontSize ?? 14.sp)),
      const SizedBox(height: 4),
      IgnorePointer(
        ignoring: readOnly,
        child: DropdownSearch<String>(
            filterFn: (item, filter) => item.toLowerCase().startsWith(filter.toLowerCase()),
            popupProps: PopupProps.menu(
                menuProps: MenuProps(backgroundColor: Colors.white, borderRadius: BorderRadius.circular(8)),
                itemBuilder: (context, item, isSelected) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text(item, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: KTextColor))),
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                    cursorColor: KPrimaryColor,
                    style: TextStyle(color: KTextColor, fontSize: 14),
                    decoration: InputDecoration(
                        hintText: s.search,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)))),
                emptyBuilder: (context, searchEntry) => Center(child: Text(s.noResultsFound, style: TextStyle(fontSize: 14, color: KTextColor)))),
            items: items,
            selectedItem: value,
            dropdownDecoratorProps: DropDownDecoratorProps(
                baseStyle: TextStyle(fontWeight: FontWeight.w400, color: KTextColor, fontSize: 12.sp),
                dropdownSearchDecoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    fillColor: readOnly ? Colors.grey[200] : Colors.white,
                    filled: true)),
            onChanged: readOnly ? null : (val) {})
      )
    ]);
  }
  
  Widget _buildTitleBox(BuildContext context, String title, String initialValue,
      Color borderColor, String currentLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          maxLines: null,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.all(12),
            fillColor: Colors.grey[200],
            filled: true,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------
  // Unified select/add field with searchable bottom sheet (moved to top-level)
  // ---------------------------------------------

  Widget _buildImageButton(String title, IconData icon, Color borderColor) {
    return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
            icon: Icon(icon, color: KTextColor),
            label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)),
            onPressed: _pickMainImage,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
  }

  Future<void> _pickMainImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _mainImageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Widget _buildMapSection(BuildContext context) {
    final provider = context.watch<OtherServicesDetailsProvider>();
    final ad = provider.adDetails;

    return Consumer<GoogleMapsProvider>(
      builder: (context, mapsProvider, child) {
        return Container(
          height: 320.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<LatLng>(
              future: _getAdLocation(ad),
              builder: (context, snapshot) {
                LatLng adLocation;

                if (snapshot.hasData) {
                  adLocation = snapshot.data!;
                } else {
                  adLocation = const LatLng(25.2048, 55.2708); // Dubai default
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: adLocation,
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapsProvider.onMapCreated(controller);
                    if (snapshot.hasData) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        mapsProvider.moveCameraToLocation(
                          adLocation.latitude,
                          adLocation.longitude,
                          zoom: 14.0,
                        );
                      });
                    }
                  },
                  mapType: MapType.normal,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('ad_location'),
                      position: adLocation,
                      infoWindow: InfoWindow(
                        title: ad?.addres?.isNotEmpty == true
                            ? 'الموقع المحدد'
                            : ad?.emirate ?? 'الموقع',
                        snippet: ad?.addres?.isNotEmpty == true
                            ? ad!.addres
                            : ad?.area ?? '',
                      ),
                    ),
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<LatLng> _getAdLocation(dynamic ad) async {
    // حاول أولاً استخدام حقل "location" لإيجاد الإحداثيات عبر Geocoding
    if (ad?.addres!= null && ad!.addres!.trim().isNotEmpty) {
      try {
        final locations = await locationFromAddress(ad.addres!);
        if (locations.isNotEmpty) {
          final first = locations.first;
          return LatLng(first.latitude, first.longitude);
        }
      } catch (e) {
        debugPrint('Geocoding failed for location "${ad.addres}": $e');
      }
    }

    // في حال الفشل، نستخدم إمارة الإعلان كنقطة افتراضية
    if (ad?.emirate != null && ad!.emirate!.isNotEmpty) {
      switch (ad.emirate!.toLowerCase()) {
        case 'dubai':
          return const LatLng(25.2048, 55.2708);
        case 'abu dhabi':
          return const LatLng(24.4539, 54.3773);
        case 'sharjah':
          return const LatLng(25.3463, 55.4209);
        case 'ajman':
          return const LatLng(25.4052, 55.5136);
        case 'ras al khaimah':
          return const LatLng(25.7889, 55.9598);
        case 'fujairah':
          return const LatLng(25.1288, 56.3264);
        case 'umm al quwain':
          return const LatLng(25.5641, 55.6550);
        default:
          return const LatLng(25.2048, 55.2708); // Dubai default
      }
    }

    // آخر حل: دبي
    return const LatLng(25.2048, 55.2708);
  }
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++    الودجت المخصصة المأخوذة من الملف المرجعي          ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

class TitledTextFieldWithAction extends StatefulWidget {
  final String title;
  final String initialValue;
  final Color borderColor;
  final bool isNumeric;
  final VoidCallback onAddPressed;
  const TitledTextFieldWithAction({Key? key, required this.title, required this.initialValue, required this.borderColor, required this.onAddPressed, this.isNumeric = false}) : super(key: key);
  @override
  _TitledTextFieldWithActionState createState() => _TitledTextFieldWithActionState();
}
class _TitledTextFieldWithActionState extends State<TitledTextFieldWithAction> {
  late FocusNode _focusNode;
  @override
  void initState() { super.initState(); _focusNode = FocusNode(); }
  @override
  void dispose() { _focusNode.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final addButtonWidth = (s.add.length * 8.0) + 24.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              focusNode: _focusNode,
              initialValue: widget.initialValue,
              keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
              style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(left: 16, right: addButtonWidth, top: 12, bottom: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                fillColor: Colors.white, filled: true,
              ),
            ),
            Positioned(
              right: 1, top: 1, bottom: 1,
              child: GestureDetector(
                onTap: () { widget.onAddPressed(); _focusNode.requestFocus(); },
                child: Container(
                  width: addButtonWidth - 10,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: KPrimaryColor, borderRadius: BorderRadius.only(topRight: Radius.circular(7), bottomRight: Radius.circular(7))),
                  child: Text(s.add, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------
// Unified select/add field with searchable bottom sheet (top-level)
// ---------------------------------------------
class TitledSelectOrAddField extends StatefulWidget {
  final String title;
  final String? value;
  final List<String> items;
  final Function(String) onChanged;
  final bool isNumeric;
  final Function(String)? onAddNew;

  const TitledSelectOrAddField({
    Key? key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isNumeric = false,
    this.onAddNew,
  }) : super(key: key);

  @override
  State<TitledSelectOrAddField> createState() => _TitledSelectOrAddFieldState();
}

class _TitledSelectOrAddFieldState extends State<TitledSelectOrAddField> {
  late String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _SearchableSelectOrAddBottomSheet(
                title: widget.title,
                items: widget.items,
                isNumeric: widget.isNumeric,
                onAddNew: widget.onAddNew,
              ),
            );
            if (result != null && result.isNotEmpty) {
              setState(() => _selectedValue = result);
              widget.onChanged(result);
            }
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedValue ?? s.chooseAnOption,
                    style: TextStyle(
                      fontWeight: _selectedValue == null ? FontWeight.normal : FontWeight.w500,
                      color: _selectedValue == null ? Colors.grey.shade500 : KTextColor,
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchableSelectOrAddBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final bool isNumeric;
  final Function(String)? onAddNew;

  const _SearchableSelectOrAddBottomSheet({
    required this.title,
    required this.items,
    this.isNumeric = false,
    this.onAddNew,
  });

  @override
  State<_SearchableSelectOrAddBottomSheet> createState() => _SearchableSelectOrAddBottomSheetState();
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((i) => i.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              style: const TextStyle(color: KTextColor),
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: const Icon(Icons.search, color: KTextColor),
                hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KPrimaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(child: Text(s.noResultsFound, style: const TextStyle(color: KTextColor)))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(item, style: const TextStyle(color: KTextColor)),
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
                          .map((e) => DropdownMenuItem<String>(
                                value: e.value,
                                child: Text(e.value, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCountryCode = v ?? _selectedCountryCode),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KPrimaryColor, width: 2)),
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
                    keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
                    style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
                    decoration: InputDecoration(
                      hintText: widget.isNumeric ? s.phoneNumber : s.addNew,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: KPrimaryColor, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      Navigator.pop(context, result);
                      if (widget.onAddNew != null) {
                        Future.microtask(() => widget.onAddNew!(result));
                      }
                    }
                  },
                  child: Text(s.add, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), minimumSize: const Size(60, 48)),
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

class TitledDescriptionBox extends StatefulWidget {
  final String title;
  final String initialValue;
  final Color borderColor;
  final int maxLength;
  final TextEditingController? controller;
  const TitledDescriptionBox({Key? key, required this.title, required this.initialValue, required this.borderColor, this.maxLength = 5000, this.controller}) : super(key: key);
  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}
class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  late TextEditingController _controller;
  bool _ownController = false;
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _ownController = true;
    }
    _controller.addListener(() { setState(() {}); });
  }
  @override
  void dispose() { if (_ownController) _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.borderColor)),
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                maxLines: null,
                maxLength: widget.maxLength,
                style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), counterText: ""),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text('${_controller.text.length}/${widget.maxLength}', style: TextStyle(color: Colors.grey, fontSize: 12), textDirection: TextDirection.ltr)),
              )
            ],
          ),
        ),
      ],
    );
  }
}