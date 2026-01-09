import 'dart:io';
import 'package:advertising_app/constant/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/presentation/widget/titled_select_or_add_field.dart';
import 'package:advertising_app/constant/image_url_helper.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n.dart';
import '../providers/google_maps_provider.dart';
import '../providers/restaurant_details_provider.dart';
import '../providers/restaurants_info_provider.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';

const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class RestaurantsSaveAdScreen extends StatefulWidget {
  final String adId;

  const RestaurantsSaveAdScreen({Key? key, required this.adId})
      : super(key: key);

  @override
  State<RestaurantsSaveAdScreen> createState() =>
      _RestaurantsSaveAdScreenState();
}

class _RestaurantsSaveAdScreenState extends State<RestaurantsSaveAdScreen> {
  // Controllers for editable fields
  final TextEditingController _priceRangeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Contact info
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;

  // Images
  File? _mainImage;
  List<File> _thumbnailImages = [];
  final ImagePicker _picker = ImagePicker();
  // Existing thumbnails (URLs) and removed ones
  List<String> _existingThumbnailUrls = [];
  final List<String> _removedExistingThumbnailUrls = [];

  // Loading states
  bool _isLoading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  @override
  void dispose() {
    _priceRangeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantData() async {
    setState(() => _isLoading = true);

    try {
      final detailsProvider = context.read<RestaurantDetailsProvider>();
      final infoProvider = context.read<RestaurantsInfoProvider>();

      // Load restaurant details
      await detailsProvider.fetchAdDetails(int.parse(widget.adId));

      // Load contact info
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token != null) {
        await infoProvider.fetchContactInfo(token: token);
      }

      // Populate editable fields with current data
      final ad = detailsProvider.adDetails;
      if (ad != null) {
        _priceRangeController.text = ad.priceRange ?? '';
        _descriptionController.text = ad.description ?? '';
        selectedPhoneNumber = ad.phoneNumber;
        selectedWhatsAppNumber = ad.whatsappNumber;

        // Populate existing thumbnails from ad
        final urls = (ad.thumbnailImagesUrls.isNotEmpty)
            ? ad.thumbnailImagesUrls
            : ImageUrlHelper.getThumbnailImageUrls(ad.thumbnailImages);
        _existingThumbnailUrls = urls.toList();
      }
    } catch (e) {
      debugPrint('Error loading restaurant data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickMainImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _mainImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking main image: $e');
    }
  }

  Future<void> _pickThumbnailImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final int currentTotal =
            _existingThumbnailUrls.length + _thumbnailImages.length;
        final int maxAllowed = 3;
        int availableSlots = maxAllowed - currentTotal;

        if (availableSlots <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('لا يمكنك إضافة أكثر من 3 صور فرعية.')),
            );
          }
        } else {
          final filesToAdd = images
              .take(availableSlots)
              .map((image) => File(image.path))
              .toList();
          setState(() {
            _thumbnailImages.addAll(filesToAdd);
          });
          if (images.length > availableSlots && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('تم تجاوز الحد الأقصى، تمت إضافة أول 3 صور فقط.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking thumbnail images: $e');
    }
  }

  void _removeThumbnailImage(int index) {
    setState(() {
      _thumbnailImages.removeAt(index);
    });
  }

  void _removeExistingThumbnail(int index) {
    if (index >= 0 && index < _existingThumbnailUrls.length) {
      setState(() {
        final url = _existingThumbnailUrls[index];
        _removedExistingThumbnailUrls.add(url);
        _existingThumbnailUrls.removeAt(index);
      });
    }
  }

  Future<File> _downloadImageToTempFile(String url) async {
    final dio = Dio();
    final dir = await getTemporaryDirectory();
    final fileName =
        'restaurant_thumb_${DateTime.now().millisecondsSinceEpoch}${p.extension(url)}';
    final filePath = p.join(dir.path, fileName);
    await dio.download(url, filePath);
    return File(filePath);
  }

  Future<void> _saveChanges() async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      final detailsProvider = context.read<RestaurantDetailsProvider>();

      // Prepare update data
      final updateData = <String, dynamic>{};

      // Add changed fields
      final currentAd = detailsProvider.adDetails;
      if (currentAd != null) {
        if (_priceRangeController.text.trim() != (currentAd.priceRange ?? '')) {
          updateData['price_range'] = _priceRangeController.text.trim();
        }
        if (_descriptionController.text.trim() !=
            (currentAd.description ?? '')) {
          updateData['description'] = _descriptionController.text.trim();
        }
        if (selectedPhoneNumber != currentAd.phoneNumber) {
          updateData['phone_number'] = selectedPhoneNumber != null
              ? PhoneNumberFormatter.formatForApi(selectedPhoneNumber!)
              : null;
        }
        if (selectedWhatsAppNumber != currentAd.whatsappNumber) {
          updateData['whatsapp_number'] = (selectedWhatsAppNumber != null &&
                  selectedWhatsAppNumber!.trim().isNotEmpty)
              ? PhoneNumberFormatter.formatForApi(selectedWhatsAppNumber!)
              : null;
        }
      }

      // Add images if selected
      if (_mainImage != null) {
        updateData['main_image'] = _mainImage;
      }
      // Merge kept existing thumbnails with new ones by downloading existing URLs to files
      final keptExistingUrls = _existingThumbnailUrls
          .where((url) => !_removedExistingThumbnailUrls.contains(url))
          .toList();
      final existingFiles = <File>[];
      for (final url in keptExistingUrls) {
        final fullUrl = ImageUrlHelper.getFullImageUrl(url);
        try {
          final file = await _downloadImageToTempFile(fullUrl);
          existingFiles.add(file);
        } catch (e) {
          debugPrint('Failed to download existing thumbnail: $e');
        }
      }
      final mergedThumbnails = <File>[];
      mergedThumbnails
        ..addAll(existingFiles)
        ..addAll(_thumbnailImages);
      if (mergedThumbnails.isNotEmpty) {
        updateData['thumbnail_images'] = mergedThumbnails;
      }

      if (updateData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.noChangesToSave,
              textDirection: Directionality.of(context),
            ),
          ),
        );
        return;
      }

      // Update the restaurant ad
      await detailsProvider.updateRestaurantAd(
        adId: int.parse(widget.adId),
        priceRange: updateData['price_range'],
        description: updateData['description'],
        phoneNumber: updateData['phone_number'],
        whatsappNumber: updateData['whatsapp_number'],
        mainImage: updateData['main_image'],
        thumbnailImages: updateData['thumbnail_images'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.saveSuccess,
              textDirection: Directionality.of(context),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.saveFailed(e.toString()),
              textDirection: Directionality.of(context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<RestaurantDetailsProvider, RestaurantsInfoProvider>(
              builder: (context, detailsProvider, infoProvider, child) {
                final ad = detailsProvider.adDetails;

                if (ad == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'لم يتم العثور على الإعلان',
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 25.h),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(children: [
                          SizedBox(width: 5.w),
                          Icon(Icons.arrow_back_ios,
                              color: KTextColor, size: 20.sp),
                          Transform.translate(
                            offset: Offset(-3.w, 0),
                            child: Text(
                              s.back,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: KTextColor,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      SizedBox(height: 7.h),
                      Center(
                        child: Text(
                          s.restaurantsAds,
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
                        _buildDetailBox(s.emirate, ad.emirate ?? ''),
                        _buildDetailBox(s.district, ad.district ?? ''),
                      ]),
                      const SizedBox(height: 7),

                      _buildFormRow([
                        _buildDetailBox(s.category, ad.category ?? ''),
                        _buildDetailBox(s.area, ad.area ?? ''),
                      ]),
                      const SizedBox(height: 7),

                      // Editable price range field
                      _buildTitledTextFormField(
                        s.price,
                        _priceRangeController,
                        borderColor,
                        hintText: 'AED 50-100',
                        isRequired: true,
                      ),
                      const SizedBox(height: 7),

                      // Read-only title field
                      _buildDetailBox(s.title, ad.title ?? ''),
                      const SizedBox(height: 7),

                      // Read-only advertiser name
                      _buildDetailBox(
                          s.advertiserName, ad.advertiserName ?? ''),
                      const SizedBox(height: 7),

                      // Editable contact fields
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
                              if (success && mounted) {
                                setState(() => selectedPhoneNumber = value);
                              }
                            }
                          },
                        ),
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
                              if (success && mounted) {
                                setState(() => selectedWhatsAppNumber = value);
                              }
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 7),

                      // Editable description field
                      TitledDescriptionBox(
                          title: s.description,
                          controller: _descriptionController,
                          borderColor: borderColor,
                          minLines: 3,
                          maxLength: 5000),
                      const SizedBox(height: 10),

                      // Image upload sections
                      _buildImageButton(
                        s.addMainImage,
                        Icons.add_a_photo_outlined,
                        borderColor,
                        onPressed: _pickMainImage,
                      ),
                      if (_mainImage != null) ...[
                        const SizedBox(height: 8),
                        _buildSelectedImage(_mainImage!, isMain: true),
                      ] else if (ad?.mainImage != null &&
                          ad!.mainImage!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Builder(
                            builder: (context) {
                              final mainUrl = ImageUrlHelper.getMainImageUrl(
                                  ad!.mainImage!);
                              if (mainUrl.isNotEmpty) {
                                final uri = Uri.tryParse(mainUrl);
                                if (uri != null &&
                                    uri.hasScheme &&
                                    uri.host.isNotEmpty) {
                                  return Image.network(
                                    mainUrl,
                                    height: 200.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/restaurant.jpg',
                                        height: 200.h,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  );
                                }
                              }
                              return Image.asset(
                                'assets/images/restaurant.jpg',
                                height: 200.h,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      _buildImageButton(
                        s.add3Images,
                        Icons.add_photo_alternate_outlined,
                        borderColor,
                        onPressed: _pickThumbnailImages,
                      ),
                      if (_existingThumbnailUrls.isNotEmpty ||
                          _thumbnailImages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildThumbnailImagesGrid(),
                      ],
                      const SizedBox(height: 10),

                      // Map section
                      _buildMapSection(context, ad),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF01547E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _isUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  s.save,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Helper methods
  Widget _buildFormRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((child) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: child,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDetailBox(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: KTextColor,
            fontSize: 14.sp,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: value.isEmpty ? Colors.grey : KTextColor,
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitledTextFormField(
    String title,
    TextEditingController controller,
    Color borderColor, {
    String? hintText,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KTextColor,
                fontSize: 14.sp,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: KTextColor,
            fontSize: 12.sp,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: KTextColor, width: 2),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton(
    String title,
    IconData icon,
    Color borderColor, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(icon, color: KTextColor),
          label: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: KTextColor,
              fontSize: 16.sp,
            ),
          ),
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ));
  }

  Widget _buildSelectedImage(File image, {bool isMain = false}) {
    return Container(
      height: isMain ? 200.h : 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.file(
              image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isMain) {
                    _mainImage = null;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImagesGrid() {
    final totalCount = _existingThumbnailUrls.length + _thumbnailImages.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        final isExisting = index < _existingThumbnailUrls.length;
        final existingIndex = index;
        final newIndex = index - _existingThumbnailUrls.length;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: isExisting
                    ? CachedNetworkImage(
                        imageUrl: ImageUrlHelper.getFullImageUrl(
                            _existingThumbnailUrls[existingIndex]),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (ctx, _) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (ctx, _, __) =>
                            const Center(child: Icon(Icons.broken_image)),
                      )
                    : Image.file(
                        _thumbnailImages[newIndex],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    if (isExisting) {
                      _removeExistingThumbnail(existingIndex);
                    } else {
                      _removeThumbnailImage(newIndex);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
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

  Widget _buildMapSection(BuildContext context, dynamic ad) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                child: Text('${ad.address ?? ''}',
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: KTextColor,
                        fontWeight: FontWeight.w500))),
          ]),
        ),
        SizedBox(height: 8.h),
        Consumer<GoogleMapsProvider>(
          builder: (context, mapsProvider, child) {
            return Container(
              height: 320.h,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: FutureBuilder<LatLng>(
                  future: _getAdLocation(ad),
                  builder: (context, snapshot) {
                    LatLng adLocation = const LatLng(25.2048, 55.2708);
                    if (snapshot.hasData) adLocation = snapshot.data!;

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
                            title: (ad.address != null &&
                                    (ad.address as String).isNotEmpty)
                                ? 'الموقع المحدد'
                                : (ad.emirate ?? 'الموقع'),
                            snippet: (ad.address != null &&
                                    (ad.address as String).isNotEmpty)
                                ? (ad.address as String)
                                : (ad.area ?? ''),
                          ),
                        ),
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper: resolve restaurant ad address/emirate into coordinates
  Future<LatLng> _getAdLocation(dynamic ad) async {
    try {
      final String? addr = ad?.address as String?;
      if (addr != null && addr.trim().isNotEmpty) {
        final locations = await locationFromAddress(addr);
        if (locations.isNotEmpty) {
          final first = locations.first;
          return LatLng(first.latitude, first.longitude);
        }
      }
    } catch (e) {
      debugPrint('Geocoding failed for restaurant address: $e');
    }

    final String? emirate = ad?.emirate as String?;
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

    return const LatLng(25.2048, 55.2708);
  }
}
