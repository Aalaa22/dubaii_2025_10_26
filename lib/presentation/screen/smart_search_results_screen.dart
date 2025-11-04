import 'package:advertising_app/data/model/smart_search_model.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/smart_search_card.dart';
import 'package:advertising_app/utils/category_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

class SmartSearchResultsScreen extends StatelessWidget {
  final SmartSearchResponse response;
  const SmartSearchResultsScreen({super.key, required this.response});

  bool _localeIsAr(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');
  }

  String? _routeForCategory(String itemType) {
    // Normalize to API slugs, then map to existing top-level routes
    final api = CategoryMapper.toApiFormat(itemType);
    switch (api) {
      case 'car_sales':
        return '/cars-sales';
      case 'real_estate':
        return '/real_estate_search';
      case 'electronics':
        return '/electronic_search';
      case 'jobs':
        return '/job_search';
      case 'car_rent':
        return '/car_rent_search';
      case 'car_services':
        return '/car_service_search';
      case 'restaurant':
        return '/restaurant_search';
      case 'other_services':
        return '/other_service_search';
      default:
        return null;
    }
  }

  Object? _filtersForRoute(String route, String keyword) {
    // Provide a minimal filter payload where supported
    switch (route) {
      case '/cars-sales':
      case '/real_estate_search':
      case '/electronic_search':
      case '/car_service_search':
      case '/other_service_search':
      case '/job_search':
        return <String, String>{'keyword': keyword};
      case '/car_rent_search':
      case '/restaurant_search':
        return <String, dynamic>{'keyword': keyword};
      case '/home':
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: KTextColor),
        title: Text(
          s.smart_search,
          style: TextStyle(color: KTextColor, fontWeight: FontWeight.w600, fontSize: 16.sp),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: response.results.isEmpty
            ? SmartSearchCard(
                keyword: response.keyword,
                results: const [],
                categoryLabel: s.category,
                totalAdsLabel: _localeIsAr(context) ? 'إجمالي الإعلانات' : 'Total Ads',
                noResultsLabel: _localeIsAr(context) ? 'لا توجد نتائج' : 'No results',
              )
            : ListView.separated(
                itemCount: response.results.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final item = response.results[index];
                  return SmartSearchCard(
                    keyword: response.keyword,
                    results: [item],
                    categoryLabel: s.category,
                    totalAdsLabel: _localeIsAr(context) ? 'إجمالي الإعلانات' : 'Total Ads',
                    noResultsLabel: _localeIsAr(context) ? 'لا توجد نتائج' : 'No results',
                    onCategoryTap: (category) {
                      final route = _routeForCategory(category);
                      if (route != null) {
                        final filters = _filtersForRoute(route, response.keyword);
                        if (filters != null) {
                          context.push(route, extra: filters);
                        } else {
                          context.push(route);
                        }
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}