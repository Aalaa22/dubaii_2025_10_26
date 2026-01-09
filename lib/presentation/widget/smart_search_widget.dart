import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

// نموذج لنتائج البحث
class SearchResult {
  final String keyword;
  final String section;
  final String sectionArabic;
  final int count;
  final String endpoint;

  SearchResult({
    required this.keyword,
    required this.section,
    required this.sectionArabic,
    required this.count,
    required this.endpoint,
  });
}

class SmartSearchWidget extends StatefulWidget {
  final String? hintText;
  final Function(SearchResult)? onResultSelected;
  final Color? borderColor;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const SmartSearchWidget({
    Key? key,
    this.hintText,
    this.onResultSelected,
    this.borderColor,
    this.height,
    this.padding,
  }) : super(key: key);

  @override
  State<SmartSearchWidget> createState() => _SmartSearchWidgetState();
}

class _SmartSearchWidgetState extends State<SmartSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  Timer? _debounceTimer;
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;

  // قائمة الأقسام مع endpoints
  final Map<String, Map<String, String>> _sections = {
    'restaurants': {
      'endpoint': '/api/restaurants/search',
      'arabic': 'المطاعم',
    },
    'real-estates': {
      'endpoint': '/api/real-estates/search',
      'arabic': 'العقارات',
    },
    'car-services': {
      'endpoint': '/api/car-services/search',
      'arabic': 'خدمات السيارات',
    },
    'car-rent': {
      'endpoint': '/api/car-rent/search',
      'arabic': 'إيجار السيارات',
    },
    'car-sales-ads': {
      'endpoint': '/api/car-sales-ads/search',
      'arabic': 'بيع السيارات',
    },
    'electronics': {
      'endpoint': '/api/electronics/search',
      'arabic': 'الإلكترونيات',
    },
    'other-services': {
      'endpoint': '/api/other-services/search',
      'arabic': 'خدمات أخرى',
    },
    'jobs': {
      'endpoint': '/api/jobs/search',
      'arabic': 'الوظائف',
    },
  };

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // تأخير إخفاء النتائج للسماح بالنقر على النتائج
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _hideResults();
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    print('Search text changed: "$query"');
    print('Controller text: "${_searchController.text}"');
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    if (query.trim().isEmpty) {
      print('Query is empty, hiding results');
      _hideResults();
      return;
    }

    print('Starting search timer for: "${query.trim()}"');
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String keyword) async {
    print('Performing search for: "$keyword"');
    if (!mounted) return;
    
    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    final apiService = ApiService();
    List<SearchResult> results = [];

    // البحث في جميع الأقسام بشكل متوازي
    final futures = _sections.entries.map((entry) async {
      try {
        print('Searching in ${entry.key} with endpoint: ${entry.value['endpoint']}');
        final response = await apiService.get(
          entry.value['endpoint']!,
          query: {
            'keyword': keyword,
            'per_page': '1', // نحتاج فقط لمعرفة العدد الإجمالي
          },
        );

        int count = 0;
        if (response is Map<String, dynamic>) {
          // محاولة استخراج العدد الإجمالي من الاستجابة
          if (response.containsKey('total')) {
            count = response['total'] ?? 0;
          } else if (response.containsKey('meta') && 
                     response['meta'] is Map<String, dynamic> &&
                     response['meta']['total'] != null) {
            count = response['meta']['total'];
          } else if (response.containsKey('data') && 
                     response['data'] is List) {
            count = (response['data'] as List).length;
          }
        } else if (response is List) {
          count = response.length;
        }

        if (count > 0) {
          results.add(SearchResult(
            keyword: keyword,
            section: entry.key,
            sectionArabic: entry.value['arabic']!,
            count: count,
            endpoint: entry.value['endpoint']!,
          ));
        }
      } catch (e) {
        // تجاهل الأخطاء للأقسام التي لا تستجيب
        print('Error searching in ${entry.key}: $e');
      }
    });

    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
      if (results.isNotEmpty) {
        _displayResults();
      } else {
        _hideResults();
      }
    }
  }

  void _displayResults() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideResults() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 300.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: widget.borderColor ?? const Color.fromRGBO(8, 194, 201, 1),
                  width: 1,
                ),
              ),
              child: _buildResultsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isSearching) {
      return Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12.w),
            Text(
              'جاري البحث...',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        child: Text(
          'لا توجد نتائج',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey[300],
      ),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Icon(
            Icons.search,
            color: widget.borderColor ?? const Color.fromRGBO(8, 194, 201, 1),
            size: 20.sp,
          ),
          title: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '"${result.keyword}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' في '),
                TextSpan(
                  text: result.sectionArabic,
                  style: TextStyle(
                    color: widget.borderColor ?? const Color.fromRGBO(8, 194, 201, 1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: (widget.borderColor ?? const Color.fromRGBO(8, 194, 201, 1)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${result.count}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: widget.borderColor ?? const Color.fromRGBO(8, 194, 201, 1),
              ),
            ),
          ),
          onTap: () {
            _hideResults();
            _focusNode.unfocus();
            widget.onResultSelected?.call(result);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building SmartSearchWidget');
    final s = S.of(context);
    final borderColor = widget.borderColor ?? const Color.fromRGBO(8, 194, 201, 1);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: widget.height ?? 35.h,
        padding: widget.padding,
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (value) {
            print('TextField onChanged called with: "$value"');
            _onSearchChanged(value);
          },
          decoration: InputDecoration(
            hintText: widget.hintText ?? s.smart_search,
            hintStyle: TextStyle(
              color: const Color.fromRGBO(129, 126, 126, 1),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: borderColor,
              size: 25.sp,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                      size: 20.sp,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _hideResults();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0.h),
          ),
        ),
      ),
    );
  }
}