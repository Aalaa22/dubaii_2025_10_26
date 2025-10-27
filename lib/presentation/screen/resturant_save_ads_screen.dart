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
  
  const RestaurantsSaveAdScreen({Key? key, required this.adId}) : super(key: key);

  @override
  State<RestaurantsSaveAdScreen> createState() => _RestaurantsSaveAdScreenState();
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
        setState(() {
          _thumbnailImages.addAll(images.map((image) => File(image.path)));
          // Limit to 5 thumbnail images
          if (_thumbnailImages.length > 5) {
            _thumbnailImages = _thumbnailImages.take(5).toList();
          }
        });
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
        if (_descriptionController.text.trim() != (currentAd.description ?? '')) {
          updateData['description'] = _descriptionController.text.trim();
        }
        if (selectedPhoneNumber != currentAd.phoneNumber) {
          updateData['phone_number'] = selectedPhoneNumber != null
              ? PhoneNumberFormatter.formatForApi(selectedPhoneNumber!)
              : null;
        }
        if (selectedWhatsAppNumber != currentAd.whatsappNumber) {
          updateData['whatsapp_number'] = (selectedWhatsAppNumber != null && selectedWhatsAppNumber!.trim().isNotEmpty)
              ? PhoneNumberFormatter.formatForApi(selectedWhatsAppNumber!)
              : null;
        }
      }
      
      // Add images if selected
      if (_mainImage != null) {
        updateData['main_image'] = _mainImage;
      }
      if (_thumbnailImages.isNotEmpty) {
        updateData['thumbnail_images'] = _thumbnailImages;
      }
      
      if (updateData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد تغييرات للحفظ')),
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
          const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ التغييرات: $e')),
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
      appBar: AppBar(
        title: Text(s.edit),
        backgroundColor: Colors.white,
        foregroundColor: KTextColor,
        elevation: 1,
      ),
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
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
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
                      _buildDetailBox(s.advertiserName, ad.advertiserName ?? ''),
                      const SizedBox(height: 7),
                      
                      // Editable contact fields
                      _buildFormRow([
                        TitledSelectOrAddField(
                          title: s.phoneNumber,
                          value: selectedPhoneNumber,
                          items: infoProvider.phoneNumbers,
                          onChanged: (newValue) => setState(() => selectedPhoneNumber = newValue),
                          isNumeric: true,
                          onAddNew: (value) async {
                            final token = await const FlutterSecureStorage().read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem('phone_numbers', value, token: token);
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
                          onChanged: (newValue) => setState(() => selectedWhatsAppNumber = newValue),
                          isNumeric: true,
                          onAddNew: (value) async {
                            final token = await const FlutterSecureStorage().read(key: 'auth_token');
                            if (token != null) {
                              final success = await infoProvider.addContactItem('whatsapp_numbers', value, token: token);
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
                      ),
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
                      ],
                      const SizedBox(height: 10),
                      
                      _buildImageButton(
                        s.add9Images,
                        Icons.add_photo_alternate_outlined,
                        borderColor,
                        onPressed: _pickThumbnailImages,
                      ),
                      if (_thumbnailImages.isNotEmpty) ...[
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _thumbnailImages.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(
                  _thumbnailImages[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeThumbnailImage(index),
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
        Text(
          s.location,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
            color: KTextColor,
          ),
        ),
        SizedBox(height: 4.h),
        
        // Location display
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/locationicon.svg',
                width: 20.w,
                height: 20.h,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${ad.address  ?? ''}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: KTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        
        // Map container
        SizedBox(
          height: 220.h,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    'assets/images/map.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 80.h,
                left: 0,
                right: 0,
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40.sp,
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  label: Text(
                    s.locateMe,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implement locate me functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01547E),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom widgets needed for the screen
class TitledSelectOrAddField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final s = S.of(context);
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
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _SearchableSelectOrAddBottomSheet(
                title: title,
                items: items,
                isNumeric: isNumeric,
                onAddNew: onAddNew,
              ),
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value ?? s.chooseAnOption,
                    style: TextStyle(
                      fontWeight: value == null ? FontWeight.normal : FontWeight.w500,
                      color: value == null ? Colors.grey.shade500 : KTextColor,
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((i) => i.toLowerCase().contains(query)).toList();
    });
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
                      onChanged: (value) => setState(() => _selectedCountryCode = value!),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                          borderSide: const BorderSide(color: KPrimaryColor, width: 2),
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
                    keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
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
                        borderSide: const BorderSide(color: KPrimaryColor, width: 2),
                      ),
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
                      // Close first, then add asynchronously
                      Navigator.pop(context, result);
                      if (widget.onAddNew != null) {
                        Future.microtask(() => widget.onAddNew!(result));
                      }
                    }
                  },
                  child: Text(
                    s.add,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    minimumSize: const Size(60, 48),
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

class TitledDescriptionBox extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final Color borderColor;
  final int maxLength;
  final String? hintText;

  const TitledDescriptionBox({
    Key? key,
    required this.title,
    required this.controller,
    required this.borderColor,
    this.maxLength = 5000,
    this.hintText,
  }) : super(key: key);

  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}

class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: KTextColor,
            fontSize: 14.sp,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: widget.borderColor),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: widget.controller,
                maxLines: null,
                minLines: 3,
                maxLength: widget.maxLength,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: KTextColor,
                  fontSize: 14.sp,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  counterText: "",
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${widget.controller.text.length}/${widget.maxLength}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}