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
import 'package:advertising_app/data/repository/real_estate_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:advertising_app/generated/l10n.dart';
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
      final detailsProvider = Provider.of<RealEstateDetailsProvider>(context, listen: false);
      await detailsProvider.fetchRealEstateDetails(widget.adId);

      // Fetch contact info
      final infoProvider = Provider.of<RealEstateInfoProvider>(context, listen: false);
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
                return const Center(child: Text('لم يتم العثور على بيانات الإعلان'));
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
                            Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                            Transform.translate(
                              offset: Offset(-3.w, 0),
                              child: Text(
                                S.of(context).back,
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
                        _buildReadOnlyField(s.emirate, ad.emirate ?? '', borderColor),
                        _buildReadOnlyField(s.district, ad.district ?? '', borderColor),
                      ]),
                      const SizedBox(height: 7),

                      _buildFormRow([
                        _buildReadOnlyField(s.area, ad.area ?? '', borderColor),
                        _buildEditableTextField(s.price, _priceController, borderColor, currentLocale, isNumber: true),
                      ]),
                      const SizedBox(height: 7),

                      _buildFormRow([
                        _buildReadOnlyField(s.contractType, ad.contractType ?? '', borderColor),
                        _buildReadOnlyField(s.propertyType, ad.propertyType ?? '', borderColor),
                      ]),
                      const SizedBox(height: 7),

                      _buildReadOnlyTitleBox(s.title, ad.title ?? '', borderColor, currentLocale),
                      const SizedBox(height: 7),

                      _buildReadOnlyField(s.advertiserName, ad.advertiserName ?? '', borderColor),
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
                        (newValue) => setState(() => selectedPhoneNumber = newValue),
                        (value) async {
                          final token = await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
                          final success = await infoProvider.addContactItem('phone_numbers', value, token: token);
                          if (success) {
                            setState(() => selectedPhoneNumber = value);
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
                        (newValue) => setState(() => selectedWhatsAppNumber = newValue),
                        (value) async {
                          final token = await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
                          final success = await infoProvider.addContactItem('whatsapp_numbers', value, token: token);
                          if (success) {
                            setState(() => selectedWhatsAppNumber = value);
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
                      
                      _buildEditableDescriptionBox(s.description, _descriptionController, borderColor),
                      const SizedBox(height: 10),
                      
                      _buildImageButton(s.addMainImage, Icons.add_a_photo_outlined, borderColor, _pickMainImage),
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
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
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
                      _buildImageButton(s.add9Images, Icons.add_photo_alternate_outlined, borderColor, _pickThumbnailImages),
                      const SizedBox(height: 7),
                      _buildThumbnailsPreview(),
                      const SizedBox(height: 7),
                      
                      Text(s.location, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor)),
                      SizedBox(height: 4.h),

                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 20.h),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text('${ad.location ?? ''}', 
                                style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500)),
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
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(s.save, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }

  Widget _buildReadOnlyField(String title, String value, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor)),
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
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTextField(String title, TextEditingController controller, Color borderColor, String currentLocale, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor)),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTitleBox(String title, String value, Color borderColor, String currentLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor)),
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
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          ),
        ),
      ],
    );
  }

  Widget _buildContactField(String title, String? selectedValue, List<String> options, 
      Function(String?) onChanged, Function(String) onAdd, Color borderColor, {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor)),
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

  Widget _buildEditableDescriptionBox(String title, TextEditingController controller, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor)),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 15000,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton(String title, IconData icon, Color borderColor, VoidCallback onPressed) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: Icon(icon, color: KTextColor), label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)), onPressed: onPressed, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
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
            Text(s.add9Images, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor)),
            Text('${_existingThumbnailUrls.length + _thumbnailImages.length}/9', style: TextStyle(color: Colors.grey.shade600)),
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
                        width: 96, height: 96,
                        child: isExisting
                            ? CachedNetworkImage(
                                imageUrl: ImageUrlHelper.getFullImageUrl(_existingThumbnailUrls[i]),
                                fit: BoxFit.cover,
                                placeholder: (c, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                errorWidget: (c, _, __) => const Icon(Icons.broken_image),
                              )
                            : Image.file(_thumbnailImages[i - _existingThumbnailUrls.length], fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 0, top: 0,
                      child: InkWell(
                        onTap: () {
                          if (isExisting) {
                            _removeExistingThumbnail(i);
                          } else {
                            _removeNewThumbnail(i - _existingThumbnailUrls.length);
                          }
                        },
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
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
                  initialCameraPosition: CameraPosition(target: adLocation, zoom: 14.0),
                  onMapCreated: (GoogleMapController controller) {
                    mapsProvider.onMapCreated(controller);
                    if (snapshot.hasData) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        mapsProvider.moveCameraToLocation(adLocation.latitude, adLocation.longitude, zoom: 14.0);
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
                        title: ad?.location.isNotEmpty == true ? 'الموقع المحدد' : (ad?.emirate ?? 'الموقع'),
                        snippet: ad?.location.isNotEmpty == true ? ad!.location : (ad?.area ?? ''),
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
      final infoProvider = Provider.of<RealEstateInfoProvider>(context, listen: false);
      final token = await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
      await infoProvider.addContactItem(type, value, token: token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة ${type == 'phone_numbers' ? 'رقم الهاتف' : 'رقم الواتساب'} بنجاح')),
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
      final int already = _existingThumbnailUrls.length + _thumbnailImages.length;
      final int remaining = maxThumbs - already;
      if (remaining <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يمكنك اختيار حتى 9 صور فقط')),
        );
        return;
      }
      final filesToAdd = images.take(remaining).map((xfile) => File(xfile.path)).toList();
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
        formData.fields.add(MapEntry('whatsapp_number', selectedWhatsAppNumber!));
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
        final f = await _downloadImageToTempFile(ImageUrlHelper.getFullImageUrl(url));
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
          SnackBar(content: Text('تم حفظ الإعلان بنجاح')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save ad');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ الإعلان: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<File?> _downloadImageToTempFile(String imageUrl) async {
    try {
      final dio = Dio();
      final response = await dio.get(imageUrl, options: Options(responseType: ResponseType.bytes));
      final filename = 'thumb_${DateTime.now().millisecondsSinceEpoch}_${imageUrl.hashCode}.jpg';
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

class TitledDescriptionBox extends StatefulWidget {
  final String title;
  final String initialValue;
  final Color borderColor;
  final int maxLength;
  const TitledDescriptionBox({Key? key, required this.title, required this.initialValue, required this.borderColor, this.maxLength = 5000}) : super(key: key);
  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}
class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() { setState(() {}); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
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

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++    الودجت المخصصة المأخوذة من الملف المرجعي          ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// TitledSelectOrAddField widget definition
class TitledSelectOrAddField extends StatefulWidget {
  final String title;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final Function(String) onAddNew;
  final bool isNumeric;

  const TitledSelectOrAddField({
    Key? key,
    required this.title,
    this.value,
    required this.items,
    required this.onChanged,
    required this.onAddNew,
    this.isNumeric = false,
  }) : super(key: key);

  @override
  _TitledSelectOrAddFieldState createState() => _TitledSelectOrAddFieldState();
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
        // العنوان خارجي بالفعل من _buildContactField
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