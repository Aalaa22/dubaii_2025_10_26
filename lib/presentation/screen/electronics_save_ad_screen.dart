import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/electronic_details_provider.dart';
import 'package:advertising_app/presentation/providers/electronics_info_provider.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:advertising_app/data/model/electronics_ad_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/repository/electronics_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/google_maps_provider.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class ElectronicsSaveAdScreen extends StatefulWidget {
  // استقبال دالة تغيير اللغة و معرف الإعلان
  final Function(Locale) onLanguageChange;
  final int adId;

  const ElectronicsSaveAdScreen({Key? key, required this.onLanguageChange, required this.adId})
      : super(key: key);

  @override
  _ElectronicsSaveAdScreenState createState() => _ElectronicsSaveAdScreenState();
}

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
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      _filteredItems = widget.items
          .where((i) => i.toLowerCase().contains(query))
          .toList();
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
                      if (widget.onAddNew != null) await widget.onAddNew!(result);
                      Navigator.pop(context, result);
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
          ],
        ),
      ),
    );
  }
}

class _ElectronicsSaveAdScreenState extends State<ElectronicsSaveAdScreen> {
  // Controllers for editable fields
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;
  
  // Image handling variables
  File? _mainImageFile;
  final List<File> _thumbnailImageFiles = [];
  final List<String> _existingThumbnailUrls = [];
  final List<String> _removedExistingThumbnailUrls = [];
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool _isUpdating = false;
  ElectronicAdModel? _adData;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    _loadAdData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _loadAdData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ElectronicDetailsProvider>(context, listen: false);
      await provider.fetchAdDetails(widget.adId);
      
      if (provider.adDetails != null) {
        _adData = provider.adDetails;
        _populateControllers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ad data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (_adData != null) {
      _priceController.text = _adData!.price ?? '';
      _descriptionController.text = _adData!.description ?? '';
      _phoneController.text = _adData!.phoneNumber ?? '';
      _whatsappController.text = _adData!.whatsappNumber ?? '';
      selectedPhoneNumber = _adData!.phoneNumber;
      selectedWhatsAppNumber = _adData!.whatsappNumber;

      // Populate existing thumbnails from ad data
      _existingThumbnailUrls.clear();
      if (_adData!.thumbnailImages.isNotEmpty) {
        _existingThumbnailUrls.addAll(_adData!.thumbnailImages);
      }
    }
  }

  // Image picker methods
  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _mainImageFile = File(image.path));
    }
  }

  Future<void> _pickThumbnailImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      // إجمالي الصور المختارة = الموجوده + الجديدة
      final int currentTotal = _existingThumbnailUrls.length + _thumbnailImageFiles.length;
      int availableSlots = 4 - currentTotal;
      if (availableSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن اختيار المزيد من الصور. الحد الأقصى  4'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      List<File> newImages = images.map((xfile) => File(xfile.path)).toList();
      
      // إذا كان العدد الجديد يتجاوز الحد المسموح
      if (newImages.length > availableSlots) {
        // أخذ فقط العدد المسموح به
        newImages = newImages.take(availableSlots).toList();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختيار ${newImages.length} صورة فقط. الحد الأقصى هو 19 صورة إجمالية'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      setState(() {
        _thumbnailImageFiles.addAll(newImages);
      });
    }
  }

  void _removeExistingThumbnail(int index) {
    setState(() {
      final removed = _existingThumbnailUrls.removeAt(index);
      _removedExistingThumbnailUrls.add(removed);
    });
  }

  void _removeNewThumbnail(int index) {
    setState(() {
      _thumbnailImageFiles.removeAt(index);
    });
  }

  Future<void> _saveAd() async {
    if (_adData == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Get token from secure storage
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final repository = ElectronicsRepository(ApiService());

      final String phone = (selectedPhoneNumber?.trim().isNotEmpty ?? false)
          ? selectedPhoneNumber!.trim()
          : (_adData?.phoneNumber ?? _phoneController.text).trim();
      final String? whatsapp = (selectedWhatsAppNumber?.trim().isNotEmpty ?? false)
          ? selectedWhatsAppNumber!.trim()
          : (_adData?.whatsappNumber?.trim().isNotEmpty ?? false)
              ? _adData!.whatsappNumber!.trim()
              : null;

      // Merge existing (kept) thumbnails by downloading them into temp files
      final List<File> combinedThumbnails = [];

      // Keep new thumbnails
      combinedThumbnails.addAll(_thumbnailImageFiles);

      // Add existing thumbnails that were not removed
      for (final url in _existingThumbnailUrls) {
        if (!_removedExistingThumbnailUrls.contains(url)) {
          final file = await _downloadImageToTempFile(url);
          if (file != null) {
            combinedThumbnails.add(file);
          }
        }
      }

      await repository.updateElectronicsAd(
        adId: widget.adId,
        token: token,
        price: _priceController.text,
        description: _descriptionController.text,
        phoneNumber: phone,
        whatsappNumber: whatsapp,
        mainImage: _mainImageFile,
        thumbnailImages: combinedThumbnails.isNotEmpty ? combinedThumbnails : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad updated successfully')),
      );
      
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ad: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  // Download an image URL/path to a temporary file for multipart upload
  Future<File?> _downloadImageToTempFile(String url) async {
    try {
      final String fullUrl = ImageUrlHelper.getFullImageUrl(url);
      final dio = Dio();
      final response = await dio.get(fullUrl, options: Options(responseType: ResponseType.bytes));
      final List<int> bytes = (response.data as List<int>);
      final tempDir = await getTemporaryDirectory();
      final filename = p.basename(Uri.parse(fullUrl).path);
      final file = File(p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_$filename'));
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Failed to download image "$url" to temp file: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على نسخة من كلاس الترجمة
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: KPrimaryColor),
        ),
      );
    }

    if (_adData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Failed to load ad data', style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAdData,
                child: Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25.h),

              // Back Button (مثل الشاشات السابقة)
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    SizedBox(width: 5.w),
                    Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
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
                  ],
                ),
              ),
              SizedBox(height: 7.h),
              
              Center(
                child: Text(
                  s.electronicsAndHomeAppliancesAds,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 24.sp,
                    color: KTextColor,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              
              _buildFormRow([
                _buildReadOnlyField(s.emirate, _adData!.emirate ?? 'N/A', borderColor),
                _buildReadOnlyField(s.district, _adData!.district ?? 'N/A', borderColor),
              ]),
              const SizedBox(height: 7),

              _buildFormRow([
                _buildReadOnlyField(s.area, _adData!.area ?? 'N/A', borderColor),
                _buildEditableTextField(s.price, _priceController, borderColor, currentLocale, isNumber: true),
              ]),
              const SizedBox(height: 7),

              _buildFormRow([
                _buildReadOnlyField(s.productName, _adData!.productName ?? 'N/A', borderColor),
                _buildReadOnlyField(s.sectionType, _adData!.sectionType ?? 'N/A', borderColor),
              ]),
              const SizedBox(height: 7),

              _buildReadOnlyTitleBox(s.title, _adData!.title ?? 'N/A', borderColor),
              const SizedBox(height: 7),

              _buildReadOnlyField(s.advertiserName, _adData!.advertiserName ?? 'N/A', borderColor),
              const SizedBox(height: 7),

              _buildFormRow([
                Consumer<ElectronicsInfoProvider>(
                  builder: (context, infoProvider, child) {
                    final phoneItems = infoProvider.phoneNumbers.isNotEmpty
                        ? infoProvider.phoneNumbers
                        : [_adData!.phoneNumber ?? ''];
                    return TitledSelectOrAddField(
                      title: s.phoneNumber,
                      value: selectedPhoneNumber,
                      items: phoneItems,
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
                    );
                  },
                ),
                Consumer<ElectronicsInfoProvider>(
                  builder: (context, infoProvider, child) {
                    final whatsappItems = infoProvider.whatsappNumbers.isNotEmpty
                        ? infoProvider.whatsappNumbers
                        : [_adData!.whatsappNumber ?? ''];
                    return TitledSelectOrAddField(
                      title: s.whatsApp,
                      value: selectedWhatsAppNumber,
                      items: whatsappItems,
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
                    );
                  },
                ),
              ]),
              const SizedBox(height: 7),

              _buildEditableDescriptionBox(s.description, _descriptionController, borderColor),
              const SizedBox(height: 10),

              // التعامل مع الصور
              _buildImageButton(s.addMainImage, Icons.add_a_photo_outlined, borderColor, onPressed: _pickMainImage),
              if(_mainImageFile != null) ...[
                const SizedBox(height: 4), 
                Text('  تم اختيار صورة رئيسية جديدة', style: TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_mainImageFile!, fit: BoxFit.cover),
                  ),
                ),
              ] else if ((_adData?.mainImage?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 4),
                Text('  الصورة الرئيسية الحالية', style: TextStyle(color: KTextColor)),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: ImageUrlHelper.getFullImageUrl(_adData!.mainImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 7),
              _buildImageButton(s.add4Images, Icons.add_photo_alternate_outlined, borderColor, onPressed: _pickThumbnailImages),
              if(_existingThumbnailUrls.isNotEmpty || _thumbnailImageFiles.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('  إجمالي الصور المختارة: ${_existingThumbnailUrls.length + _thumbnailImageFiles.length} / 4', style: TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingThumbnailUrls.length + _thumbnailImageFiles.length,
                    itemBuilder: (context, index) {
                      final bool isExisting = index < _existingThumbnailUrls.length;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isExisting
                                  ? CachedNetworkImage(
                                      imageUrl: ImageUrlHelper.getFullImageUrl(_existingThumbnailUrls[index]),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(_thumbnailImageFiles[index - _existingThumbnailUrls.length], fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  if (isExisting) {
                                    _removeExistingThumbnail(index);
                                  } else {
                                    _removeNewThumbnail(index - _existingThumbnailUrls.length);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(2),
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
              const SizedBox(height: 10),

              // قسم الموقع
              Text(s.location, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor)),
              SizedBox(height: 4.h),

              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 20.h),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(_adData!.addres.toString(), style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500)),
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
                  onPressed: _isUpdating ? null : _saveAd,
                  child: _isUpdating 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Updating...', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      )
                    : Text(s.save, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUpdating ? Colors.grey : KPrimaryColor,
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

  String _getAdLocation() {
    if (_adData == null) return 'N/A';
    
    List<String> locationParts = [];
    if (_adData!.emirate != null && _adData!.emirate!.isNotEmpty) {
      locationParts.add(_adData!.emirate!);
    }
    if (_adData!.district != null && _adData!.district!.isNotEmpty) {
      locationParts.add(_adData!.district!);
    }
    if (_adData!.area != null && _adData!.area!.isNotEmpty) {
      locationParts.add(_adData!.area!);
    }
    
    return locationParts.isNotEmpty ? locationParts.join(' - ') : 'N/A';
  }

  Widget _buildFormRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }

  Widget _buildReadOnlyField(String title, String value, Color borderColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600], fontSize: 12.sp),
        ),
      ),
    ]);
  }

  Widget _buildEditableTextField(String title, TextEditingController controller,
      Color borderColor, String currentLocale,
      {bool isNumber = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
          controller: controller,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.white,
              filled: true))
    ]);
  }

  Widget _buildReadOnlyTitleBox(String title, String value, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600], fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildEditablePhoneField(String title, TextEditingController controller, Color borderColor) {
    final s = S.of(context);
    final addButtonWidth = (s.add.length * 8.0) + 24.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(left: 16, right: addButtonWidth, top: 12, bottom: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                fillColor: Colors.white, filled: true,
              ),
            ),
            Positioned(
              right: 1, top: 1, bottom: 1,
              child: GestureDetector(
                onTap: () {
                  // Handle add functionality for phone numbers
                  print("${title} Add clicked");
                },
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

  Widget _buildEditableDescriptionBox(String title, TextEditingController controller, Color borderColor) {
    const int maxLength = 5000;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
          child: Column(
            children: [
              TextFormField(
                controller: controller,
                maxLines: null,
                maxLength: maxLength,
                style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), counterText: ""),
                onChanged: (value) {
                  setState(() {}); // Rebuild to update character count
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text('${controller.text.length}/$maxLength', style: TextStyle(color: Colors.grey, fontSize: 12), textDirection: TextDirection.ltr)),
              )
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildImageButton(String title, IconData icon, Color borderColor, {required VoidCallback onPressed}) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: Icon(icon, color: KTextColor), label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)), onPressed: onPressed, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
  }

  Widget _buildMapSection(BuildContext context) {
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
              future: _getAdLatLng(ad),
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
                        title: (ad?.addres?.isNotEmpty == true || ad?.location.isNotEmpty == true)
                            ? 'الموقع المحدد'
                            : (ad?.emirate ?? 'الموقع'),
                        snippet: ad?.addres?.isNotEmpty == true
                            ? ad!.addres
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

  // Helper: compute ad LatLng from address or emirate
  Future<LatLng> _getAdLatLng(ElectronicAdModel? ad) async {
    try {
      final String? addr = ad?.addres?.trim();
      final String? loc = ad?.location?.trim();
      final String query = (addr != null && addr.isNotEmpty)
          ? addr
          : (loc != null && loc.isNotEmpty ? loc : '');
      if (query.isNotEmpty) {
        final locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          final first = locations.first;
          return LatLng(first.latitude, first.longitude);
        }
      }
    } catch (e) {
      debugPrint('Geocoding failed for electronics ad: $e');
    }

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
    return const LatLng(25.2048, 55.2708);
  }
}
