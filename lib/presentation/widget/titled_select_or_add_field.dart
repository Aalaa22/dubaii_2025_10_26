import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_phone_field.dart';

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
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
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
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis))
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
  final Function(String)? onAddNew;

  const _SearchableSelectOrAddBottomSheet({
    required this.title,
    required this.items,
    this.isNumeric = false,
    this.onAddNew,
  });

  @override
  _SearchableSelectOrAddBottomSheetState createState() =>
      _SearchableSelectOrAddBottomSheetState();
}

class _SearchableSelectOrAddBottomSheetState
    extends State<_SearchableSelectOrAddBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addController = TextEditingController();
  List<String> _filteredItems = [];
  String _fullPhoneNumber = '';

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
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);
    final Color kPrimaryColor = const Color.fromRGBO(1, 84, 126, 1);

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
                            BorderSide(color: kPrimaryColor, width: 2)))),
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

            // Logic for Adding New Entry
            if (widget.isNumeric) ...[
              // Use CustomPhoneField for phone numbers to match login page behavior
              CustomPhoneField(
                controller: _addController,
                onPhoneNumberChanged: (fullNumber) {
                  _fullPhoneNumber = fullNumber;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async {
                      if (_fullPhoneNumber.isNotEmpty) {
                        if (widget.items.contains(_fullPhoneNumber)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('هذا الرقم موجود بالفعل في قائمتك'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        if (widget.onAddNew != null) {
                          try {
                            await widget.onAddNew!(_fullPhoneNumber);
                            if (mounted)
                              Navigator.pop(context, _fullPhoneNumber);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          Navigator.pop(context, _fullPhoneNumber);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(s.add,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
              ),
            ] else ...[
              // Simple text field for non-numeric entries
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addController,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: KTextColor,
                          fontSize: 12),
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
                                  BorderSide(color: kPrimaryColor, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                      onPressed: () async {
                        String result = _addController.text.trim();
                        if (result.isNotEmpty) {
                          if (widget.items.contains(result)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('هذا العنصر موجود بالفعل'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (widget.onAddNew != null) {
                            try {
                              await widget.onAddNew!(result);
                              if (mounted) Navigator.pop(context, result);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e
                                        .toString()
                                        .replaceAll('Exception: ', '')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } else {
                            Navigator.pop(context, result);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          minimumSize: const Size(60, 48)),
                      child: Text(s.add,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                ],
              ),
            ],
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
  final int? minLines;

  const TitledDescriptionBox({
    Key? key,
    required this.title,
    required this.controller,
    required this.borderColor,
    this.maxLength = 15000,
    this.hintText,
    this.minLines,
  }) : super(key: key);

  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}

class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
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
                controller: widget.controller,
                maxLines: null,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: KTextColor,
                    fontSize: 14.sp),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: widget.hintText,
                    counterText: ""),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(right: 8.0, bottom: 8.0, left: 8.0),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                        '${widget.controller.text.length}/${widget.maxLength}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        textDirection: Directionality.of(context))),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class TitledTextFieldWithAction extends StatefulWidget {
  final String title;
  final String initialValue;
  final Color borderColor;
  final bool isNumeric;
  final VoidCallback onAddPressed;
  final bool readOnly;
  const TitledTextFieldWithAction(
      {Key? key,
      required this.title,
      required this.initialValue,
      required this.borderColor,
      required this.onAddPressed,
      this.isNumeric = false,
      this.readOnly = false})
      : super(key: key);
  @override
  _TitledTextFieldWithActionState createState() =>
      _TitledTextFieldWithActionState();
}

class _TitledTextFieldWithActionState extends State<TitledTextFieldWithAction> {
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final addButtonWidth = (s.add.length * 8.0) + 24.0;
    final Color kPrimaryColor = const Color.fromRGBO(1, 84, 126, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KTextColor,
                fontSize: 14.sp)),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              focusNode: _focusNode,
              initialValue: widget.initialValue,
              readOnly: widget.readOnly,
              keyboardType:
                  widget.isNumeric ? TextInputType.number : TextInputType.text,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: KTextColor,
                  fontSize: 12.sp),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(
                    left: 16, right: addButtonWidth, top: 12, bottom: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.borderColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.borderColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: kPrimaryColor, width: 2)),
                fillColor: widget.readOnly ? Colors.grey[200] : Colors.white,
                filled: true,
              ),
            ),
            if (!widget.readOnly)
              Positioned(
                right: 1,
                top: 1,
                bottom: 1,
                child: GestureDetector(
                  onTap: () {
                    widget.onAddPressed();
                    _focusNode.requestFocus();
                  },
                  child: Container(
                    width: addButtonWidth - 10,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(7),
                            bottomRight: Radius.circular(7))),
                    child: Text(s.add,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
