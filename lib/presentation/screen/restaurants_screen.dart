import 'dart:math';
import 'package:advertising_app/data/restaurant_data_dummy.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:advertising_app/presentation/widget/unified_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/restaurants_info_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:advertising_app/utils/favorites_helper.dart';
import 'package:advertising_app/data/model/best_advertiser_adapters.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> with FavoritesHelper<RestaurantsScreen> {
  int _selectedIndex = 6;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // متغيرات الاختيار الواحد
  String? _selectedEmirate;
  String? _selectedDistrict;
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load favorites cache
      loadFavoriteIds();
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    final provider = Provider.of<RestaurantsInfoProvider>(context, listen: false);
    final token = await _storage.read(key: 'auth_token') ?? '';
    await provider.fetchAllData(token: token);
    // جلب أفضل المعلنين للمطاعم
    await provider.fetchTopRestaurants(token: token, category: 'restaurant');
  }

  List<String> get categories => [
        S.of(context).carsales,
        S.of(context).realestate,
        S.of(context).electronics,
        S.of(context).jobs,
        S.of(context).carrent,
        S.of(context).carservices,
        S.of(context).restaurants,
        S.of(context).otherservices,
      ];

  Map<String, String> get categoryRoutes => {
        S.of(context).carsales: "/home",
        S.of(context).realestate: "/realEstate",
        S.of(context).electronics: "/electronics",
        S.of(context).jobs: "/jobs",
        S.of(context).carrent: "/car_rent",
        S.of(context).carservices: "/carServices",
        S.of(context).restaurants: "/restaurants",
        S.of(context).otherservices: "/otherServices",
      };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: CustomBottomNav(currentIndex: 0),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: s.smart_search,
                              hintStyle: TextStyle(
                                  color: const Color.fromRGBO(129, 126, 126, 1),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500),
                              prefixIcon: Icon(
                                Icons.search,
                                color: borderColor,
                                size: 25.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                  color: borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 0.h,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: borderColor,
                          size: 35.sp,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                  child: CustomCategoryGrid(
                    categories: categories,
                    selectedIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    onCategoryPressed: (selectedCategory) {
                      final route = categoryRoutes[selectedCategory];
                      if (route != null) {
                        context.push(route);
                      } else {
                        print('Route not found for $selectedCategory');
                      }
                    },
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(
                            s.discover_restaurants_offers,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: KTextColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      
                      Consumer<RestaurantsInfoProvider>(
                        builder: (context, provider, child) {
                          return Column(
                            children: [
                              UnifiedDropdown<String>(
                                title: s.emirate,
                                selectedValue: _selectedEmirate,
                                items: ['All', ...provider.emirateDisplayNames, 'Other'],
                                onConfirm: (selection) => setState(() {
                                  _selectedEmirate = selection;
                                  _selectedDistrict = null; // إعادة تعيين المنطقة عند تغيير الإمارة
                                }),
                                isLoading: provider.isLoading,
                              ),
                              
                              SizedBox(height: 3.h),
                              
                              UnifiedDropdown<String>(
                                title: s.district_choose,
                                selectedValue: _selectedDistrict,
                                items: _selectedEmirate == null || _selectedEmirate == 'Other'
                                  ? ['All', 'Other']
                                  : _selectedEmirate == 'All'
                                    ? ['All', ...provider.emirateDisplayNames
                                        .expand((emirate) => provider.getDistrictsForEmirate(emirate))
                                        .toSet()
                                        .toList(), 'Other']
                                    : ['All', ...provider.getDistrictsForEmirate(_selectedEmirate), 'Other'],
                                onConfirm: (selection) => setState(() => _selectedDistrict = selection),
                                isLoading: provider.isLoading,
                              ),
                              
                              SizedBox(height: 3.h),
                              
                              UnifiedDropdown<String>(
                                title: s.category_type,
                                selectedValue: _selectedCategory,
                                items: ['All', ...provider.categoryDisplayNames, 'Other'],
                                onConfirm: (selection) => setState(() => _selectedCategory = selection),
                                isLoading: provider.isLoading,
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 4.h),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 0.w),
                        child: UnifiedSearchButton(
                          text: s.search,
                          onPressed: () {
                            // التحقق من صحة البيانات قبل البحث - السماح بـ All لعرض جميع البيانات
                            if (_selectedEmirate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please Select Emirate."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (_selectedDistrict == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please Select District."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (_selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please Select Category."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // تمرير الفلاتر إلى صفحة البحث
                            final filters = {
                              'emirate': _selectedEmirate,
                              'district': _selectedDistrict,
                              'category': _selectedCategory,
                            };
                            context.push('/restaurant_search', extra: filters);
                            
                            // مسح الاختيارات بعد البحث
                            setState(() {
                              _selectedEmirate = null;
                              _selectedDistrict = null;
                              _selectedCategory = null;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                        child: GestureDetector(
                          onTap: () => context.push('/restaurant_offerbox'),
                          child: Container(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
                            height: 68.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.click_daily_offers,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: KTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Icon(Icons.arrow_forward_ios,
                                    size: 22.sp, color: KTextColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Consumer<RestaurantsInfoProvider>(
                        builder: (context, provider, child) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 4.w),
                                  Icon(Icons.star, color: Colors.amber, size: 20.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    s.top_premium_dealers,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: KTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              if (provider.isLoading || provider.isLoadingTopRestaurants)
                                Container(
                                  height: 200.h,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: KPrimaryColor,
                                    ),
                                  ),
                                )
                              else if (provider.topRestaurants.isEmpty)
                                Container(
                                  height: 200.h,
                                  child: Center(
                                    child: Text(
                                      s.no_restaurants_found,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: provider.topRestaurants.map((advertiser) {
                                    print('=== Processing advertiser: ${advertiser.name} ===');
                                    print('Total ads for ${advertiser.name}: ${advertiser.ads.length}');
                                    
                                    // فلترة الإعلانات للحصول على إعلانات المطاعم فقط
                                    final restaurantAds = advertiser.ads.where((ad) {
                                      final category = ad.category?.toLowerCase();
                                      print('Ad: ${ad.title}, Category: $category');
                                      final isRestaurant = category == 'restaurant' || category == 'restaurants';
                                      print('Is restaurant ad: $isRestaurant');
                                      return isRestaurant;
                                    }).toList();

                                    print('Restaurant ads found for ${advertiser.name}: ${restaurantAds.length}');
                                    
                                    if (restaurantAds.isEmpty) {
                                      print('No restaurant ads found for ${advertiser.name}, hiding advertiser');
                                      return SizedBox.shrink();
                                    }
                                    
                                    print('Showing ${restaurantAds.length} restaurant ads for ${advertiser.name}');
                                    
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 8.h,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                 advertiser.name,
                                                 style: TextStyle(
                                                   fontSize: 14.sp,
                                                   fontWeight: FontWeight.w600,
                                                   color: KTextColor,
                                                 ),
                                               ),
                                              const Spacer(),
                                              InkWell(
                                                onTap: () {
                                                  // استخدام advertiserId بدلاً من user_id للحصول على معرف المعلن الصحيح
                                                  final advertiserId = advertiser.id.toString();
                            debugPrint('Navigating to all ads with advertiser ID: $advertiserId');
                            // التحقق من أن معرف المعلن ليس صفر
                            if (advertiserId == '0') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('لا يمكن عرض إعلانات هذا المعلن حالياً'))
                              );
                              return;
                            }
                            context.push('/all_ad_car_sales/$advertiserId');
                                                },
                                                child: Text(
                                                  s.see_all_ads,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    decoration: TextDecoration.underline,
                                                    decorationColor: borderColor,
                                                    color: borderColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 175,
                                          width: double.infinity,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: min(restaurantAds.length, 8),
                                            padding:
                                                EdgeInsets.symmetric(horizontal: 5.w),
                                            itemBuilder: (context, index) {
                                              final ad = restaurantAds[index];
                                              return GestureDetector(
                                                onTap: () {
                                                  context.push('/restaurant_details', extra: {'id': ad.id});
                                                },
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional.only(
                                                    end: index == restaurantAds.length - 1 ? 0 : 4.w,
                                                  ),
                                                  child: Container(
                                                    width: 145,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(4.r),
                                                      border: Border.all(
                                                          color: Colors.grey.shade300),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey.withOpacity(0.15),
                                                          blurRadius: 5.r,
                                                          offset: Offset(0, 2.h),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Stack(
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(4.r),
                                                              child: ad.images.isNotEmpty
                                                                ? CachedNetworkImage(
                                                                    imageUrl: ImageUrlHelper.getFullImageUrl(ad.images.first),
                                                                    height: 94.h,
                                                                    width: double.infinity,
                                                                    fit: BoxFit.cover,
                                                                    placeholder: (context, url) => Container(
                                                                      height: 94.h,
                                                                      width: double.infinity,
                                                                      color: Colors.grey.shade200,
                                                                      child: Center(
                                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                                      ),
                                                                    ),
                                                                    errorWidget: (context, url, error) {
                                                                      // في حال فشل تحميل الصورة، لا نعرض أيقونة وهمية
                                                                      return Container(
                                                                        height: 94.h,
                                                                        width: double.infinity,
                                                                        color: Colors.grey.shade200,
                                                                      );
                                                                    },
                                                                  )
                                                                : Container(
                                                                    // عند عدم توفر صور، اعرض خلفية محايدة بدون أيقونة وهمية
                                                                    height: 94.h,
                                                                    width: double.infinity,
                                                                    color: Colors.grey.shade200,
                                                                  ),
                                                            ),
                                                            Positioned(
                                                              top: 8,
                                                              right: 8,
                                                              child: buildFavoriteIcon(
                                                                BestAdvertiserRestaurantItemAdapter(ad),
                                                                onAddToFavorite: () {},
                                                                onRemoveFromFavorite: null,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding: EdgeInsets.symmetric(
                                                                horizontal: 6.w),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment.start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                Text(
                                                                  '${ad.priceRange ?? '0'} AED',
                                                                  style: TextStyle(
                                                                    color: Colors.red,
                                                                    fontWeight:
                                                                        FontWeight.w600,
                                                                    fontSize: 11.5.sp,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  ad.title ?? 'مطعم مميز',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight.w600,
                                                                    fontSize: 11.5.sp,
                                                                    color: KTextColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '${ad.emirate ?? ''}, ${ad.district ?? ''}',
                                                                  style: TextStyle(
                                                                    fontSize: 11.5.sp,
                                                                    color:
                                                                        const Color.fromRGBO(
                                                                            165, 164, 162, 1),
                                                                    fontWeight:
                                                                        FontWeight.w600,
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
                                              );
                                            }
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}