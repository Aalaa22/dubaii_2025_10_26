import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCategoryGrid extends StatelessWidget {
  final List<String> categories;
  final void Function(int index)? onTap; // للـ Favorite
  final void Function(String title)? onCategoryPressed; // للـ Home
  final int? selectedIndex;

  const CustomCategoryGrid({
    super.key,
    required this.categories,
    this.onTap,
    this.onCategoryPressed,
    this.selectedIndex,
  });

  double getResponsiveFontSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return screenWidth > 600
        ? 14
        : screenWidth > 400
            ? 10.5
            : screenWidth > 360
                ? 10.4
                : 10;
    //  : screenWidth > 360
    //           ? 9
    //           : 7.5;
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final fontSize = getResponsiveFontSize(context).sp;
    // نقسم العناصر إلى صفوف
    final rows = <List<String>>[];
    for (int i = 0; i < categories.length; i += 4) {
      rows.add(categories.skip(i).take(4).toList());
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            children: row.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;

              final globalIndex = categories.indexOf(title);
              final isSelected = selectedIndex != null
                  ? globalIndex == selectedIndex
                  : globalIndex == 0;
              final isWide = title.contains('Electronics');
              final flex = isWide ? 2 : 1;

              return Flexible(
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.4),
                  child: GestureDetector(
                    onTap: () {
                      onTap?.call(globalIndex);
                      onCategoryPressed?.call(title);
                    },
                    child: Container(
                      height: 37.h,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Color.fromRGBO(1, 84, 126, 1) : null,
                        gradient: isSelected
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFE4F8F6),
                                  Color(0xFFC9F8FE),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? KTextColor : Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.4),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                             
                              fontSize: fontSize.sp,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : Color.fromRGBO(0, 30, 91, 1),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:advertising_app/constants.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class CustomCategoryGrid extends StatelessWidget {
//   final List<String> categories;
//   final void Function(int index)? onTap;
//   final void Function(String title)? onCategoryPressed;
//   final int? selectedIndex;

//   const CustomCategoryGrid({
//     super.key,
//     required this.categories,
//     this.onTap,
//     this.onCategoryPressed,
//     this.selectedIndex,
//   });

//   double getResponsiveFontSize(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     debugPrint('📱 screen width: $screenWidth');
//     return screenWidth > 600
//         ? 14
       
//         : screenWidth > 360
//             ? 9   
//             : screenWidth > 320
//                 ? 8
//                 : 6;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isRTL = Directionality.of(context) == TextDirection.rtl;
//     final fontSize = getResponsiveFontSize(context).sp;

//     final rows = <List<String>>[];
//     for (int i = 0; i < categories.length; i += 4) {
//       rows.add(categories.skip(i).take(4).toList());
//     }

//     final specialButtons = [
//       'Cars Sales',
//       'real estate',
//       'Electronics & Home \n Appliances',
//       'Jobs',
//       'Car Rent',
//       'Car Services',
//       'Restaurants',
//       //'Other Services'
//     ];

//     return Column(
//       children: rows.map((row) {
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 2),
//           child:Expanded(
//             child: Row(
//               textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
//               children: row.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final title = entry.value;
//                 final globalIndex = categories.indexOf(title);
//                 final isSelected = selectedIndex != null
//                     ? globalIndex == selectedIndex
//                     : globalIndex == 0;
//                 final isWide = title.contains('Electronics');
//                 final flex = isWide ? 2 : 1;
//                 final isTargetButton = specialButtons.contains(title);
            
//                 if (isTargetButton) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 1.4),
//                     child: GestureDetector(
//                       onTap: () {
//                         onTap?.call(globalIndex);
//                         onCategoryPressed?.call(title);
//                       },
//                       child: IntrinsicWidth(
//                         child: Container(
//                           height: 43,
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? const Color.fromRGBO(1, 84, 126, 1)
//                                 : null,
//                             gradient: isSelected
//                                 ? null
//                                 : const LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: [
//                                       Color(0xFFE4F8F6),
//                                       Color(0xFFC9F8FE),
//                                     ],
//                                   ),
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                               color:
//                                   isSelected ? KTextColor : Colors.grey.shade300,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.07),
//                                 blurRadius: 2,
//                                 offset: const Offset(0, 1),
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 6),
//                               child: Text(
//                                 title,
//                                 textAlign: TextAlign.center,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   fontFamily: 'Montserrat',
//                                   fontSize: fontSize.sp,
//                                   fontWeight: FontWeight.w400,
//                                   color: isSelected
//                                       ? Colors.white
//                                       : const Color.fromRGBO(0, 30, 91, 1),
//                                   height: 1.2,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }
            
//                 return Flexible(
//                   flex: flex,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 1.4),
//                     child: GestureDetector(
//                       onTap: () {
//                         onTap?.call(globalIndex);
//                         onCategoryPressed?.call(title);
//                       },
//                       child: Container(
//                         height: 43,
//                         decoration: BoxDecoration(
//                           color: isSelected
//                               ? const Color.fromRGBO(1, 84, 126, 1)
//                               : null,
//                           gradient: isSelected
//                               ? null
//                               : const LinearGradient(
//                                   begin: Alignment.topCenter,
//                                   end: Alignment.bottomCenter,
//                                   colors: [
//                                     Color(0xFFE4F8F6),
//                                     Color(0xFFC9F8FE),
//                                   ],
//                                 ),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                             color: isSelected ? KTextColor : Colors.grey.shade300,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.07),
//                               blurRadius: 2,
//                               offset: const Offset(0, 1),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 0),
//                             child: Text(
//                               title,
//                               textAlign: TextAlign.center,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontFamily: 'Montserrat',
//                                 fontSize: fontSize.sp,
//                                 fontWeight: FontWeight.w400,
//                                 color: isSelected
//                                     ? Colors.white
//                                     : const Color.fromRGBO(0, 30, 91, 1),
//                                 height: 1.2,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }































// import 'package:flutter/material.dart';
// import 'package:advertising_app/constants.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class CustomCategoryGrid extends StatelessWidget {
//   final List<String> categories;
//   final void Function(int index)? onTap; // للـ Favorite
//   final void Function(String title)? onCategoryPressed; // للـ Home
//   final int? selectedIndex;

//   const CustomCategoryGrid({
//     super.key,
//     required this.categories,
//     this.onTap,
//     this.onCategoryPressed,
//     this.selectedIndex,
//   });

//   double getResponsiveFontSize(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;

//     debugPrint('📱 screen width: $screenWidth ////////////////////////////////////////////////////////////');

//     return screenWidth > 600
//         ? 14
//         // : screenWidth > 390
//         //     ? 12
//         //     : screenWidth > 380
//         //         ? 12
//                 : screenWidth > 360
//                     ? 12
//                     : 8;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isRTL = Directionality.of(context) == TextDirection.rtl;
//     final fontSize = getResponsiveFontSize(context);

//     // نقسم العناصر إلى صفوف
//     final rows = <List<String>>[];
//     for (int i = 0; i < categories.length; i += 4) {
//       rows.add(categories.skip(i).take(4).toList());
//     }

//     // الأزرار اللي تاخد عرض على قد الكلمة
//     final specialButtons = ['Jobs', 'Car Rent', "Electronics & Home \n Appliances","Restaurants","Car Services"];

//     return Column(
//       children: rows.map((row) {
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 2),
//           child: Row(
//             textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
//             children: row.asMap().entries.map((entry) {
//               final index = entry.key;
//               final title = entry.value;

//               final globalIndex = categories.indexOf(title);
//               final isSelected = selectedIndex != null
//                   ? globalIndex == selectedIndex
//                   : globalIndex == 0;
//               final isWide = title.contains('Electronics');
//               final flex = isWide ? 2 : 1;

//               final isTargetButton = specialButtons.contains(title);

//               if (isTargetButton) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 1.4),
//                   child: GestureDetector(
//                     onTap: () {
//                       onTap?.call(globalIndex);
//                       onCategoryPressed?.call(title);
//                     },
//                     child: IntrinsicWidth(
//                       child: Container(
//                         height: 43,
//                         decoration: BoxDecoration(
//                           color: isSelected
//                               ? const Color.fromRGBO(1, 84, 126, 1)
//                               : null,
//                           gradient: isSelected
//                               ? null
//                               : const LinearGradient(
//                                   begin: Alignment.topCenter,
//                                   end: Alignment.bottomCenter,
//                                   colors: [
//                                     Color(0xFFE4F8F6),
//                                     Color(0xFFC9F8FE),
//                                   ],
//                                 ),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                             color: isSelected
//                                 ? KTextColor
//                                 : Colors.grey.shade300,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.07),
//                               blurRadius: 2,
//                               offset: const Offset(0, 1),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 6),
//                             child: Text(
//                               title,
//                               textAlign: TextAlign.center,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontFamily: 'Montserrat',
//                                 fontSize: fontSize,
//                                 fontWeight: FontWeight.w400,
//                                 color: isSelected
//                                     ? Colors.white
//                                     : const Color.fromRGBO(0, 30, 91, 1),
//                                 height: 1.2,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }

//               // باقي الأزرار العادية
//               return Flexible(
//                 flex: flex,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 1.4),
//                   child: GestureDetector(
//                     onTap: () {
//                       onTap?.call(globalIndex);
//                       onCategoryPressed?.call(title);
//                     },
//                     child: Container(
//                       height: 43,
//                       decoration: BoxDecoration(
//                         color: isSelected
//                             ? const Color.fromRGBO(1, 84, 126, 1)
//                             : null,
//                         gradient: isSelected
//                             ? null
//                             : const LinearGradient(
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                                 colors: [
//                                   Color(0xFFE4F8F6),
//                                   Color(0xFFC9F8FE),
//                                 ],
//                               ),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: isSelected
//                               ? KTextColor
//                               : Colors.grey.shade300,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.07),
//                             blurRadius: 2,
//                             offset: const Offset(0, 1),
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 0),
//                           child: Text(
//                             title,
//                             textAlign: TextAlign.center,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontFamily: 'Montserrat',
//                               fontSize: fontSize,
//                               fontWeight: FontWeight.w400,
//                               color: isSelected
//                                   ? Colors.white
//                                   : const Color.fromRGBO(0, 30, 91, 1),
//                               height: 1.2,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }
