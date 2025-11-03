import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/presentation/providers/electronics_info_provider.dart';
import 'package:advertising_app/presentation/providers/job_ad_provider.dart';
import 'package:advertising_app/presentation/providers/job_info_provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:geocoding/geocoding.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

class JobsAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;

  const JobsAdScreen({Key? key, required this.onLanguageChange})
      : super(key: key);

  @override
  State<JobsAdScreen> createState() => _JobsAdScreenState();
}

class _JobsAdScreenState extends State<JobsAdScreen> {
  // --- Controllers لحقول الإدخال النصية ---
  final TextEditingController _jobNameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactDetailsController =
      TextEditingController();
  // --- متغيرات الحالة لحفظ الاختيارات ---
  String? selectedEmirate;
  String? selectedDistrict;
  String? selectedCategoryType;
  String? selectedSectionType;
  String? selectedAdvertiserName;
  // حذف الحقول غير المطلوبة من الواجهة (Phone/WhatsApp)
  // String? selectedPhoneNumber;
  // String? selectedWhatsAppNumber;
  // --- الموقع ---
  String selectedLocation = '';
  LatLng? selectedLatLng;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // جلب القيم العامة
      final jobProvider = context.read<JobAdProvider>();
      await jobProvider.fetchAllJobScreenData();
      await context.read<JobInfoProvider>().fetchJobAdValues();
      // جلب بيانات جهة الإعلان (اسم المعلن) باستخدام التوكن المخزن
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      await context
          .read<ElectronicsInfoProvider>()
          .fetchAllData(token: token, includeContactInfo: true);
      // التحقق من بيانات البروفايل وضبط الموقع الافتراضي من contact info
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

    if (user.advertiserLocation != null &&
        user.advertiserLocation!.trim().isNotEmpty) {
      setState(() {
        selectedLocation = user.advertiserLocation!;
      });
    }

    List<String> missingFields = [];
    if (user.phone.trim().isEmpty) {
      missingFields.add('phone number');
    }
    if ((user.advertiserLocation == null ||
            user.advertiserLocation!.trim().isEmpty) &&
        (user.latitude == null || user.longitude == null)) {
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
        final s = S.of(context);
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

        final List<String> localizedMissingFields = missingFields.map((field) {
          switch (field.trim().toLowerCase()) {
            case 'phone number':
              return s.phone;
            case 'your location':
              return s.advertiserLocation;
            default:
              return field;
          }
        }).toList();

        final String description = isArabic
            ? 'يجب عليك إكمال الحقول التالية في ملفك الشخصي قبل إضافة الإعلان:'
            : 'You must complete the following fields in your profile before adding the advertisement:';
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              s.warning,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: KTextColor, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: KTextColor),
                ),
                const SizedBox(height: 8),
                ...localizedMissingFields.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
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
                      ]),
                    )),
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
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
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
                  child: Text(
                    s.cancel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      },
    );
  }

  @override
  void dispose() {
    _jobNameController.dispose();
    _salaryController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _contactDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

    final jobProvider = context.watch<JobAdProvider>();
    final jobInfoProvider = context.watch<JobInfoProvider>();
    final electronicsProvider = context.watch<ElectronicsInfoProvider>();

    final isLoadingData = jobProvider.isCategoryTypesLoading ||
        jobProvider.isEmiratesLoading ||
        jobInfoProvider.isLoading;
    final hasError = (jobProvider.categoryTypesError != null) ||
        (jobProvider.emiratesError != null) ||
        (jobInfoProvider.error != null);

    if (isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (hasError) {
      return Scaffold(body: Center(child: Text('Error loading data')));
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
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    SizedBox(width: 5.w),
                    Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                    Transform.translate(
                      offset: Offset(-3.w, 0),
                      child: Text(s.back,
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: KTextColor)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 7.h),

              Center(
                child: Text(s.jobsAds,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 24.sp,
                        color: KTextColor)),
              ),
              SizedBox(height: 10.h),
              // --- Emirate & District from provider ---
              _buildFormRow([
                _buildSingleSelectField(
                  context,
                  s.emirate,
                  selectedEmirate,
                  jobProvider.emirateNames,
                  (selection) => setState(() {
                    selectedEmirate = selection;
                    selectedDistrict = null;
                  }),
                ),
                _buildSingleSelectField(
                  context,
                  s.district,
                  selectedDistrict,
                  (selectedEmirate == null)
                      ? []
                      : jobProvider.emirates
                          .firstWhere(
                            (e) => e.name == selectedEmirate,
                            orElse: () => jobProvider.emirates.isNotEmpty
                                ? jobProvider.emirates.first
                                : EmirateModel(
                                    name: '', displayName: '', districts: []),
                          )
                          .districts,
                  (selection) => setState(() => selectedDistrict = selection),
                ),
              ]),
              const SizedBox(height: 7),

              _buildFormRow([
                _buildSingleSelectField(
                  context,
                  s.categoryType,
                  selectedCategoryType,
                  jobProvider.categoryTypes,
                  (selection) =>
                      setState(() => selectedCategoryType = selection),
                ),
                _buildSingleSelectField(
                  context,
                  s.sectionType,
                  selectedSectionType,
                  jobInfoProvider.sectionTypes,
                  (selection) =>
                      setState(() => selectedSectionType = selection),
                ),
              ]),
              const SizedBox(height: 7),

              _buildFormRow([
                _buildTitledTextFormField(s.jobName, 'Enter job name',
                    _jobNameController, borderColor, currentLocale),
                _buildTitledTextFormField(s.salary, 'Enter salary',
                    _salaryController, borderColor, currentLocale,
                    isNumber: true),
              ]),
              const SizedBox(height: 7),

              // Title field with multi-line support and car_sales validation
              _buildTitledTextFormField(
                  s.title,
                  'Enter your title',
                  _titleController,
                  borderColor,
                  currentLocale,
                  minLines: 3,
                  maxLines: 4),
              const SizedBox(height: 7),

              TitledSelectOrAddField(
                title: s.advertiserName,
                value: selectedAdvertiserName,
                items: electronicsProvider.advertiserNames,
                onChanged: (newValue) =>
                    setState(() => selectedAdvertiserName = newValue),
                onAddNew: (newValue) async {
                  final token = await const FlutterSecureStorage()
                      .read(key: 'auth_token');
                  if (token != null) {
                    final success = await electronicsProvider.addContactItem(
                        'advertiser_names', newValue,
                        token: token);
                    if (success && mounted)
                      setState(() => selectedAdvertiserName = newValue);
                  }
                },
              ),
              const SizedBox(height: 7),

              // Contact Details field replacing phone/whatsapp
              _buildTitledTextFormField(
                  'Contact Details',
                  s.enterContactInfo,
                  _contactDetailsController,
                  borderColor,
                  currentLocale),
              const SizedBox(height: 7),

              // Description with hint
              TitledDescriptionBox(
                title: s.description,
                initialValue: '',
                borderColor: borderColor,
                maxLength: 15000,
                controller: _descriptionController,
                hintText: s.enterDescription,
              ),
              const SizedBox(height: 10),

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
                                : S.of(context).advertiserLocation,
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
                  onPressed: () { _validateAndProceedToNext(); },
                  child: Text(s.next,
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
      ),
    );
  }

  // --- دوال المساعدة الموحدة ---
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

  Widget _buildTitledTextFormField(String title, String hintText,
      TextEditingController controller, Color borderColor, String currentLocale,
      {bool isNumber = false, int minLines = 1, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      Builder(builder: (context) {
        final field = TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLines > 1 ? 100 : null,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
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
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.white,
              filled: true),
        );
        return maxLines > 1 ? field : SizedBox(height: 48, child: field);
      })
    ]);
  }

  Widget _buildSingleSelectField(BuildContext context, String title,
      String? selectedValue, List<String> allItems, Function(String?) onConfirm,
      {double? titleFontSize}) {
    final s = S.of(context);
    String displayText = selectedValue ?? s.chooseAnOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KTextColor,
                fontSize: titleFontSize ?? 14.sp)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await _showSingleSelectPicker(context,
                title: title, items: allItems);
            onConfirm(result);
          },
          child: Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color.fromRGBO(8, 194, 201, 1)),
                borderRadius: BorderRadius.circular(8)),
            child: Text(
              displayText,
              style: TextStyle(
                  fontWeight: selectedValue == null
                      ? FontWeight.normal
                      : FontWeight.w500,
                  color:
                      selectedValue == null ? Colors.grey.shade500 : KTextColor,
                  fontSize: 12.sp),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _showSingleSelectPicker(BuildContext context,
      {required String title, required List<String> items}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) =>
          _SingleSelectBottomSheet(title: title, items: items),
    );
  }

  Widget _buildTitleBox(BuildContext context, String title, String initialValue,
      Color borderColor, String currentLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KTextColor,
                fontSize: 14.sp)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          maxLines: null,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton(String title, IconData icon, Color borderColor) {
    return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
            icon: Icon(icon, color: KTextColor),
            label: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: KTextColor,
                    fontSize: 16.sp)),
            onPressed: () {},
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)))));
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'جاري تحديد الموقع...' : 'Locating...'),
        backgroundColor: KPrimaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

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

        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isArabic ? 'تم تحديد الموقع بنجاح' : 'Location found'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isArabic ? 'فشل في تحديد الموقع: $e' : 'Failed to get location: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _navigateToLocationPicker() async {
    try {
      double? initialLat = selectedLatLng?.latitude;
      double? initialLng = selectedLatLng?.longitude;
      String? initialAddress =
          selectedLocation.isNotEmpty ? selectedLocation : null;

      String route = '/location_picker';
      if (initialLat != null && initialLng != null) {
        route += '?lat=$initialLat&lng=$initialLng';
        if (initialAddress != null && initialAddress.isNotEmpty) {
          route += '&address=${Uri.encodeComponent(initialAddress)}';
        }
      }

      final result = await context.push(route);
      if (result != null && result is Map<String, dynamic>) {
        final LatLng? location = result['location'] as LatLng?;
        final String? address = result['address'] as String?;
        if (location != null) {
          setState(() {
            selectedLatLng = location;
            if (address != null && address.isNotEmpty) {
              selectedLocation = address;
            }
          });
        }
      }
    } catch (e) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isArabic ? 'حدث خطأ أثناء اختيار الموقع: $e' : 'Error picking location: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _validateAndProceedToNext() {
    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final List<String> missing = [];

    if (_jobNameController.text.trim().isEmpty) missing.add(s.jobName);
    if (_titleController.text.trim().isEmpty) missing.add(s.title);
    if (_descriptionController.text.trim().isEmpty) missing.add(s.description);

    if (selectedEmirate == null || (selectedEmirate?.trim().isEmpty ?? true)) {
      missing.add(s.emirate);
    }
    if (selectedDistrict == null || (selectedDistrict?.trim().isEmpty ?? true)) {
      missing.add(s.district);
    }
    if (selectedCategoryType == null || (selectedCategoryType?.trim().isEmpty ?? true)) {
      missing.add(s.categoryType);
    }
    if (selectedSectionType == null || (selectedSectionType?.trim().isEmpty ?? true)) {
      missing.add(s.sectionType);
    }

    if (_salaryController.text.trim().isEmpty) {
      missing.add(s.salary);
    } else {
      final salaryText = _salaryController.text.trim();
      final salaryNum = double.tryParse(salaryText.replaceAll(',', ''));
      if (salaryNum == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'الراتب يجب أن يكون رقمًا صالحًا'
                : 'Salary must be a valid number'),
            backgroundColor: KPrimaryColor,
          ),
        );
        return;
      }
    }

    if (selectedAdvertiserName == null || (selectedAdvertiserName?.trim().isEmpty ?? true)) {
      missing.add(s.advertiserName);
    }
    if (_contactDetailsController.text.trim().isEmpty) {
      missing.add(s.enterContactInfo);
    }
    if (selectedLocation.trim().isEmpty) {
      missing.add(s.location);
    }

    if (missing.isNotEmpty) {
      final joined = missing.join(isArabic ? '، ' : ', ');
      final message = isArabic
          ? 'يرجى تعبئة/اختيار: ' + joined
          : 'Please complete/select: ' + joined;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: KPrimaryColor,
        ),
      );
      return;
    }

    final adData = {
      'adType': 'job',
      'jobName': _jobNameController.text.trim(),
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'emirate': selectedEmirate,
      'district': selectedDistrict,
      'categoryType': selectedCategoryType,
      'sectionType': selectedSectionType,
      'salary': _salaryController.text.trim(),
      'advertiserName': selectedAdvertiserName,
      'contactDetails': _contactDetailsController.text.trim(),
      'location': selectedLocation,
      'address': selectedLocation,
      'latitude': selectedLatLng?.latitude,
      'longitude': selectedLatLng?.longitude,
    };

    context.push('/placeAnAd', extra: adData);
  }

  Widget _buildMapSection(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            Consumer<GoogleMapsProvider>(
              builder: (context, mapsProvider, child) => GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: selectedLatLng ?? const LatLng(25.2048, 55.2708),
                  zoom: 12.0,
                ),
                onMapCreated: mapsProvider.onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                onTap: (pos) async {
                  final address = await mapsProvider.getAddressFromCoordinates(
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
                          markerId: const MarkerId('selected_location'),
                          position: selectedLatLng!,
                        )
                      },
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoadingLocation ? null : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLoadingLocation ? Colors.grey : KPrimaryColor,
                        minimumSize: const Size(double.infinity, 43),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          :  Text(
                              S.of(context).locateMe,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToLocationPicker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01547E),
                        minimumSize: const Size(double.infinity, 43),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:Text(
                        S.of(context).pickLocation,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          await mapsProvider.moveCameraToLocation(
            latLng.latitude,
            latLng.longitude,
            zoom: 16.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error geocoding selectedLocation: $e');
    }
  }
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++        الودجت المساعدة المنقولة من الشاشات الأخرى    ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class TitledSelectOrAddField extends StatelessWidget {
  final String title;
  final String? value;
  final List<String> items;
  final Function(String) onChanged;
  final bool isNumeric;
  final Future<void> Function(String)? onAddNew;
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
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KTextColor,
                fontSize: 14.sp)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(value ?? s.chooseAnOption,
                        style: TextStyle(
                            fontWeight: value == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                            color: value == null
                                ? Colors.grey.shade500
                                : KTextColor,
                            fontSize: 12.sp))),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _SearchableSelectOrAddBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final bool isNumeric;
  final Future<void> Function(String)? onAddNew;
  const _SearchableSelectOrAddBottomSheet(
      {Key? key,
      required this.title,
      required this.items,
      this.isNumeric = false,
      this.onAddNew})
      : super(key: key);
  @override
  _SearchableSelectOrAddBottomSheetState createState() =>
      _SearchableSelectOrAddBottomSheetState();
}

class _SearchableSelectOrAddBottomSheetState
    extends State<_SearchableSelectOrAddBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addController = TextEditingController();
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
    _addController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: KTextColor)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              style: TextStyle(color: KTextColor),
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: Icon(Icons.search, color: KTextColor),
                hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: KPrimaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(s.noResultsFound,
                          style: TextStyle(color: KTextColor)))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                            title:
                                Text(item, style: TextStyle(color: KTextColor)),
                            onTap: () => Navigator.pop(context, item));
                      },
                    ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
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
                      hintText: s.addNew,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: KPrimaryColor, width: 2)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final text = _addController.text.trim();
                    if (text.isEmpty) return;
                    if (widget.onAddNew != null) {
                      await widget.onAddNew!(text);
                    }
                    Navigator.pop(context, text);
                  },
                  child: Text(s.add,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
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
  const _SingleSelectBottomSheet(
      {Key? key, required this.title, required this.items})
      : super(key: key);
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
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Text(widget.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: KTextColor))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _searchController,
                style: TextStyle(color: KTextColor),
                decoration: InputDecoration(
                  hintText: s.search,
                  prefixIcon: Icon(Icons.search, color: KTextColor),
                  hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Text(s.noResultsFound,
                            style: TextStyle(color: KTextColor)))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                              title: Text(item,
                                  style: TextStyle(color: KTextColor)),
                              onTap: () => Navigator.pop(context, item));
                        },
                      ),
              ),
            ],
          ),
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
  final String? hintText;
  const TitledDescriptionBox(
      {Key? key,
      required this.title,
      required this.initialValue,
      required this.borderColor,
      this.maxLength = 5000,
      this.controller,
      this.hintText})
      : super(key: key);
  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}

class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  late TextEditingController _controller;
  late final bool _ownsController;

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KTextColor,
                fontSize: 14.sp)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.borderColor)),
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                maxLines: null,
                maxLength: widget.maxLength,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: KTextColor,
                    fontSize: 14.sp),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: Colors.grey)),
              ),
              // Padding(
              //   padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              //   child: Align(
              //     alignment: Alignment.bottomRight,
              //     child: Text('${_controller.text.length}/${widget.maxLength}',
              //         style: TextStyle(color: Colors.grey, fontSize: 12),
              //         textDirection: TextDirection.ltr),
              //   ),
              // )
            ],
          ),
        ),
      ],
    );
  }
}
