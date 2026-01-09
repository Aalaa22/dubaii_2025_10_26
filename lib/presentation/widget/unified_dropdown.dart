import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/generated/l10n.dart';

// Unified color constants for consistent styling
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

/// Unified dropdown widget for consistent selection UI across the app
class UnifiedDropdown<T> extends StatelessWidget {
  final String title;
  final T? selectedValue;
  final List<T> items;
  final Function(T?) onConfirm;
  final String Function(T)? displayNamer;
  final bool isLoading;
  final bool isRequired;
  final double? titleFontSize;

  const UnifiedDropdown({
    Key? key,
    required this.title,
    required this.selectedValue,
    required this.items,
    required this.onConfirm,
    this.displayNamer,
    this.isLoading = false,
    this.isRequired = false,
    this.titleFontSize,
  }) : super(key: key);

  String _getDisplayText() {
    if (isLoading) return "Loading...";
    if (selectedValue == null) return title;
    if (displayNamer != null) return displayNamer!(selectedValue as T);
    return selectedValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRequired) ...[
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: KTextColor,
              fontSize: titleFontSize ?? 14.sp,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: GestureDetector(
            onTap: isLoading || items.isEmpty
                ? null
                : () async {
                    final result = await showModalBottomSheet<T>(
                      context: context,
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => UnifiedBottomSheet<T>(
                        title: title,
                        items: items,
                        initialSelection: selectedValue,
                        displayNamer: displayNamer,
                      ),
                    );
                    if (result != null) {
                      onConfirm(result);
                    }
                  },
            child: Container(
              height: 48,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: (isLoading || items.isEmpty)
                    ? Colors.grey.shade200
                    : Colors.white,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getDisplayText(),
                      style: TextStyle(
                        fontWeight: selectedValue == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                        color: selectedValue == null
                            ? Colors.grey.shade500
                            : KTextColor,
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KPrimaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Unified bottom sheet for consistent selection UI
class UnifiedBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? initialSelection;
  final String Function(T)? displayNamer;

  const UnifiedBottomSheet({
    Key? key,
    required this.title,
    required this.items,
    this.initialSelection,
    this.displayNamer,
  }) : super(key: key);

  @override
  State<UnifiedBottomSheet<T>> createState() => _UnifiedBottomSheetState<T>();
}

class _UnifiedBottomSheetState<T> extends State<UnifiedBottomSheet<T>> {
  T? _selectedItem;
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialSelection;
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
      _filteredItems = widget.items.where((item) {
        final displayText = widget.displayNamer != null
            ? widget.displayNamer!(item)
            : item.toString();
        return displayText.toLowerCase().contains(query);
      }).toList();
    });
  }

  String _getDisplayText(T item) {
    return widget.displayNamer != null
        ? widget.displayNamer!(item)
        : item.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return KPrimaryColor; // Selected circle color
            }
            return borderColor; // Unselected circle color
          }),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: KTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search field
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
                      borderSide: BorderSide(color: KPrimaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                
                // Items list
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
                            return RadioListTile<T>(
                              title: Text(
                                _getDisplayText(item),
                                style: const TextStyle(color: KTextColor),
                              ),
                              value: item,
                              groupValue: _selectedItem,
                              activeColor: KPrimaryColor,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (value) {
                                setState(() {
                                  _selectedItem = value;
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                
                // Apply button with unified styling
                UnifiedApplyButton(
                  onPressed: () => Navigator.pop(context, _selectedItem),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified apply button for consistent styling across the app
class UnifiedApplyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? text;
  final double? width;
  final double? height;

  const UnifiedApplyButton({
    Key? key,
    required this.onPressed,
    this.text,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: KPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(text ?? s.apply),
      ),
    );
  }
}

/// Unified search button for consistent styling across the app
class UnifiedSearchButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? text;
  final double? width;
  final double? height;

  const UnifiedSearchButton({
    Key? key,
    required this.onPressed,
    this.text,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: KPrimaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          height: height ?? 43,
          width: width ?? double.infinity,
          child: Center(
            child: Text(
              text ?? s.search,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}