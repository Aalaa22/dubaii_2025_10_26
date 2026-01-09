// // file: lib/presentation/screen/all_dealer_ads_screen.dart

// import 'package:advertising_app/data/car_sales_data_dummy.dart';
// import 'package:advertising_app/presentation/screen/car_sales_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class AllDealerAdsScreen extends StatelessWidget {
//   final String dealerName;
//   const AllDealerAdsScreen({super.key, required this.dealerName});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('إعلانات $dealerName'), // عرض اسم المعلن في العنوان
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black, // لون سهم الرجوع والنص
//         elevation: 1,
//       ),
//       body: GridView.builder(
//         padding: EdgeInsets.all(8.w),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // عرض إعلانين في كل صف
//           childAspectRatio: (145 / 175), // الحفاظ على نفس نسبة العرض للارتفاع
//           crossAxisSpacing: 8.w,
//           mainAxisSpacing: 8.h,
//         ),
//         // عرض جميع الإعلانات من القائمة الوهمية
//         itemCount: CarSalesDummyData.length,
//         itemBuilder: (context, index) {
//           final car = CarSalesDummyData[index];
//           // إعادة استخدام نفس بطاقة الإعلان
//           // لا نستخدم Padding هنا لأن GridView يوفر المسافات
//           return CarCardWidget(car: car);
//         },
//       ),
//     );
//   }
// }