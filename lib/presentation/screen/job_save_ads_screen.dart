import 'package:advertising_app/presentation/providers/job_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
const Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class JobsSaveAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  final int? adId;

  const JobsSaveAdScreen({Key? key, required this.onLanguageChange, this.adId})
      : super(key: key);

  @override
  _JobsSaveAdScreenState createState() => _JobsSaveAdScreenState();
}

class _JobsSaveAdScreenState extends State<JobsSaveAdScreen> {
  late Future<void> _fetchAdDetailsFuture;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();

  // Listeners for logging during edit
  void _logDuringEditSalary() {
    debugPrint('=== أثناء التعديل | salary: ${_salaryController.text}');
  }
  void _logDuringEditDescription() {
    debugPrint('=== أثناء التعديل | description: ${_descriptionController.text}');
  }
  void _logDuringEditContactInfo() {
    debugPrint('=== أثناء التعديل | contact_info: ${_contactInfoController.text}');
  }

  @override
  void initState() {
    super.initState();
    // Attach listeners to log values during user edits
    _salaryController.addListener(_logDuringEditSalary);
    _descriptionController.addListener(_logDuringEditDescription);
    _contactInfoController.addListener(_logDuringEditContactInfo);
    if (widget.adId != null) {
      _fetchAdDetailsFuture = Provider.of<JobDetailsProvider>(context, listen: false)
          .fetchAdDetails(widget.adId!)
          .then((_) {
        // Log provider state after fetch
        final provider = Provider.of<JobDetailsProvider>(context, listen: false);
        debugPrint('[JobsSaveAdScreen] fetchAdDetails completed. error=${provider.error} hasAd=${provider.adDetails != null}');
        final adDetails =
            Provider.of<JobDetailsProvider>(context, listen: false).adDetails;
        if (adDetails != null) {
          // Print key fields to help diagnose data mapping issues
          debugPrint('[JobsSaveAdScreen] Ad Details: id=${adDetails.id}, title=${adDetails.title}, emirate=${adDetails.emirate}, district=${adDetails.district}, category=${adDetails.category}, sectionType=${adDetails.sectionType}, price=${adDetails.price}, phone=${adDetails.phoneNumber}, whatsapp=${adDetails.whatsappNumber}, descriptionLen=${adDetails.description?.length ?? 0}');
          setState(() {
            _salaryController.text = adDetails.price?.toString() ?? '';
            _descriptionController.text = adDetails.description ?? '';
            _phoneController.text = adDetails.phoneNumber ?? '';
            _whatsappController.text = adDetails.whatsappNumber ?? '';
            _contactInfoController.text = adDetails.contactInfo ?? '';
          });
          debugPrint('[JobsSaveAdScreen] Controllers populated: salary=${_salaryController.text}, phone=${_phoneController.text}, whatsapp=${_whatsappController.text}, descLen=${_descriptionController.text.length}');
          // Print values BEFORE modification
          debugPrint('=== قبل التعديل | salary: ${_salaryController.text}, description: ${_descriptionController.text}, contact_info: ${_contactInfoController.text}');
        } else {
          debugPrint('[JobsSaveAdScreen] No adDetails available after fetch.');
        }
      }).catchError((error, stack) {
        debugPrint('[JobsSaveAdScreen] Error fetching ad details: $error');
        debugPrintStack(stackTrace: stack);
      });
    } else {
      _fetchAdDetailsFuture = Future.value();
    }
  }

  @override
  void dispose() {
    // Detach listeners
    _salaryController.removeListener(_logDuringEditSalary);
    _descriptionController.removeListener(_logDuringEditDescription);
    _contactInfoController.removeListener(_logDuringEditContactInfo);
    _salaryController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<void>(
        future: _fetchAdDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && widget.adId != null) {
            debugPrint('[JobsSaveAdScreen] FutureBuilder waiting for adId=${widget.adId}');
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            debugPrint('[JobsSaveAdScreen] FutureBuilder error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final jobProvider = Provider.of<JobDetailsProvider>(context, listen: false);
          final adDetails = jobProvider.adDetails;
          if (adDetails == null) {
            debugPrint('[JobsSaveAdScreen] AdDetails is null. Provider error: ${jobProvider.error}');
          } else {
            debugPrint('[JobsSaveAdScreen] Rendering with ad title: ${adDetails.title}');
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
                        s.jobsAds,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 24.sp,
                          color: KTextColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _buildFormRow([
                      _buildTitledDropdownField(
                          context, s.emirate, ['Dubai', 'Abu Dhabi'], adDetails?.emirate, borderColor, readOnly: true),
                      _buildTitledDropdownField(
                          context, s.district, ['Satwa', 'Al Barsha'], adDetails?.district, borderColor, readOnly: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildTitledDropdownField(
                          context, s.categoryType, ['Job Offer', 'Job Seeker'], adDetails?.category, borderColor, readOnly: true),
                      _buildTitledDropdownField(
                          context, s.sectionType, ['Cleaning Services', 'IT'], adDetails?.sectionType, borderColor, readOnly: true),
                    ]),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildTitledTextField(s.jobName, adDetails?.job_name ?? '', borderColor, currentLocale, readOnly: true),
                      _buildTitledTextField(s.salary, '', borderColor, currentLocale, isNumber: true, controller: _salaryController),
                    ]),
                    const SizedBox(height: 7),
                    _buildTitleBox(context, s.title, adDetails?.title ?? '', borderColor, currentLocale, readOnly: true),
                    const SizedBox(height: 7),
                    TitledTextFieldWithAction(title: s.advertiserName, initialValue: adDetails?.advertiserName ?? '', borderColor: borderColor, onAddPressed: () {}, readOnly: true),
                    const SizedBox(height: 7),
                    _buildFormRow([
                      _buildTitledTextField(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'معلومات التواصل' : 'Contact Info',
                        '',
                        borderColor,
                        currentLocale,
                        controller: _contactInfoController,
                      ),
                    ]),
                    const SizedBox(height: 7),
                    TitledDescriptionBox(title: s.description, initialValue: '', borderColor: borderColor, maxLength: 15000, controller: _descriptionController),
                    const SizedBox(height: 7),
                    // _buildImageButton(s.addMainImage, Icons.add_a_photo_outlined, borderColor),
                    // const SizedBox(height: 7),
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
                              '${adDetails?.address ?? ''}',
                              style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500),
                            ),
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final adDetails = Provider.of<JobDetailsProvider>(context, listen: false).adDetails;
                            if (adDetails != null) {
                              // Create a map with the updated data
                              Map<String, dynamic> updatedData = {
                                'salary': _salaryController.text,
                                'description': _descriptionController.text,
                                'contact_info': _contactInfoController.text,
                              };

                              // Print values BEFORE saving (update)
                              debugPrint('=== قبل الحفظ/التحديث ===');
                              debugPrint('salary: ${_salaryController.text}');
                              debugPrint('description: ${_descriptionController.text}');
                              debugPrint('contact_info: ${_contactInfoController.text}');

                              // Call the provider to update the ad
                              Provider.of<JobDetailsProvider>(context, listen: false)
                                  .updateAdDetails(adDetails.id, updatedData)
                                  .then((_) {
                                // Print values AFTER saving (update completed)
                                debugPrint('=== بعد التعديل/الحفظ ===');
                                debugPrint('salary: ${_salaryController.text}');
                                debugPrint('description: ${_descriptionController.text}');
                                debugPrint('contact_info: ${_contactInfoController.text}');
                                // Optionally, show a success message or navigate back
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      S.of(context).saveSuccess,
                                      textDirection: Directionality.of(context),
                                    ),
                                  ),
                                );
                                context.pop();
                              }).catchError((error) {
                                // Handle any errors
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      S.of(context).saveFailed(error.toString()),
                                      textDirection: Directionality.of(context),
                                    ),
                                  ),
                                );
                              });
                            }
                          }
                        },
                        child: Text(s.save, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
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
        },
      ),
    );
  }



  Widget _buildTitledTextField(String title, String initialValue, Color borderColor, String currentLocale, {bool isNumber = false, bool readOnly = false, TextEditingController? controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          readOnly: readOnly,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
      DropdownSearch<String>(
          enabled: !readOnly,
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
          onChanged: (val) {})
    ]);
  }

  // Restored form row helper to align paired fields horizontally
  Widget _buildFormRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: 8.w),
        ]
      ],
    );
  }
  
  Widget _buildTitleBox(BuildContext context, String title, String initialValue,
      Color borderColor, String currentLocale, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          readOnly: readOnly,
          maxLines: null,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.all(12),
            fillColor: readOnly ? Colors.grey[200] : Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------
  // Unified select/add field with searchable bottom sheet (moved to top-level)
  // ---------------------------------------------

  // Widget _buildImageButton(String title, IconData icon, Color borderColor) {
  //   return SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: Icon(icon, color: KTextColor), label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)), onPressed: () {}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
  // }

  Widget _buildMapSection(BuildContext context) {
    final jobProvider = context.watch<JobDetailsProvider>();
    final ad = jobProvider.adDetails;

    return Consumer<GoogleMapsProvider>(
      builder: (context, mapsProvider, child) {
        return Container(
          height: 220.h,
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

                return Stack(
                  children: [
                    Positioned.fill(
                      child: GoogleMap(
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
                              title: (ad?.address?.isNotEmpty == true)
                                  ? S.of(context).location
                                  : (ad?.emirate ?? S.of(context).location),
                              snippet: (ad?.address?.isNotEmpty == true)
                                  ? ad!.address
                                  : (ad?.district ?? ''),
                            ),
                          ),
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<LatLng> _getAdLocation(dynamic ad) async {
    // حاول أولاً استخدام العنوان النصي إن كان متوفراً
    if (ad?.address != null && ad!.address!.trim().isNotEmpty) {
      try {
        final locations = await locationFromAddress(ad.address!);
        if (locations.isNotEmpty) {
          final first = locations.first;
          return LatLng(first.latitude, first.longitude);
        }
      } catch (e) {
        debugPrint('فشل تحويل العنوان إلى إحداثيات "${ad.address}": $e');
      }
    }

    // بديل: استخدام الإمارة إن فشل التحويل أو لم يتوفر عنوان
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

    // افتراضي: دبي
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
  final bool readOnly;
  const TitledTextFieldWithAction({Key? key, required this.title, required this.initialValue, required this.borderColor, required this.onAddPressed, this.isNumeric = false, this.readOnly = false}) : super(key: key);
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
              readOnly: widget.readOnly,
              keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
              style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(left: 16, right: addButtonWidth, top: 12, bottom: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                fillColor: widget.readOnly ? Colors.grey[200] : Colors.white, filled: true,
              ),
            ),
            if (!widget.readOnly)
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

class TitledSelectOrAddField extends StatelessWidget {
  final String title;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;
  final Function(String) onAddNew;
  final bool isNumeric;
  final TextEditingController? controller;

  const TitledSelectOrAddField({
    Key? key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onAddNew,
    this.isNumeric = false,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? value : null,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             suffixIcon: IconButton(
              icon: const Icon(Icons.list_alt, color: KTextColor),
              tooltip: s.chooseAnOption,
              onPressed: () async {
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
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  if (controller != null) controller!.text = result;
                  onChanged(result);
                  onAddNew(result); // keep compatibility with existing callback
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class TitledDescriptionBox extends StatelessWidget {
  final String title;
  final String initialValue;
  final Color borderColor;
  final int maxLength;
  final TextEditingController? controller;

  const TitledDescriptionBox({
    Key? key,
    required this.title,
    required this.initialValue,
    required this.borderColor,
    required this.maxLength,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          maxLines: 5,
          maxLength: maxLength,
          style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}