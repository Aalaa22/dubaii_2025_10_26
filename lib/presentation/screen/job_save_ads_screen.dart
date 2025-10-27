import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
const Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class JobsSaveAdScreen extends StatelessWidget {
  // استقبال دالة تغيير اللغة
  final Function(Locale) onLanguageChange;

  const JobsSaveAdScreen({Key? key, required this.onLanguageChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على نسخة من كلاس الترجمة
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);
    
    // قيم وهمية للحقول
    const emirateValue = 'Dubai';
    const districtValue = 'Satwa';
    const categoryTypeValue = 'Job Offer';
    const sectionTypeValue = 'Cleaning Services';

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
                    context, s.emirate, ['Dubai', 'Abu Dhabi'], emirateValue, borderColor),
                _buildTitledDropdownField(
                    context, s.district, ['Satwa', 'Al Barsha'], districtValue, borderColor),
              ]),
              const SizedBox(height: 7),

              _buildFormRow([
                _buildTitledDropdownField(
                    context, s.categoryType, ['Job Offer', 'Job Seeker'], categoryTypeValue, borderColor),
                _buildTitledDropdownField(
                    context, s.sectionType, ['Cleaning Services', 'IT'], sectionTypeValue, borderColor),
              ]),
              const SizedBox(height: 7),
              
              _buildFormRow([
                 _buildTitledTextField(s.jobName, 'Cleaner', borderColor, currentLocale),
                 _buildTitledTextField(s.salary, 'AED 2000', borderColor, currentLocale, isNumber: true),
              ]),
              const SizedBox(height: 7),
              
              _buildTitleBox(context, s.title, 'Hiring A Cleaner With Experience', borderColor, currentLocale),
              const SizedBox(height: 7),

              TitledTextFieldWithAction(title: s.advertiserName, initialValue: 'Al Modiyen Company', borderColor: borderColor, onAddPressed: (){ print("Add advertiser clicked"); }),
              const SizedBox(height: 7),

              _buildFormRow([
                 TitledSelectOrAddField(
                   title: s.phoneNumber,
                   value: '0097708236561',
                   items: const ['0097708236561'],
                   onChanged: (_) {},
                   isNumeric: true,
                   onAddNew: (value) { print("Add phone clicked: $value"); },
                 ),
                 TitledSelectOrAddField(
                   title: s.whatsApp,
                   value: '0097708236561',
                   items: const ['0097708236561'],
                   onChanged: (_) {},
                   isNumeric: true,
                   onAddNew: (value) { print("Add whatsapp clicked: $value"); },
                 ),
              ]),
              const SizedBox(height: 7),

              TitledDescriptionBox(title: s.description, initialValue: 'We Hiring Cleaner With Experience Job With One Duty Shift One Day Off', borderColor: borderColor, maxLength: 15000),
              const SizedBox(height: 10),
              
              _buildImageButton(s.addMainImage, Icons.add_a_photo_outlined, borderColor),
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
                      child: Text(
                        'Dubai Satwa',
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
                  onPressed: () { /* Action for Save */ },
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
  }

  // --- دوال المساعدة المحدثة ---

  Widget _buildFormRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }

  Widget _buildTitledTextField(String title, String initialValue, Color borderColor, String currentLocale, {bool isNumber = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
      const SizedBox(height: 4),
      TextFormField(
          initialValue: initialValue,
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

  // ---------------------------------------------
  // Unified select/add field with searchable bottom sheet (moved to top-level)
  // ---------------------------------------------

  Widget _buildImageButton(String title, IconData icon, Color borderColor) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: Icon(icon, color: KTextColor), label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)), onPressed: () {}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
  }

  Widget _buildMapSection(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
        height: 220.h, width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.asset('assets/images/map.png', fit: BoxFit.cover))),
            Positioned(top: 80.h, left: 0, right: 0, child: Icon(Icons.location_pin, color: Colors.red, size: 40.sp)),
            Positioned(
              bottom: 10, left: 10,
              child: ElevatedButton.icon(
                icon: Icon(Icons.location_on_outlined, color: Colors.white, size: 24.sp),
                label: Text(s.locateMe, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16.sp)),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01547E),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ));
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