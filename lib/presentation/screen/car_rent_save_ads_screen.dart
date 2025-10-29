import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/data/model/car_rent_ad_model.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/car_rent_ad_provider.dart';
import 'package:advertising_app/presentation/providers/car_rent_info_provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

final Color borderColor = const Color.fromRGBO(8, 194, 201, 1);


class CarsRentSaveAdScreen extends StatefulWidget {
  // استقبال دالة تغيير اللغة و adId
  final Function(Locale) onLanguageChange;
  final String? adId;

  const CarsRentSaveAdScreen({
    Key? key, 
    required this.onLanguageChange,
    this.adId,
  }) : super(key: key);

  @override
  State<CarsRentSaveAdScreen> createState() => _CarsRentSaveAdScreenState();
}

class _CarsRentSaveAdScreenState extends State<CarsRentSaveAdScreen> {
  // Controllers for editable fields
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dayRentController = TextEditingController();
  final TextEditingController _monthRentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Contact info controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _advertiserNameController = TextEditingController();
  
  // State variables for TitledSelectOrAddField
  String? selectedAdvertiserName;
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;
  
  // Image variables
  File? _mainImage;
  List<File> _thumbnailImages = [];
  List<String> _existingThumbnailUrls = [];
  List<String> _removedThumbnailUrls = [];
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    // بعد الإطار الأول: جلب معلومات الاتصال ثم تفاصيل الإعلان إن وُجدت
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final infoProvider = Provider.of<CarRentInfoProvider>(context, listen: false);
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      await infoProvider.fetchContactInfo(token: token);

      if (widget.adId != null) {
        _fetchAdDetails();
      }
    });
  }
  
  @override
  void dispose() {
    _priceController.dispose();
    _dayRentController.dispose();
    _monthRentController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _advertiserNameController.dispose();
    super.dispose();
  }
  
  void _fetchAdDetails() {
    final provider = Provider.of<CarRentAdProvider>(context, listen: false);
    provider.fetchAdDetails(widget.adId!).then((_) {
      if (provider.currentAd != null) {
        _populateFields(provider.currentAd!);
      }
    });
  }
  
  void _populateFields(CarRentAdModel ad) {
    _priceController.text = ad.price ?? '';
    _dayRentController.text = ad.dayRent ?? '';
    _monthRentController.text = ad.monthRent ?? '';
    _descriptionController.text = ad.description ?? '';
    _phoneController.text = ad.phoneNumber ?? '';
    _whatsappController.text = ad.whatsapp ?? '';
    _advertiserNameController.text = ad.advertiserName ?? '';
    
    // Set existing thumbnail URLs
    _existingThumbnailUrls = List<String>.from(ad.thumbnailImages ?? []);

    // تهيئة القيم المختارة لحقول الاتصال من بيانات الإعلان
    setState(() {
      selectedPhoneNumber = ad.phoneNumber;
      selectedWhatsAppNumber = ad.whatsapp;
      selectedAdvertiserName = ad.advertiserName;
    });
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على نسخة من كلاس الترجمة
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<CarRentAdProvider>(
        builder: (context, provider, child) {
          if (widget.adId != null && provider.isLoadingAdDetails) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final ad = provider.currentAd;
          
          return SingleChildScrollView(
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
                       s.carsRentAds,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 24.sp,
                        color: KTextColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  
                  // Read-only fields for editing mode
                  if (widget.adId != null && ad != null) ...[
                    _buildFormRow([
                      _buildReadOnlyField(s.emirate, ad.emirate ?? '', borderColor),
                      _buildReadOnlyField(s.make, ad.make ?? '', borderColor),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      _buildReadOnlyField(s.model, ad.model ?? '', borderColor),
                      _buildReadOnlyField(s.trim, ad.trim ?? '', borderColor),
                      _buildTitledTextField(s.price, '', borderColor, currentLocale, 
                          controller: _priceController, isNumber: true),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      _buildReadOnlyField(s.year, ad.year ?? '', borderColor),
                      _buildReadOnlyField(s.dayRent, ad.dayRent ?? '', borderColor),
                      _buildReadOnlyField(s.monthRent, ad.monthRent ?? '', borderColor),
                    ]),
                    const SizedBox(height: 7),
                    
                    _buildTitleBox(context, s.title, ad.title ?? '', borderColor, currentLocale, 
                         readOnly: true),
                    const SizedBox(height: 7),
                    
                    _buildFormRow([
                      _buildReadOnlyField(s.carType, ad.carType ?? '', borderColor),
                      _buildReadOnlyField(s.transType, ad.transType ?? '', borderColor),
                      _buildReadOnlyField(s.fuelType, ad.fuelType ?? '', borderColor),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      _buildReadOnlyField(s.color, ad.color ?? '', borderColor),
                      _buildReadOnlyField(s.interiorColor, ad.interiorColor ?? '', borderColor),
                      _buildReadOnlyField(s.seatsNo, ad.seatsNo ?? '', borderColor),
                    ]),
                    const SizedBox(height: 7),
                    
                    _buildReadOnlyField(s.advertiserName, ad.advertiserName ?? '', borderColor),
                    const SizedBox(height: 7),
                    
                    _buildFormRow([
                      Consumer<CarRentInfoProvider>(
                        builder: (context, infoProvider, child) {
                          return TitledSelectOrAddField(
                            title: s.phoneNumber,
                            value: selectedPhoneNumber,
                            items: infoProvider.phoneNumbers.isNotEmpty 
                                ? infoProvider.phoneNumbers 
                                : [ad.phoneNumber ?? ''],
                            onChanged: (newValue) => setState(() => selectedPhoneNumber = newValue),
                            onAddNew: (value) async {
                              final token = await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
                              final success = await infoProvider.addContactItem('phone_numbers', value, token: token);
                              if (success) {
                                setState(() => selectedPhoneNumber = value);
                              }
                            },
                            isNumeric: true,
                          );
                        },
                      ),
                      Consumer<CarRentInfoProvider>(
                        builder: (context, infoProvider, child) {
                          return TitledSelectOrAddField(
                            title: s.whatsApp,
                            value: selectedWhatsAppNumber,
                            items: infoProvider.whatsappNumbers.isNotEmpty 
                                ? infoProvider.whatsappNumbers 
                                : [ad.whatsapp ?? ''],
                            onChanged: (newValue) => setState(() => selectedWhatsAppNumber = newValue),
                            onAddNew: (value) async {
                              final token = await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
                              final success = await infoProvider.addContactItem('whatsapp_numbers', value, token: token);
                              if (success) {
                                setState(() => selectedWhatsAppNumber = value);
                              }
                            },
                            isNumeric: true,
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 7),
                    
                    // _buildFormRow([
                    //   _buildReadOnlyField(s.emirate, ad.emirate ?? '', borderColor),
                    //   _buildReadOnlyField(s.district, ad.district ?? '', borderColor),
                    // ]),
                    // const SizedBox(height: 7),
                    
                    _buildReadOnlyField(s.area, ad.area ?? 'N/A', borderColor),
                    const SizedBox(height: 7),

                  ] else ...[
                    // Original form fields for new ads
                    _buildFormRow([
                      _buildTitledDropdownField(
                          context, s.emirate, ['Dubai', 'Abu Dhabi'], ad!.emirate, borderColor),
                      _buildTitledDropdownField(
                          context, s.make, ['Audi', 'BMW'], ad.make, borderColor),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      _buildTitledDropdownField(
                          context, s.model, ['S5', 'A8'], ad.model, borderColor),
                      _buildTitledDropdownField(
                          context, s.trim, ['Tsfi', 'TDI'], ad.trim, borderColor),
                      _buildTitledTextField(s.price, ad.price, borderColor, currentLocale, 
                          controller: _priceController, isNumber: true),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      _buildTitledDropdownField(
                          context, s.year, ['2022', '2021'], '2022', borderColor),
                      _buildTitledTextField(s.dayRent, '600', borderColor, currentLocale, 
                          controller: _dayRentController, isNumber: true),
                      _buildTitledTextField(s.monthRent, '12000', borderColor, currentLocale, 
                          controller: _monthRentController, isNumber: true),
                    ]),
                    const SizedBox(height: 7),
                    
                    _buildTitleBox(context, s.title, 'Very Comfortable Car', borderColor, currentLocale,
                        controller: _descriptionController),
                    const SizedBox(height: 7),
                    
                    _buildFormRow([
                      _buildTitledDropdownField(
                          context, s.carType, ['SUV', 'Sedan'], 'SUV', borderColor),
                      _buildTitledDropdownField(
                          context, s.transType, ['Auto', 'Manual'], 'Auto', borderColor),
                      _buildTitledDropdownField(
                          context, s.fuelType, ['Petrol', 'Diesel'], 'Petrol', borderColor),
                    ]),
                    const SizedBox(height: 7),

                    _buildFormRow([
                      _buildTitledDropdownField(
                          context, s.color, ['White', 'Black'], 'White', borderColor),
                      _buildTitledDropdownField(context, s.interiorColor,
                          ['Red', 'Black'], 'Red', borderColor),
                      _buildTitledDropdownField(
                          context, s.seatsNo, ['4', '5'], '4', borderColor),
                    ]),
                    const SizedBox(height: 7),
                  ],
              
                  // Contact info section
                  // _buildFormRow([
                  //   TitledTextFieldWithAction(
                  //     title: s.phoneNumber, 
                  //     initialValue: widget.adId != null ? '' : '0097708236561', 
                  //     borderColor: borderColor, 
                  //     controller: _phoneController,
                  //     onAddPressed: () { print("Add phone clicked"); }, 
                  //     isNumeric: true
                  //   ),
                  //   TitledTextFieldWithAction(
                  //     title: s.whatsApp, 
                  //     initialValue: widget.adId != null ? '' : '0097708236561', 
                  //     borderColor: borderColor, 
                  //     controller: _whatsappController,
                  //     onAddPressed: () { print("Add whatsapp clicked"); }, 
                  //     isNumeric: true
                  //   ),
                  // ]),
                  
                  // const SizedBox(height: 7),

                  // TitledTextFieldWithAction(
                  //   title: s.advertiserName, 
                  //   initialValue: widget.adId != null ? '' : 'Alwan Rental', 
                  //   borderColor: borderColor, 
                  //   controller: _advertiserNameController,
                  //   onAddPressed: () { print("Add advertiser clicked"); }
                  // ),
                  // const SizedBox(height: 7),
                  
                  TitledDescriptionBox(
                    title: s.describeYourCar, 
                    initialValue: widget.adId != null ? '' : '20% Down Payment With Insurance Registration And Delivery To Client Without Fees', 
                    borderColor: borderColor,
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 10),
                  
                  // Image sections
                  _buildMainImageSection(s, borderColor),
                  const SizedBox(height: 7),
                  _buildThumbnailImagesSection(s, borderColor),
                  const SizedBox(height: 7),
              
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
                      child: Text(
                        ad.location.toString(),
                        style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 8.h),

              _buildMapSection(context),
              const SizedBox(height: 12),

                  // زر الحفظ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _saveAd,
                      child: provider.isSubmitting 
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
  
  void _saveAd() async {
    final provider = Provider.of<CarRentAdProvider>(context, listen: false);
    
    if (widget.adId != null) {
      // Update existing ad
      final adData = <String, dynamic>{
        'price': _priceController.text,
        'day_rent': _dayRentController.text,
        'month_rent': _monthRentController.text,
        'description': _descriptionController.text,
        // استخدام القيم المختارة من مزوّد معلومات الاتصال إن وُجِدت
        'phone_number': (selectedPhoneNumber ?? _phoneController.text),
        'whatsapp': (selectedWhatsAppNumber ?? _whatsappController.text),
        'advertiser_name': (selectedAdvertiserName ?? _advertiserNameController.text),
      };
      
      // Add image data to the adData map - these will be handled by the repository
      if (_mainImage != null) {
        adData['mainImage'] = _mainImage;
      }
      // Merge kept existing thumbnails (downloaded) with newly added ones, limit to 9
      final keptExistingUrls = _existingThumbnailUrls.where((url) => !_removedThumbnailUrls.contains(url)).toList();
      final List<File> existingFiles = [];
      for (final url in keptExistingUrls) {
        try {
          final fullUrl = ImageUrlHelper.getFullImageUrl(url);
          final file = await _downloadImageToTempFile(fullUrl);
          if (file != null) existingFiles.add(file);
        } catch (_) {
          // Ignore download failures for individual thumbnails
        }
      }

      List<File> mergedThumbnails = []
        ..addAll(existingFiles)
        ..addAll(_thumbnailImages);

      if (mergedThumbnails.length > 9) {
        mergedThumbnails = mergedThumbnails.take(9).toList();
      }

      if (mergedThumbnails.isNotEmpty) {
        adData['thumbnailImages'] = mergedThumbnails;
      }
      
      await provider.updateCarRentAd(
        widget.adId!,
        adData,
      );
      
      if (provider.submissionError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad updated successfully!')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.submissionError}')),
        );
      }
    } else {
      // Create new ad - existing logic would go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create new ad functionality not implemented yet')),
      );
    }
  }

  // --- دوال المساعدة المحدثة ---

  Widget _buildFormRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }

  Widget _buildTitledTextField(String title, String initialValue, Color borderColor, String currentLocale, {bool isNumber = false, TextEditingController? controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
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
      )
    ]);
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
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          maxLines: null,
          readOnly: readOnly,
          style: TextStyle(fontWeight: FontWeight.w500, color: readOnly ? Colors.grey[600] : KTextColor, fontSize: 14.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? borderColor : KPrimaryColor, width: 2)),
            fillColor: readOnly ? Colors.grey[100] : null,
            filled: readOnly,
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMainImageSection(S s, Color borderColor) {
    final provider = context.watch<CarRentAdProvider>();
    final ad = provider.currentAd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined, color: KTextColor),
            label: Text(s.addMainImage, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)),
            onPressed: _pickMainImage,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        ),
        if (_mainImage != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_mainImage!, height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
        ] else if (ad?.mainImage != null && ad!.mainImage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Builder(builder: (context) {
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
                        'assets/images/careRent.jpg',
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  );
                }
              }
              return Image.asset('assets/images/careRent.jpg', height: 140, width: double.infinity, fit: BoxFit.cover);
            }),
          ),
        ],
      ],
    );
  }
  
  Widget _buildThumbnailImagesSection(S s, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: KTextColor),
            label: Text(s.add9Images, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)),
            onPressed: _pickThumbnailImages,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        ),
        if (_existingThumbnailUrls.isNotEmpty || _thumbnailImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _existingThumbnailUrls.length + _thumbnailImages.length,
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
                                  'assets/images/careRent.jpg',
                                  width: 120,
                                  height: 100,
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          }
                          return Image.asset(
                            'assets/images/careRent.jpg',
                            width: 120,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        })
                      else
                        Image.file(
                          _thumbnailImages[index - _existingThumbnailUrls.length],
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
      ],
    );
  }
  
  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _mainImage = File(image.path);
      });
    }
  }
  
  Future<void> _pickThumbnailImages() async {
    // Calculate current total images
    final currentTotal = _existingThumbnailUrls.length + _thumbnailImages.length;
    
    // Check if we've reached the maximum limit
    if (currentTotal >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن إضافة المزيد من الصور. الحد الأقصى 9 صور'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Calculate how many more images can be added
    final remainingSlots = 9 - currentTotal;
    
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      // Check if selected images exceed remaining slots
      if (images.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يمكنك إضافة $remainingSlots صور فقط. الحد الأقصى 9 صور'),
            backgroundColor: Colors.orange,
          ),
        );
        // Take only the allowed number of images
        final allowedImages = images.take(remainingSlots).toList();
        setState(() {
          _thumbnailImages.addAll(allowedImages.map((image) => File(image.path)));
        });
      } else {
        setState(() {
          _thumbnailImages.addAll(images.map((image) => File(image.path)));
        });
      }
    }
  }
  
  void _removeThumbnailImage(int index) {
    setState(() {
      _thumbnailImages.removeAt(index);
    });
  }
  
  void _removeExistingThumbnail(int index) {
    setState(() {
      _removedThumbnailUrls.add(_existingThumbnailUrls[index]);
      _existingThumbnailUrls.removeAt(index);
    });
  }

  // تحميل صورة موجودة من السيرفر إلى ملف مؤقت لإعادة رفعها ضمن الصور المدمجة
  Future<File?> _downloadImageToTempFile(String imageUrl) async {
    try {
      final dio = Dio();
      final response = await dio.get(imageUrl, options: Options(responseType: ResponseType.bytes));
      final filename = 'car_rent_thumb_${DateTime.now().millisecondsSinceEpoch}_${imageUrl.hashCode}.jpg';
      final file = File('${Directory.systemTemp.path}/$filename');
      await file.writeAsBytes(response.data);
      return file;
    } catch (_) {
      return null;
    }
  }

  Widget _buildMapSection(BuildContext context) {
    final provider = context.watch<CarRentAdProvider>();
    final ad = provider.currentAd;
    
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
                  // Default location while loading
                  adLocation = const LatLng(25.2048, 55.2708); // Dubai default
                }
                
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: adLocation,
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapsProvider.onMapCreated(controller);
                    // Move camera to the correct location after map is created
                    if (snapshot.hasData) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        mapsProvider.moveCameraToLocation(
                          adLocation.latitude, 
                          adLocation.longitude, 
                          zoom: 14.0
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
                        title: ad?.location?.isNotEmpty == true 
                            ? 'الموقع المحدد' 
                            : ad?.emirate ?? 'الموقع',
                        snippet: ad?.location?.isNotEmpty == true 
                            ? ad!.location 
                            :  '',
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
    // First, try to use the saved location field for geocoding
    if (ad?.location != null && ad!.location!.trim().isNotEmpty) {
      try {
        final locations = await locationFromAddress(ad.location!);
        if (locations.isNotEmpty) {
          final first = locations.first;
          return LatLng(first.latitude, first.longitude);
        }
      } catch (e) {
        debugPrint('Geocoding failed for location "${ad.location}": $e');
      }
    }
    
    // Fallback to emirate-based coordinates if location geocoding fails
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
    
    // Final fallback to Dubai coordinates
    return const LatLng(25.2048, 55.2708);
  }
}

// TitledSelectOrAddField widget definition
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
  late TextEditingController _controller;
  
  @override
  void initState() { 
    super.initState(); 
    _focusNode = FocusNode(); 
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }
  @override
  void dispose() { 
    _focusNode.dispose(); 
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose(); 
  }
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
  final TextEditingController? controller;
  const TitledDescriptionBox({
    Key? key, required this.title, required this.initialValue, required this.borderColor, this.maxLength = 5000, this.controller
  }) : super(key: key);
  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}
class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(() { setState(() {}); });
  }
  @override
  void dispose() { 
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose(); 
  }
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