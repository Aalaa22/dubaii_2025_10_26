import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class CustomScrollOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  /// إظهار الـ overlay
  static void show(BuildContext context, {
    required Widget content,
    double? elevation,
    Color? backgroundColor,
    EdgeInsets? padding,
    Border? border,
  }) {
    if (_isVisible) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        right: 0,
        child: Material(
          elevation: elevation ?? 6,
          color: backgroundColor ?? Colors.white,
          child: Container(
            padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              border: border ?? Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  /// إخفاء الـ overlay
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }

  /// التحقق من حالة الـ overlay
  static bool get isVisible => _isVisible;
}

/// Widget للتحكم في الـ scroll overlay بشكل تلقائي
class ScrollOverlayController extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final Widget overlayContent;
  final double showThreshold; // متى يظهر الـ overlay
  final double hideThreshold; // متى يختفي الـ overlay
  final double scrollSensitivity; // حساسية التمرير
  final Function()? onOverlayShow;
  final Function()? onOverlayHide;

  const ScrollOverlayController({
    Key? key,
    required this.child,
    required this.scrollController,
    required this.overlayContent,
    this.showThreshold = 150.0,
    this.hideThreshold = 100.0,
    this.scrollSensitivity = 3.0,
    this.onOverlayShow,
    this.onOverlayHide,
  }) : super(key: key);

  @override
  State<ScrollOverlayController> createState() => _ScrollOverlayControllerState();
}

class _ScrollOverlayControllerState extends State<ScrollOverlayController>
    with WidgetsBindingObserver {
  
  bool _showOverlay = false;
  double _lastOffset = 0;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      CustomScrollOverlay.hide();
      _isActive = false;
    } else if (state == AppLifecycleState.resumed) {
      _isActive = true;
      if (_showOverlay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CustomScrollOverlay.show(context, content: widget.overlayContent);
          }
        });
      }
    }
  }

  void _handleScroll() {
    if (!_isActive || !mounted) return;
    
    final currentOffset = widget.scrollController.offset;
    final scrollDelta = currentOffset - _lastOffset;

    // منطق إظهار الـ overlay عند scroll up
    if (scrollDelta < -widget.scrollSensitivity && !_showOverlay) {
      if (currentOffset > widget.showThreshold) {
        setState(() {
          _showOverlay = true;
        });
        CustomScrollOverlay.show(context, content: widget.overlayContent);
        widget.onOverlayShow?.call();
      }
    } 
    // إخفاء الـ overlay عند scroll down
    else if (scrollDelta > widget.scrollSensitivity && _showOverlay) {
      setState(() {
        _showOverlay = false;
      });
      CustomScrollOverlay.hide();
      widget.onOverlayHide?.call();
    }
    // إخفاء الـ overlay عند الوصول لأعلى الصفحة
    else if (currentOffset <= widget.hideThreshold && _showOverlay) {
      setState(() {
        _showOverlay = false;
      });
      CustomScrollOverlay.hide();
      widget.onOverlayHide?.call();
    }

    _lastOffset = currentOffset;
  }

  @override
  void dispose() {
    _isActive = false;
    CustomScrollOverlay.hide();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Widget جاهز لمحتوى الـ overlay الخاص بصفحة السيارات
class CarSalesOverlayContent extends StatelessWidget {
  final VoidCallback onBackPressed;
  final List<String> filterLabels;
  final String adCountText;
  final String sortText;
  final bool sortValue;
  final ValueChanged<bool>? onSortChanged;

  const CarSalesOverlayContent({
    Key? key,
    required this.onBackPressed,
    required this.filterLabels,
    required this.adCountText,
    required this.sortText,
    this.sortValue = true,
    this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Back button
        GestureDetector(
          onTap: onBackPressed,
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.black87, size: 17.sp),
              Transform.translate(
                offset: Offset(-3.w, 0),
                child: Text(
                  'رجوع', // يمكن تمريرها كمعامل
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        
        // Filter section
        Row(
          children: [
            SvgPicture.asset('assets/icons/filter.svg',
                width: 25.w, height: 25.h),
            SizedBox(width: 12.w),
            Expanded(
              child: Row(
                children: filterLabels.map((label) => [
                  Expanded(child: _buildFilterChip(label)),
                  if (filterLabels.indexOf(label) < filterLabels.length - 1)
                    SizedBox(width: 7.w),
                ]).expand((x) => x).toList(),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        
        // Ad count and sort section
        Row(
          children: [
            Text(
              adCountText,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
            Spacer(),
            Container(
              height: 37.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF08C2C9)),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/locationicon.svg',
                    width: 18.w,
                    height: 18.h,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    sortText,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Switch(
                    value: sortValue,
                    onChanged: onSortChanged,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF08C2C9),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      height: 33.h,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF08C2C9)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.black87,
            size: 14.sp,
          ),
        ],
      ),
    );
  }
}