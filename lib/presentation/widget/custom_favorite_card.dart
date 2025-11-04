import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/car_rent_model.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/job_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoriteCard extends StatefulWidget {
  final FavoriteItemInterface item;
  final int categoryIndex;
  final VoidCallback onDelete;

  const FavoriteCard({
    super.key,
    required this.item,
    required this.categoryIndex,
    required this.onDelete,
  });

  @override
  State<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<FavoriteCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      clipBehavior: Clip.antiAlias, // لتحسين شكل الحواف الدائرية
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. الجزء العلوي: الصور والقلب الأحمر
          _buildImageSlider(),
          // 2. الجزء السفلي: التفاصيل المبنية بذكاء
          Flexible(child: _buildDynamicCardDetails()),
        ],
      ),
    );
  }

  // =================================================================
  // == الدوال المساعدة
  // =================================================================

  /// يبني الجزء العلوي من البطاقة (عارض الصور والأيقونات)
  Widget _buildImageSlider() {
    final item = widget.item;
    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: item.images.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _buildImageWidget(item.images[index]),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8)),
            child: Text("${_currentPage + 1}/${item.images.length}",
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  item.images.length,
                  (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.grey.shade400),
                      )),
            ),
          ),
        ),
        Positioned(top: 8, left: 8, child: _buildPriorityLabel(item.priority)),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.favorite, color: Colors.red, size: 30),
            tooltip: 'حذف من المفضلة',
          ),
        ),
      ],
    );
  }

  /// الدالة الذكية التي تبني التفاصيل وتحل مشكلة المساحات الفارغة
  Widget _buildDynamicCardDetails() {
    final item = widget.item;
    final List<Widget> detailsChildren = [];

    // --- إضافة الأجزاء العلوية الثابتة ---
    detailsChildren.add(_buildPriceAndDateRow());
    detailsChildren.add(SizedBox(height: 8.h));
    detailsChildren.add(Text(item.title,
        style: TextStyle(
            color: KTextColor, fontWeight: FontWeight.w600, fontSize: 16.sp),
        maxLines: 2,
        overflow: TextOverflow.ellipsis));

    // --- إضافة الأجزاء الاختيارية بناءً على التصنيف ---
    switch (widget.categoryIndex) {
      case 0: // سيارات للبيع (لديها line1)
        detailsChildren.add(SizedBox(height: 6.h));
        detailsChildren.add(RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: TextStyle(
                color: KTextColor, fontSize: 14.sp, fontFamily: 'Poppins'),
            children: item.line1.split(' ').map((word) {
              final parts = word.split(':');
              return TextSpan(
                text: parts.length == 2 ? '${parts[0]}: ' : '$word ',
                style: TextStyle(fontWeight: FontWeight.w600),
                children: [
                  if (parts.length == 2)
                    TextSpan(
                        text: '${parts[1]} ',
                        style: TextStyle(fontWeight: FontWeight.w500))
                ],
              );
            }).toList(),
          ),
        ));
        break;

      case 3: // وظائف (لديها requirement)
        if (item is JobModel) {
          detailsChildren.add(SizedBox(height: 6.h));
          detailsChildren.add(Text(item.requirment,
              style: TextStyle(
                  color: Color.fromRGBO(0, 30, 90, 1),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis));
        }
        break;

      case 4: // تأجير سيارات (لديها day_rent و month_rent)
        if (item is CarRentModel) {
          detailsChildren.add(SizedBox(height: 8.h));
          detailsChildren.add(Row(
            children: [
               _buildLabelWithValue("Day Rent", item.day_rent),
                    const SizedBox(width: 16),
                    _buildLabelWithValue("Month Rent", item.month_rent),
                  ],
          ));
        }
        break;

      case 5: // خدمات سيارات (لديها line1)
        detailsChildren.add(SizedBox(height: 6.h));
        detailsChildren.add(Text(item.line1,
            style: TextStyle(
                color: Color.fromRGBO(0, 30, 90, 1),
                fontSize: 14,
                fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis));
        break;
    }

    // --- إضافة الأجزاء السفلية الثابتة ---
    detailsChildren.add(SizedBox(height: 10.h));
    if (item.details.isNotEmpty) {
      detailsChildren.add(Text(item.details,
          style: TextStyle(
              fontSize: 14.sp,
              color: KTextColor,
              fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis));
    }
    detailsChildren.add(_buildLocationAndDeleteRow());
    detailsChildren.add(_buildContactRow());

    // --- بناء الـ Column النهائية ---
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: detailsChildren,
      ),
    );
  }

  // --- دوال مساعدة للأجزاء المشتركة ---

  Widget _buildPriceAndDateRow() => Row(children: [
        SvgPicture.asset('assets/icons/priceicon.svg',
            width: 24.w, height: 19.h),
        SizedBox(width: 10.w),
        Text(widget.item.price,
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp)),
        const Spacer(),
        Text(widget.item.date,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400)),
      ]);

  Widget _buildLocationAndDeleteRow() => Padding(padding: const EdgeInsets.only(top: 0.0),
        child: Row(children: [
          SvgPicture.asset('assets/icons/locationicon.svg',
              width: 16.w, height: 20.h),
          const SizedBox(width: 10),
          Expanded(
              child: Text(widget.item.location,
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: KTextColor,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 44.w,
            height: 44.h,
            child: IconButton(
                onPressed: widget.onDelete,
                icon: SvgPicture.asset('assets/icons/deleted.svg',
                    width: 23.w, height: 28.h)),
          ),
        ]),
      );

  Widget _buildContactRow() => Row(children: [
        Text(widget.item.contact,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: KTextColor)),
        const Spacer(),
        _buildActionIcon(FontAwesomeIcons.whatsapp),
        const SizedBox(width: 5),
        _buildActionIcon(Icons.phone),
      ]);

  Widget _buildActionIcon(IconData icon) =>
   Container(
        height: 35.h,
        width: 62.w,
        decoration: BoxDecoration(
            color: const Color(0xFF01547E),
            borderRadius: BorderRadius.circular(8)),
        child: Center(child: Icon(icon, color: Colors.white, size: 22)),
      );

 Widget _buildLabelWithValue(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label ",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(0, 30, 90, 1),
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: const Color.fromRGBO(0, 30, 90, 1),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

 
  Widget _buildPriorityLabel(AdPriority priority) {
    final (String, Icon?) data = switch (priority) {
      AdPriority.PremiumStar => (
          'Premium',
          const Icon(Icons.star, color: Colors.amber, size: 18)
        ),
      AdPriority.premium => ('Premium', null),
      AdPriority.featured => ('Featured', null),
      AdPriority.free => ('', null),
    };
    if (data.$1.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFC9F8FE), Color(0xFF08C2C9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(data.$1,
            style: const TextStyle(
                color: KTextColor, fontSize: 12, fontWeight: FontWeight.w400)),
        if (data.$2 != null) ...[const SizedBox(width: 2), data.$2!],
      ]),
    );
  }

  /// بناء ويدجت الصورة باستخدام ImageUrlHelper
  Widget _buildImageWidget(String imagePath) {
    final rawPath = imagePath.trim();
    if (rawPath.isEmpty || rawPath.toLowerCase() == 'null') {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      );
    }

    final processedUrl = ImageUrlHelper.getFullImageUrl(rawPath);

    // Try network when the processed URL is http/https
    if (processedUrl.startsWith('http://') || processedUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: processedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.error, size: 50, color: Colors.red),
        ),
      );
    }

    // Use local asset if path explicitly begins with assets/
    if (rawPath.startsWith('assets/')) {
      return Image.asset(
        rawPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        errorBuilder: (context, error, stackTrace) => Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.error, size: 50, color: Colors.red),
        ),
      );
    }

    // Unknown/invalid path -> neutral placeholder
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    );
  }
}



















// import 'package:advertising_app/constant/string.dart';
// import 'package:advertising_app/generated/l10n.dart';
// import 'package:advertising_app/data/model/ad_priority.dart';
// import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class FavoriteCard extends StatefulWidget {
//   final FavoriteItemInterface item;
//   final VoidCallback onDelete;
//   final bool showDelete;
//   final VoidCallback? onAddToFavorite; 

//   const FavoriteCard({
//     super.key,
//     required this.item,
//     required this.onDelete,
//     this.showDelete = true,
//     this.onAddToFavorite,
//   });

//   @override
//   State<FavoriteCard> createState() => _FavoriteCardState();
// }

// class _FavoriteCardState extends State<FavoriteCard> {
//   late PageController _pageController;
//   int _currentPage = 0;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController();
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final item = widget.item;

//     return Card(
//       color: Colors.white,
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               SizedBox(
//                 height: 200,
//                 child: PageView.builder(
//                   controller: _pageController,
//                   itemCount: item.images.length,
//                   onPageChanged: (index) =>
//                       setState(() => _currentPage = index),
//                   itemBuilder: (context, index) => ClipRRect(
//                     borderRadius:
//                         const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.asset(
//                       item.images[index],
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: 8,
//                 left: 8,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     "${_currentPage + 1}/${item.images.length}",
//                     style: TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: 8,
//                 left: 0,
//                 right: 0,
//                 child: Align(
//                   alignment: Alignment.center,
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: List.generate(item.images.length, (index) {
//                       return Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 2),
//                         width: 7,
//                         height: 7,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: _currentPage == index
//                               ? Colors.white
//                               : Colors.grey.shade400,
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//               ),
//               // نجمة أو لوجو الأولوية
//               Positioned(
//                 top: 8,
//                 left: 8,
//                 child: _buildPriorityLabel(item.priority),
//               ),
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: _buildTopRightIcon(),  ),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     SvgPicture.asset(
//                       'assets/icons/priceicon.svg',
//                       width: 24.w,
//                       height: 19.h,
//                     ),
//                     SizedBox(width: 10.w),
//                     Text(
//                       item.price,
//                       style: TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.w700,
//                         fontSize: 16.sp,
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       item.date,
//                       style: TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12.sp,
//                           fontWeight: FontWeight.w400),
//                     )
//                   ],
//                 ),
//                 SizedBox(height: 8.h),
//                 Text(
//                   item.title,
//                   style: TextStyle(
//                     color: KTextColor,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16.sp,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 RichText(
//                   text: TextSpan(
//                     children: item.line1.split(' ').map((word) {
//                       final parts = word.split(':');
//                       if (parts.length == 2) {
//                         return TextSpan(
//                           text: '${parts[0]}:',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: KTextColor,
//                             fontSize: 14.sp,
//                           ),
//                           children: [
//                             TextSpan(
//                               text: '${parts[1]}',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: KTextColor,
//                                 fontSize: 16.sp,
//                               ),
//                             ),
//                           ],
//                         );
//                       } else {
//                         return TextSpan(
//                           text: '$word ',
//                           style: const TextStyle(
//                             color: KTextColor,
//                             fontSize: 16,
//                           ),
//                         );
//                       }
//                     }).toList(),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   item.details,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     color: KTextColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     SvgPicture.asset(
//                       'assets/icons/locationicon.svg',
//                       width: 16.w,
//                       height: 20.h,
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text(
//                         item.location,
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           color: KTextColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     SizedBox(
//                       width: 38.w,
//                       height: 38.h,
//                       child: Offstage(
//                         offstage: !widget.showDelete,
//                         child: IconButton(
//                           onPressed: widget.onDelete,
//                           icon: SvgPicture.asset(
//                             'assets/icons/deleted.svg',
//                             width: 23.w,
//                             height: 28.h,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Text(
//                       item.contact,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14.sp,
//                         color: KTextColor,
//                       ),
//                     ),
//                     const Spacer(),
//                     _buildActionIcon(FontAwesomeIcons.whatsapp),
//                     const SizedBox(width: 5),
//                     _buildActionIcon(Icons.phone),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionIcon(IconData icon) {
//     return Container(
//       height: 35.h,
//       width: 62.w,
//       decoration: BoxDecoration(
//         color: const Color(0xFF01547E),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Center(
//         child: Icon(icon, color: Colors.white, size: 22),
//       ),
//     );
//   }

//   Widget _buildPriorityLabel(AdPriority priority) {
//     String text;
//     Icon? icon;

//     switch (priority) {
//       case AdPriority.PremiumStar:
//         text = 'Premium';
//         icon = const Icon(Icons.star, color: Colors.amber, size: 18);
//         break;
//       case AdPriority.premium:
//         text = 'Premium';
//         break;
//       case AdPriority.featured:
//         text = 'Featured';
//         break;
//       case AdPriority.free:
//         text = 'Free';
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFFC9F8FE), Color(0xFF08C2C9)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             text,
//             style: const TextStyle(
//               color: KTextColor,
//               fontSize: 12,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//           if (icon != null) ...[
//             const SizedBox(width: 2),
//             icon,
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildTopRightIcon() {
//   if (widget.onAddToFavorite != null) {
//     return IconButton(
//       icon: const Icon(Icons.favorite_border, color: Colors.grey),
//       onPressed: _handleAddToFavorite,
//     );
//   } else if (widget.showDelete) {
//     return IconButton(
//       icon: const Icon(Icons.favorite, color: Colors.red),
//       onPressed: widget.onDelete,
//     );
//   } else {
//     return const SizedBox.shrink();
//   }
// }
  
//   void _handleAddToFavorite() {
  // showDialog(
  //   context: context,
  //   builder: (context) => AlertDialog(
  //     title:  Text(S.of(context).add_to_favorite,style: TextStyle(color: KTextColor,fontSize: 16)), // "إضافة إلى المفضلة"
  //   content: Text(S.of(context).confirm_add_to_favorite,style: TextStyle(color: KTextColor,fontSize: 18),), // "هل تريد إضافة هذا العنصر إلى المفضلة؟"
  //  actions: [
  //       TextButton(
  //         child:Text(S.of(context).cancel,style: TextStyle(color: KTextColor,fontSize: 20)),
  //         onPressed: () => Navigator.pop(context),
  //       ),
  //       TextButton(
  //         child:  Text(S.of(context).yes,style: TextStyle(color: KTextColor,fontSize: 20)),
  //         onPressed: () {
  //           Navigator.pop(context);
  //           widget.onAddToFavorite?.call();
  //         // ✅ Optional: عرض SnackBar تأكيد
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text(S.of(context).added_to_favorite)),
  //           );
  //         },
          
  //       ),
        
  //     ],
  //   ),
  // );
// }

// }


