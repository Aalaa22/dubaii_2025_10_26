import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/google_maps_provider.dart';

import '../../generated/l10n.dart';
import '../providers/real_estate_details_provider.dart';
import '../providers/real_estate_info_provider.dart';

import 'package:advertising_app/presentation/widget/titled_select_or_add_field.dart';
import '../../../constant/string.dart';
import '../../../constant/image_url_helper.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
const Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class RealEstateSaveAdScreen extends StatefulWidget {
  // استقبال دالة تغيير اللغة ومعرف الإعلان
  final Function(Locale) onLanguageChange;
  final String adId;

  const RealEstateSaveAdScreen({
    Key? key,
    required this.onLanguageChange,
    required this.adId,
  }) : super(key: key);

  @override
  State<RealEstateSaveAdScreen> createState() => _RealEstateSaveAdScreenState();
}

class _RealEstateSaveAdScreenState extends State<RealEstateSaveAdScreen> {
  // State variables
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  // Contact info
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;

  // Image handling
  File? _mainImage;
  List<File> _thumbnailImages = [];
  final ImagePicker _picker = ImagePicker();
  // صور موجودة من السيرفر + صور جديدة يضيفها المستخدم
  List<String> _existingThumbnailUrls = [];
  List<String> _removedExistingThumbnailUrls = [];

  // State management
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // إذا كان المعرف فارغًا أو قيمة افتراضية من الراوتر، لا نحاول الجلب
    if (widget.adId.trim().isEmpty || widget.adId.trim() == '0') {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Fetch real estate details
      final detailsProvider =
          Provider.of<RealEstateDetailsProvider>(context, listen: false);
      await detailsProvider.fetchRealEstateDetails(widget.adId);

      // Fetch contact info
      final infoProvider =
          Provider.of<RealEstateInfoProvider>(context, listen: false);
      await infoProvider.fetchContactInfo();

      // Populate controllers with existing data
      final ad = detailsProvider.realEstateDetails;
      if (ad != null) {
        _priceController.text = ad.price?.toString() ?? '';
        _descriptionController.text = ad.description ?? '';
        selectedPhoneNumber = ad.phoneNumber;
        selectedWhatsAppNumber = ad.whatsappNumber;
        // حفظ الصور الفرعية القادمة مع الإعلان
        try {
          _existingThumbnailUrls = List<String>.from(ad.thumbnailImages ?? []);
        } catch (_) {
          _existingThumbnailUrls = [];
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على نسخة من كلاس الترجمة
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<RealEstateDetailsProvider, RealEstateInfoProvider>(
              builder: (context, detailsProvider, infoProvider, child) {
                final ad = detailsProvider.realEstateDetails;

                if (ad == null) {
                  return const Center(
                      child: Text('لم يتم العثور على بيانات الإعلان'));
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
                          child: Row(
                            children: [
                              SizedBox(width: 5.w),
                              Icon(Icons.arrow_back_ios,
                                  color: KTextColor, size: 20.sp),
                              Transform.translate(
                                offset: Offset(-3.w, 0),
                                child: Text(
                                  S.of(context)!.back,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: KTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 7.h),

                        Center(
                          child: Text(
                            s.realEstateAds,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 24.sp,
                              color: KTextColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // Read-only fields
                        _buildFormRow([
                          _buildReadOnlyField(
                              s.emirate, ad.emirate ?? '', borderColor),
                          _buildReadOnlyField(
                              s.district, ad.district ?? '', borderColor),
                        ]),
                        const SizedBox(height: 7),

                        _buildFormRow([
                          _buildReadOnlyField(
                              s.area, ad.area ?? '', borderColor),
                          _buildEditableTextField(s.price, _priceController,
                              borderColor, currentLocale,
                              isNumber: true),
                        ]),
                        const SizedBox(height: 7),

                        _buildFormRow([
                          _buildReadOnlyField(s.contractType,
                              ad.contractType ?? '', borderColor),
                          _buildReadOnlyField(s.propertyType,
                              ad.propertyType ?? '', borderColor),
                        ]),
                        const SizedBox(height: 7),

                        _buildReadOnlyTitleBox(s.title, ad.title ?? '',
                            borderColor, currentLocale),
                        const SizedBox(height: 7),

                        _buildReadOnlyField(s.advertiserName,
                            ad.advertiserName ?? '', borderColor),
                        const SizedBox(height: 7),

                        // Contact Information
                        const SizedBox(height: 7),
                        _buildFormRow([
                          Consumer<RealEstateInfoProvider>(
                            builder: (context, infoProvider, child) {
                              return Expanded(
                                child: _buildContactField(
                                  s.phoneNumber,
                                  selectedPhoneNumber,
                                  infoProvider.phoneNumbers.isNotEmpty
                                      ? infoProvider.phoneNumbers
                                      : [ad.phoneNumber ?? ''],
                                  (newValue) => setState(
                                      () => selectedPhoneNumber = newValue),
                                  (value) async {
                                    final token =
                                        await const FlutterSecureStorage()
                                                .read(key: 'auth_token') ??
                                            '';
                                    final success = await infoProvider
                                        .addContactItem('phone_numbers', value,
                                            token: token);
                                    if (success) {
                                      setState(
                                          () => selectedPhoneNumber = value);
                                    }
                                  },
                                  KPrimaryColor,
                                  isNumeric: true,
                                ),
                              );
                            },
                          ),
                          // const SizedBox(width:5),
                          Consumer<RealEstateInfoProvider>(
                            builder: (context, infoProvider, child) {
                              return Expanded(
                                child: _buildContactField(
                                  s.whatsApp,
                                  selectedWhatsAppNumber,
                                  infoProvider.whatsappNumbers.isNotEmpty
                                      ? infoProvider.whatsappNumbers
                                      : [ad.whatsappNumber ?? ''],
                                  (newValue) => setState(
                                      () => selectedWhatsAppNumber = newValue),
                                  (value) async {
                                    final token =
                                        await const FlutterSecureStorage()
                                                .read(key: 'auth_token') ??
                                            '';
                                    final success =
                                        await infoProvider.addContactItem(
                                            'whatsapp_numbers', value,
                                            token: token);
                                    if (success) {
                                      setState(
                                          () => selectedWhatsAppNumber = value);
                                    }
                                  },
                                  KPrimaryColor,
                                  isNumeric: true,
                                ),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 7),

                        TitledDescriptionBox(
                            title: s.description,
                            controller: _descriptionController,
                            borderColor: borderColor,
                            minLines: 4,
                            maxLength: 5000),
                        const SizedBox(height: 10),

                        _buildImageButton(
                            s.addMainImage,
                            Icons.add_a_photo_outlined,
                            borderColor,
                            _pickMainImage),
                        if (_mainImage != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _mainImage!,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ] else if (ad.mainImage != null &&
                            ad.mainImage!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Builder(
                              builder: (context) {
                                final mainUrl = ImageUrlHelper.getMainImageUrl(
                                    ad.mainImage!);
                                if (mainUrl.isNotEmpty) {
                                  final uri = Uri.tryParse(mainUrl);
                                  if (uri != null &&
                                      uri.hasScheme &&
                                      uri.host.isNotEmpty) {
                                    return Image.network(
                                      mainUrl,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/realEstate.jpg',
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    );
                                  }
                                }
                                return Image.asset(
                                  'assets/images/realEstate.jpg',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 7),
                        _buildImageButton(
                            s.add9Images,
                            Icons.add_photo_alternate_outlined,
                            borderColor,
                            _pickThumbnailImages),
                        const SizedBox(height: 7),
                        _buildThumbnailsPreview(),
                        const SizedBox(height: 7),

                        Text(s.location,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: KTextColor)),
                        SizedBox(height: 4.h),

                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              SvgPicture.asset('assets/icons/locationicon.svg',
                                  width: 20.w, height: 20.h),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text('${ad.location ?? ''}',
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: KTextColor,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildMapSection(context),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveAd,
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(s.save,
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
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
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((child) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: child)))
            .toList());
  }

  Widget _buildReadOnlyField(String title, String value, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: KTextColor)),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTextField(String title, TextEditingController controller,
      Color borderColor, String currentLocale,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: KTextColor)),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          decoration: InputDecoration(
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
              borderSide: BorderSide(color: KPrimaryColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTitleBox(
      String title, String value, Color borderColor, String currentLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: KTextColor)),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
            textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          ),
        ),
      ],
    );
  }

  Widget _buildContactField(
      String title,
      String? selectedValue,
      List<String> options,
      Function(String?) onChanged,
      Function(String) onAdd,
      Color borderColor,
      {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: KTextColor)),
        SizedBox(height: 4.h),
        TitledSelectOrAddField(
          title: '',
          value: selectedValue,
          items: options,
          onChanged: (newValue) => onChanged(newValue),
          onAddNew: (value) async {
            await onAdd(value);
          },
          isNumeric: isNumeric,
        ),
      ],
    );
  }

  Widget _buildImageButton(
      String title, IconData icon, Color borderColor, VoidCallback onPressed) {
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

  Widget _buildThumbnailsPreview() {
    if (_existingThumbnailUrls.isEmpty && _thumbnailImages.isEmpty) {
      return const SizedBox.shrink();
    }
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.add9Images,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: KTextColor)),
            Text('${_existingThumbnailUrls.length + _thumbnailImages.length}/9',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _existingThumbnailUrls.length + _thumbnailImages.length,
            itemBuilder: (context, i) {
              final bool isExisting = i < _existingThumbnailUrls.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: isExisting
                            ? CachedNetworkImage(
                                imageUrl: ImageUrlHelper.getFullImageUrl(
                                    _existingThumbnailUrls[i]),
                                fit: BoxFit.cover,
                                placeholder: (c, _) => const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                errorWidget: (c, _, __) =>
                                    const Icon(Icons.broken_image),
                              )
                            : Image.file(
                                _thumbnailImages[
                                    i - _existingThumbnailUrls.length],
                                fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () {
                          if (isExisting) {
                            _removeExistingThumbnail(i);
                          } else {
                            _removeNewThumbnail(
                                i - _existingThumbnailUrls.length);
                          }
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context) {
    final provider = context.watch<RealEstateDetailsProvider>();
    final ad = provider.realEstateDetails;

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
                LatLng adLocation = const LatLng(25.2048, 55.2708);
                if (snapshot.hasData) {
                  adLocation = snapshot.data!;
                }

                return GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: adLocation, zoom: 14.0),
                  onMapCreated: (GoogleMapController controller) {
                    mapsProvider.onMapCreated(controller);
                    if (snapshot.hasData) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        mapsProvider.moveCameraToLocation(
                            adLocation.latitude, adLocation.longitude,
                            zoom: 14.0);
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
                        title: ad?.location.isNotEmpty == true
                            ? S.of(context)!.location
                            : (ad?.emirate ?? S.of(context)!.location),
                        snippet: ad?.location.isNotEmpty == true
                            ? ad!.location
                            : (ad?.area ?? ''),
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

  // Contact info and image handling methods
  Future<void> _addContactItem(String type, String value) async {
    try {
      final infoProvider =
          Provider.of<RealEstateInfoProvider>(context, listen: false);
      final token =
          await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
      await infoProvider.addContactItem(type, value, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'تم إضافة ${type == 'phone_numbers' ? 'رقم الهاتف' : 'رقم الواتساب'} بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إضافة البيانات: $e')),
        );
      }
    }
  }

  Future<void> _pickMainImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _mainImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
      );
    }
  }

  Future<void> _pickThumbnailImages() async {
    const int maxThumbs = 9;
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;
      final int already =
          _existingThumbnailUrls.length + _thumbnailImages.length;
      final int remaining = maxThumbs - already;
      if (remaining <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يمكنك اختيار حتى 9 صور فقط')),
        );
        return;
      }
      final filesToAdd =
          images.take(remaining).map((xfile) => File(xfile.path)).toList();
      setState(() {
        _thumbnailImages.addAll(filesToAdd);
      });
      final extra = images.length - filesToAdd.length;
      if (extra > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يمكنك اختيار حتى 9 صور فقط')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصور: $e')),
      );
    }
  }

  void _removeExistingThumbnail(int index) {
    if (index < 0 || index >= _existingThumbnailUrls.length) return;
    setState(() {
      _removedExistingThumbnailUrls.add(_existingThumbnailUrls[index]);
      _existingThumbnailUrls.removeAt(index);
    });
  }

  void _removeNewThumbnail(int index) {
    if (index < 0 || index >= _thumbnailImages.length) return;
    setState(() {
      _thumbnailImages.removeAt(index);
    });
  }

  // Save functionality
  Future<void> _saveAd() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      final formData = FormData();

      // Add method field for PUT request
      formData.fields.add(MapEntry('_method', 'PUT'));

      // Add editable fields
      formData.fields.add(MapEntry('price', _priceController.text));
      formData.fields.add(MapEntry('description', _descriptionController.text));

      if (selectedPhoneNumber != null) {
        formData.fields.add(MapEntry('phone_number', selectedPhoneNumber!));
      }

      if (selectedWhatsAppNumber != null) {
        formData.fields
            .add(MapEntry('whatsapp_number', selectedWhatsAppNumber!));
      }

      // Add main image if selected
      if (_mainImage != null) {
        formData.files.add(MapEntry(
          'main_image',
          await MultipartFile.fromFile(_mainImage!.path),
        ));
      }

      // دمج الصور الفرعية: الموجودة التي تم الإبقاء عليها + الجديدة
      final List<File> allThumbs = [];
      for (final url in _existingThumbnailUrls) {
        final f =
            await _downloadImageToTempFile(ImageUrlHelper.getFullImageUrl(url));
        if (f != null) allThumbs.add(f);
      }
      allThumbs.addAll(_thumbnailImages);
      final merged = allThumbs.take(9).toList();
      for (int i = 0; i < merged.length; i++) {
        formData.files.add(MapEntry(
          'thumbnail_images[]',
          await MultipartFile.fromFile(merged[i].path),
        ));
      }

      final response = await dio.post(
        '$baseUrl/api/real-estate/${widget.adId}',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.saveSuccess,
              textDirection: Directionality.of(context),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save ad');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context)!.saveFailed(e.toString()),
            textDirection: Directionality.of(context),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<File?> _downloadImageToTempFile(String imageUrl) async {
    try {
      final dio = Dio();
      final response = await dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));
      final filename =
          'thumb_${DateTime.now().millisecondsSinceEpoch}_${imageUrl.hashCode}.jpg';
      final file = File('${Directory.systemTemp.path}/$filename');
      await file.writeAsBytes(response.data);
      return file;
    } catch (_) {
      return null;
    }
  }
}

// Helper: resolve ad location to coordinates
Future<LatLng> _getAdLocation(dynamic ad) async {
  // Try geocoding using precise location string
  try {
    final String? loc = ad?.location;
    if (loc != null && loc.trim().isNotEmpty) {
      final locations = await locationFromAddress(loc);
      if (locations.isNotEmpty) {
        final first = locations.first;
        return LatLng(first.latitude, first.longitude);
      }
    }
  } catch (e) {
    debugPrint('Geocoding failed for real estate location: $e');
  }

  // Fallback to emirate-based defaults
  final String? emirate = ad?.emirate;
  if (emirate != null && emirate.isNotEmpty) {
    switch (emirate.toLowerCase()) {
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
        return const LatLng(25.2048, 55.2708);
    }
  }

  // Final fallback: Dubai
  return const LatLng(25.2048, 55.2708);
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++    الودجت المخصصة المأخوذة من الملف المرجعي          ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
