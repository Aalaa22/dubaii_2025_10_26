import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// تعريف متغير اللون المستخدم إذا لم يكن معرفاً
const KTextColor = Color(0xFF001E5A);

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  // لاحظ: القائمة المترجمة تُبنى داخل build باستخدام S.of(context)

  @override
  Widget build(BuildContext context) {
    // استخدام MediaQuery لتحديد الأبعاد
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    // عناصر الشبكة مترجمة حسب اللغة الحالية
    final localizedItems = [
      {
        "title": S.of(context).carsales,
        "image": "assets/images/salesCar.jpg",
        "route": "/car_sales_ads"
      },
      {
        "title": S.of(context).realestate,
        "image": "assets/images/realEstate.jpg",
        "route": "/real_estate_ads"
      },
      {
        "title": S.of(context).carrent,
        "image": "assets/images/careRent.jpg",
        "route": "/car_rent_ads"
      },
      {
        "title": S.of(context).carservices,
        "image": "assets/images/car_services.png",
        "route": "/car_services_ads"
      },
      {
        "title": S.of(context).electronics,
        "image": "assets/images/electronics.jpg",
        "route": "/electronics_ads"
      },
      {
        "title": S.of(context).restaurants,
        "image": "assets/images/restaurant.jpg",
        "route": "/resturant_ads"
      },
      {
        "title": S.of(context).jobs,
        "image": "assets/images/jobs.jpg",
        "route": "/job_ads"
      },
      {
        "title": S.of(context).otherservices,
        "image": "assets/images/service.jpg",
        "route": "/other_servics_ads"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- شريط العنوان باستخدام Stack لتحقيق المحاذاة المطلوبة ---
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // زيادة بسيطة في الهامش
              ),
              child: SizedBox(
                height: screenHeight * 0.1, // تحديد ارتفاع ثابت للهيدر
                child: Stack(
                  children: [
                    // --- 1. الشعار والعنوان في المنتصف ---
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize
                            .min, // لجعل الـ Row يأخذ أقل مساحة ممكنة
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: screenHeight * 1, // تعديل الارتفاع قليلاً
                          ),
                          const SizedBox(width: 2),
                          Text(
                            S.of(context).enjoyFreeAds,
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                              color: KTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
SizedBox(width: 5),
                    // --- 2. زر الرجوع في اليسار ---
                    Align(
                    //  alignment: Alignment.topLeft,
                      child:
                         GestureDetector(
                        onTap: () => context.pop(),
                        child: Row(
                          children: [
                            const SizedBox(width: 18),
                            Icon(Icons.arrow_back_ios,
                                color: KTextColor, size: 17.sp),
                            Transform.translate(
                              offset: Offset(-3.w, 0),
                              child: Text(
                                S.of(context).back,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: KTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                     
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            // --- الشبكة باستخدام Wrap ---
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), // لمنع التمرير
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: Wrap(
                    spacing: screenWidth * 0.02,
                    runSpacing: screenHeight * 0.015,
                    alignment: WrapAlignment.center,
                    children: localizedItems.map((item) {
                      return GestureDetector(
                        onTap: () => context.push(item['route']!),
                        child: PostAdItem(
                          title: item['title']!,
                          image: item['image']!,
                          screenWidth: screenWidth,
                          isPortrait: isPortrait,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ),]
          
        ),
      ),
    );
  }
}

// --- ويدجت موحد لكل عنصر في الشبكة (بدون تغيير) ---
class PostAdItem extends StatelessWidget {
  final String title;
  final String image;
  final double screenWidth;
  final bool isPortrait;

  const PostAdItem({
    required this.title,
    required this.image,
    required this.screenWidth,
    required this.isPortrait,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemWidth = isPortrait ? screenWidth * 0.42 : screenWidth * 0.3;

    return Container(
      width: itemWidth,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              // borderRadius: const BorderRadius.only(
              //   topLeft: Radius.circular(0),
              //   topRight: Radius.circular(0),
              // ),
              child: Image.asset(
                image,
                // ضبط عرض صورة car_services فقط لتقليل التكبير غير المرغوب
                fit: image.endsWith('car_services.png')
                    ? BoxFit.contain
                    : BoxFit.cover,
                width: double.infinity,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.001),
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: KTextColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
