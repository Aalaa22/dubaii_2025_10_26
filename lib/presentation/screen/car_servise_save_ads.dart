import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/repository/car_services_ad_repository.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/presentation/providers/car_rent_info_provider.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
const Color borderColor = Color.fromRGBO(8, 194, 201, 1);
final Color KDisabledColor = Colors.white;
final Color KDisabledTextColor = Colors.grey;

class CarServicesSaveAdScreen extends StatefulWidget {
  // استقبال دالة تغيير اللغ
  final Function(Locale) onLanguageChange;
  final int? adId;

  const CarServicesSaveAdScreen({Key? key, required this.onLanguageChange, this.adId})
      : super(key: key);

  @override
  State<CarServicesSaveAdScreen> createState() => _CarServicesSaveAdScreenState();
}

class _CarServicesSaveAdScreenState extends State<CarServicesSaveAdScreen> {
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late CarRentInfoProvider _contactProvider;

  CarServiceModel? _adData;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _controllersPopulated = false;

  // Editable controllers
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _titleController;
  late TextEditingController _serviceNameController;
  late TextEditingController _areaController;
  late TextEditingController _advertiserNameController;

  // Contact selections
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;

  // Images to upload
  File? _mainImageFile;
  final List<File> _thumbnailImageFiles = [];
  final List<String> _existingThumbnailUrls = [];
  final List<String> _removedExistingThumbnailUrls = [];

  @override
  void initState() {
    super.initState();
    _contactProvider = CarRentInfoProvider();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _titleController = TextEditingController();
    _serviceNameController = TextEditingController();
    _areaController = TextEditingController();
    _advertiserNameController = TextEditingController();
    if ((widget.adId ?? 0) > 0) {
      _fetchAdDetails(widget.adId!);
    }
    _loadContactInfo();
  }

  Future<LatLng> _getAdLocation(dynamic ad) async {
    // استخدم العنوان النصي إذا كان متوفرًا
    final String? loc = ad?.location;
    if (loc != null && loc.trim().isNotEmpty) {
      try {
        final locations = await locationFromAddress(loc.trim());
        if (locations.isNotEmpty) {
          final first = locations.first;
          return LatLng(first.latitude, first.longitude);
        }
      } catch (e) {
        debugPrint('Geocoding failed for location "$loc": $e');
      }
    }

    // استخدم الإمارة كبديل عند الفشل
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

    // افتراضي: دبي
    return const LatLng(25.2048, 55.2708);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    _serviceNameController.dispose();
    _areaController.dispose();
    _advertiserNameController.dispose();
    _contactProvider.removeListener(_onContactsLoaded);
    _contactProvider.dispose();
    super.dispose();
  }

  Future<void> _fetchAdDetails(int adId) async {
    setState(() => _isLoading = true);
    debugPrint('[CarServicesSaveAdScreen] _fetchAdDetails: start, adId=' + adId.toString());
    try {
      final repository = CarServicesAdRepository(ApiService());
      // استخدم المسار الأبسط المباشر: /api/car-services/:id
      final details = await repository.getCarServiceById(adId: adId);
      if (details == null) {
        debugPrint('[CarServicesSaveAdScreen] _fetchAdDetails: API returned null details for adId=' + adId.toString());
        setState(() {
          _adData = null;
        });
      } else {
        setState(() {
          _adData = details;
        });
        // Populate controllers once data is available
        _populateControllersFromAd();
      }
    } catch (e) {
      debugPrint('[CarServicesSaveAdScreen] _fetchAdDetails: exception=' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ad details: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[CarServicesSaveAdScreen] _fetchAdDetails: end, isLoading=' + _isLoading.toString() + ', hasData=' + (_adData != null).toString());
    }
  }

  void _populateControllersFromAd() {
    if (_adData == null) {
      debugPrint('[CarServicesSaveAdScreen] _populateControllersFromAd: _adData is null; skip populating controllers');
      return;
    }
    // تعبئة جميع الحقول من الداتا الفعلية
    _priceController.text = _adData!.price;
    _descriptionController.text = _adData!.description;
    _titleController.text = _adData!.title;
    _serviceNameController.text = _adData!.serviceName;
    _areaController.text = _adData!.area ?? '';
    _advertiserNameController.text = _adData!.advertiserName;
    selectedPhoneNumber = _adData!.phoneNumber;
    selectedWhatsAppNumber = _adData!.whatsapp;
    _controllersPopulated = true;
    // Populate existing thumbnails for combined display
    _existingThumbnailUrls
      ..clear()
      ..addAll(_adData!.thumbnailImages);
  }

  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _mainImageFile = File(image.path));
    }
  }

  Future<void> _pickThumbnailImages() async {
    const int maxThumbnails = 3;
    final int currentTotal = _existingThumbnailUrls.length + _thumbnailImageFiles.length;
    if (currentTotal >= maxThumbnails) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن إضافة المزيد من الصور. الحد الأقصى $maxThumbnails صور'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final int remainingSlots = maxThumbnails - currentTotal;
      List<File> newImages = images.map((x) => File(x.path)).toList();
      if (newImages.length > remainingSlots) {
        newImages = newImages.take(remainingSlots).toList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم اختيار ${newImages.length} صورة فقط. الحد الأقصى $maxThumbnails صورة إجمالية'), backgroundColor: Colors.orange),
          );
        }
      }
      setState(() {
        _thumbnailImageFiles.addAll(newImages);
      });
    }
  }

  void _removeThumbnailImage(int index) {
    if (index < 0 || index >= _thumbnailImageFiles.length) return;
    setState(() {
      _thumbnailImageFiles.removeAt(index);
    });
  }

  void _removeExistingThumbnail(int index) {
    if (index < 0 || index >= _existingThumbnailUrls.length) return;
    setState(() {
      _removedExistingThumbnailUrls.add(_existingThumbnailUrls[index]);
      _existingThumbnailUrls.removeAt(index);
    });
  }

  Future<File?> _downloadImageToTempFile(String imageUrl) async {
    try {
      final fullUrl = ImageUrlHelper.getFullImageUrl(imageUrl);
      final dio = Dio();
      final response = await dio.get(fullUrl, options: Options(responseType: ResponseType.bytes));
      final filename = 'car_service_thumb_${DateTime.now().millisecondsSinceEpoch}_${imageUrl.hashCode}.jpg';
      final file = File('${Directory.systemTemp.path}/$filename');
      await file.writeAsBytes(response.data);
      return file;
    } catch (_) {
      return null;
    }
  }

  void _loadContactInfo() async {
    final token = await _storage.read(key: 'auth_token');
    _contactProvider.addListener(_onContactsLoaded);
    await _contactProvider.fetchContactInfo(token: token);
    if (mounted) {
      setState(() {
        // Ensure UI shows fetched phone/WhatsApp lists even if provider doesn't notify
      });
    }
  }

  void _onContactsLoaded() {
    if (mounted) {
      setState(() {
        // rebuild to reflect updated contact lists
      });
    }
  }

  Future<void> _handleAddNewContact(String field, String value) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication token not found')));
      }
      return;
    }
    final success = await _contactProvider.addContactItem(field, value, token: token);
    if (success) {
      if (field == 'phone_numbers') setState(() => selectedPhoneNumber = value);
      if (field == 'whatsapp_numbers') setState(() => selectedWhatsAppNumber = value);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add contact')));
      }
    }
  }

  Future<void> _updateAd() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final repository = CarServicesAdRepository(ApiService());

      final String phone = (selectedPhoneNumber?.trim().isNotEmpty ?? false)
          ? selectedPhoneNumber!.trim()
          : (_adData?.phoneNumber ?? '').trim();
      final String? whatsapp = (selectedWhatsAppNumber?.trim().isNotEmpty ?? false)
          ? selectedWhatsAppNumber!.trim()
          : (_adData?.whatsapp?.trim().isNotEmpty ?? false)
              ? _adData!.whatsapp!.trim()
              : null;
      // دمج الصور المصغرة: تنزيل الباقي من الصور القديمة إلى ملفات + إضافة الصور الجديدة
      final keptExistingUrls = _existingThumbnailUrls.where((u) => !_removedExistingThumbnailUrls.contains(u)).toList();
      final List<File> existingFiles = [];
      for (final url in keptExistingUrls) {
        try {
          final file = await _downloadImageToTempFile(url);
          if (file != null) existingFiles.add(file);
        } catch (_) {
          // تجاهل فشل تنزيل صورة واحدة
        }
      }

      final List<File> mergedThumbnails = []
        ..addAll(existingFiles)
        ..addAll(_thumbnailImageFiles);

      await repository.updateCarServiceAd(
        adId: widget.adId!,
        token: token,
        price: _priceController.text.trim(),
        description: _descriptionController.text.trim(),
        phoneNumber: phone,
        whatsapp: whatsapp,
        mainImage: _mainImageFile,
        thumbnailImages: mergedThumbnails.isNotEmpty ? mergedThumbnails : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الإعلان بنجاح')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التحديث: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على نسخة من كلاس الترجمة
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);
    
    // قيم وهمية للحقول
    final emirateValue = _adData?.emirate ?? 'Dubai';
    final districtValue = _adData?.district ?? 'Ras Alkhor';
    final serviceTypeValue = _adData?.serviceType ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25.h),

              // Back Button - مطابق للتصميم السابق
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

              // Title - مطابق للتصميم السابق
              Center(
                child: Text(
                  s.carsServicesAds, // استخدام المفتاح الجديد
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 24.sp,
                    color: KTextColor,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              
              _buildFormRow([
                _buildReadOnlyField(s.emirate, _adData?.emirate ?? ""),
                _buildReadOnlyField(s.district, _adData?.district ?? ""),
                _buildReadOnlyField(s.area, _adData?.area ?? '-'),
              ]),
              const SizedBox(height: 7),

              _buildFormRow([
                _buildReadOnlyField(s.serviceType, _adData?.serviceType ?? serviceTypeValue),
                _buildReadOnlyField(s.serviceName, _adData?.serviceName ?? '-'),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.price, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
                    decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: Colors.white,
                        filled: true),
                  )
                ]),
              ]),
              const SizedBox(height: 7),

              _buildTitleBox(
                context,
                s.title,
                '',
                borderColor,
                currentLocale,
                controller: _titleController,
                readOnly: true,
              ),
              const SizedBox(height: 7),

              _buildReadOnlyField(s.advertiserName, _adData?.advertiserName ?? '-'),
              const SizedBox(height: 7),

              _buildFormRow([
                TitledSelectOrAddField(
                  title: s.phoneNumber,
                  value: selectedPhoneNumber ?? _adData?.phoneNumber,
                  items: _contactProvider.phoneNumbers,
                  onChanged: (v) { setState(() => selectedPhoneNumber = v); },
                  isNumeric: true,
                  onAddNew: (value) => _handleAddNewContact('phone_numbers', value),
                ),
                TitledSelectOrAddField(
                  title: s.whatsApp,
                  value: selectedWhatsAppNumber ?? _adData?.whatsapp,
                  items: _contactProvider.whatsappNumbers,
                  onChanged: (v) { setState(() => selectedWhatsAppNumber = v); },
                  isNumeric: true,
                  onAddNew: (value) => _handleAddNewContact('whatsapp_numbers', value),
                ),
              ]),
              const SizedBox(height: 7),
              
              // Description with controller for editing
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.description, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: null,
                      style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Main image picker
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_a_photo_outlined, color: KTextColor),
                  label: Text(s.addMainImage, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)),
                  onPressed: _pickMainImage,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                ),
              ),
              if (_mainImageFile != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_mainImageFile!, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
              ] else if (_adData?.mainImage != null && _adData!.mainImage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Builder(builder: (context) {
                    final mainUrl = ImageUrlHelper.getMainImageUrl(_adData!.mainImage!);
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
                              'assets/images/car_service.png',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        );
                      }
                    }
                    return Image.asset('assets/images/car_service.png', height: 140, width: double.infinity, fit: BoxFit.cover);
                  }),
                ),
              ],
              const SizedBox(height: 7),
              // Thumbnail images picker
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: KTextColor),
                  label: Text(s.add3Images, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)),
                  onPressed: _pickThumbnailImages,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                ),
              ),
              if (_existingThumbnailUrls.isNotEmpty || _thumbnailImageFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingThumbnailUrls.length + _thumbnailImageFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final bool isExisting = index < _existingThumbnailUrls.length;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            if (isExisting)
                              Builder(builder: (context) {
                                final url = ImageUrlHelper.getFullImageUrl(_existingThumbnailUrls[index]);
                                final uri = Uri.tryParse(url);
                                if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
                                  return Image.network(
                                    url,
                                    width: 120,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/car_service.png',
                                        width: 120,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  );
                                }
                                return Image.asset(
                                  'assets/images/car_service.png',
                                  width: 120,
                                  height: 100,
                                  fit: BoxFit.cover,
                                );
                              })
                            else
                              Image.file(
                                _thumbnailImageFiles[index - _existingThumbnailUrls.length],
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  if (isExisting) {
                                    _removeExistingThumbnail(index);
                                  } else {
                                    _removeThumbnailImage(index - _existingThumbnailUrls.length);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
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
              const SizedBox(height: 7),
              
              Text(
                s.location,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor),
              ),
              SizedBox(height: 4.h),
              
              Directionality(
                 textDirection: TextDirection.ltr,
                 child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 20.h),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        (() {
                          final loc = (_adData?.location?.trim().isNotEmpty ?? false)
                              ? _adData!.location!.trim()
                              : '${_adData?.emirate ?? ''} ${_adData?.district ?? ''} ${_adData?.area ?? ''}'.trim();
                          return loc.isNotEmpty ? loc : '-';
                        })(),
                        style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 8.h),

              _buildMapSection(context), // دالة الخريطة المأخوذة من الكود السابق
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          if ((widget.adId ?? 0) > 0) {
                            _updateAd();
                          } else {
                            context.push('/payment');
                          }
                        },
                  child: _isUpdating
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
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
      ),
    );
  }

  // --- دوال المساعدة المحدثة ---

  Widget _buildFormRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }

  Widget _buildTitledTextField(String title, String initialValue, Color borderColor, String currentLocale, {bool isNumber = false, TextEditingController? controller}) {
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: Colors.white,
      filled: true,
    );

    final textStyle = TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp);

    Widget field;
    if (controller != null) {
      field = TextFormField(
        controller: controller,
        style: textStyle,
        textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: inputDecoration,
      );
    } else {
      field = TextFormField(
        initialValue: initialValue,
        style: textStyle,
        textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: inputDecoration,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _buildTitledDropdownField(
      BuildContext context, String title, List<String> items, String? value, Color borderColor,
      {double? titleFontSize}) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: titleFontSize ?? 14.sp)),
      const SizedBox(height: 4),
      DropdownSearch<String>(
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
                  fillColor: Colors.white,
                  filled: true)),
          onChanged: (val) {})
    ]);
  }
  
  Widget _buildTitleBox(BuildContext context, String title, String initialValue,
      Color borderColor, String currentLocale, {TextEditingController? controller, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        if (controller != null)
          TextFormField(
            controller: controller,
            maxLines: null,
            readOnly: readOnly,
            style: TextStyle(fontWeight: FontWeight.w500, color: readOnly ? KDisabledTextColor : KTextColor, fontSize: 14.sp),
            textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? KDisabledColor : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? Colors.grey.shade400 : borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? Colors.grey.shade400 : borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? Colors.grey.shade400 : KPrimaryColor, width: readOnly ? 1 : 2)),
              contentPadding: EdgeInsets.all(12),
            ),
          )
        else
          TextFormField(
            initialValue: initialValue,
            maxLines: null,
            readOnly: readOnly,
            style: TextStyle(fontWeight: FontWeight.w500, color: readOnly ? KDisabledTextColor : KTextColor, fontSize: 14.sp),
            textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? KDisabledColor : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? Colors.grey.shade400 : borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? Colors.grey.shade400 : borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? Colors.grey.shade400 : KPrimaryColor, width: readOnly ? 1 : 2)),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
      ],
    );
  }

  // حقل عرض فقط موحد للحالات أحادية السطر
  Widget _buildReadOnlyField(String title, String value, {double? titleFontSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: titleFontSize ?? 14.sp)),
        const SizedBox(height: 4),
        Container(
          height: 48,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: KDisabledColor,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isNotEmpty ? value : '-',
            style: TextStyle(fontWeight: FontWeight.w500, color: KDisabledTextColor, fontSize: 12.sp),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton(String title, IconData icon, Color borderColor) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: Icon(icon, color: KTextColor), label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)), onPressed: () {}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
  }

  Widget _buildMapSection(BuildContext context) {
    final s = S.of(context);
    final ad = _adData;
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
                        title: (() {
                          final loc = (_adData?.location?.trim().isNotEmpty ?? false)
                              ? _adData!.location!.trim()
                              : '${_adData?.emirate ?? ''} ${_adData?.district ?? ''} ${_adData?.area ?? ''}'.trim();
                          return loc.isNotEmpty ? loc : s.location;
                        })(),
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
  final TextEditingController? controller;
  const TitledTextFieldWithAction({Key? key, required this.title, required this.initialValue, required this.borderColor, required this.onAddPressed, this.isNumeric = false, this.controller}) : super(key: key);
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
              controller: widget.controller,
              initialValue: widget.controller == null ? widget.initialValue : null,
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

// ---------------------------------------------
// Unified select/add field with searchable bottom sheet
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
  void didUpdateWidget(covariant TitledSelectOrAddField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _selectedValue = widget.value;
      });
    }
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