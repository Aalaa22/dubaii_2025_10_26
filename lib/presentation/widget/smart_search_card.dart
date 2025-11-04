import 'package:advertising_app/data/model/smart_search_model.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Local color constants to match app style
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

class SmartSearchCard extends StatelessWidget {
  final String keyword;
  final List<SmartSearchItem> results;
  final ValueChanged<String>? onCategoryTap;
  final String categoryLabel;
  final String totalAdsLabel;
  final String noResultsLabel;

  const SmartSearchCard({
    super.key,
    required this.keyword,
    required this.results,
    this.onCategoryTap,
    required this.categoryLabel,
    required this.totalAdsLabel,
    required this.noResultsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Card(
      elevation: 6,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: KPrimaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    keyword,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: KTextColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ...results.map((item) => InkWell(
                  onTap: onCategoryTap == null ? null : () => onCategoryTap!(item.itemType),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$categoryLabel${item.itemType}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: KTextColor,
                            ),
                          ),
                        ),
                        Text(
                          '$totalAdsLabel ${item.totalAds}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            color: KPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            if (results.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    noResultsLabel,
                    style: const TextStyle(color: KTextColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}