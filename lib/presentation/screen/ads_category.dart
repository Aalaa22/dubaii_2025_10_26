import 'package:advertising_app/constant/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AdsCategoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items = [
    {
      "title": "Cars Sales",
      "image": "assets/images/salesCar.jpg",
      "route": '/car_sales_ads' // مسار الصفحة الجديدة
    },
    {
      "title": "Real Estate",
      "image": "assets/images/realEstate.jpg",
      "route": "/real_estate"
    },
    {
      "title": "Cars Rent",
      "image": "assets/images/careRent.jpg",
      "route": "/cars_rent"
    },
    {
      "title": "Cars Services",
      "image": "assets/images/car_services.png",
      "route": "/Frame 1707478476.png"
    },
    {
      "title": "Electronics & home appliances",
      "image": "assets/images/electronics.jpg",
      "route": "/electronics"
    },
    {
      "title": "Restaurants",
      "image": "assets/images/restaurant.jpg",
      "route": "/restaurants"
    },
    {"title": "Jobs", "image": "assets/images/jobs.jpg", "route": "/jobs"},
    {
      "title": "Other Services",
      "image": "assets/images/service.jpg",
      "route": "/other_services"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header بدون مسافة سفلية
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 40, 16, 0), // بدون padding سفلي
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 90,
                ),
                Text(
                  "Enjoy Free Ads",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: KTextColor,
                  ),
                ),
              ],
            ),
          ),
          // GridView بدون مسافة علوية
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18), // padding موحد للجريد
              crossAxisCount: 2,
              childAspectRatio: .98.h,
              mainAxisSpacing: 0,
              crossAxisSpacing: 12,
              children: items.map((item) {
                return GestureDetector(
                  onTap: () => context.go(item['route']), // التنقل عند الضغط
                  child: CategoryItem(
                    title: item['title'],
                    image: item['image'],
                    spacing: 0,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String title;
  final String image;
  final double spacing;

  const CategoryItem({
    required this.title,
    required this.image,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
