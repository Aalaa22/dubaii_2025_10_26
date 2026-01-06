import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/legal_contents.dart';
import 'package:advertising_app/constant/string.dart';

enum LegalType { terms, privacy }

class LegalDialog extends StatelessWidget {
  final LegalType type;
  final bool isArabic;

  const LegalDialog({
    super.key,
    required this.type,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    String title = "";
    String content = "";

    if (type == LegalType.terms) {
      title =
          isArabic ? LegalContents.termsTitleAr : LegalContents.termsTitleEn;
      content = isArabic
          ? LegalContents.termsContentAr
          : LegalContents.termsContentEn;
    } else {
      title = isArabic
          ? LegalContents.privacyTitleAr
          : LegalContents.privacyTitleEn;
      content = isArabic
          ? LegalContents.privacyContentAr
          : LegalContents.privacyContentEn;
    }

    return Container(
      height: 0.8.sh,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, title),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: KTextColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(8, 194, 201, 1),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Text(
            isArabic ? "إغلاق" : "Close",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  static void show(BuildContext context,
      {required LegalType type, required bool isArabic}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LegalDialog(type: type, isArabic: isArabic),
    );
  }
}
