import 'dart:ui';
import 'package:advertising_app/data/model/car_rent_ad_model.dart';
import 'package:advertising_app/presentation/screen/car_services_ad_screen.dart';
import 'package:advertising_app/presentation/screen/login2_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:advertising_app/data/model/car_rent_model.dart';
import 'package:advertising_app/data/model/car_sale_model.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/data/model/electronic_model.dart';
import 'package:advertising_app/data/model/job_model.dart';
import 'package:advertising_app/data/model/other_service_model.dart';
import 'package:advertising_app/data/model/real_estate_model.dart';
import 'package:advertising_app/data/model/restaurant_model.dart';
import 'package:advertising_app/presentation/screen/all_add_car_rent.dart';
import 'package:advertising_app/presentation/screen/all_add_screen.dart';
import 'package:advertising_app/presentation/screen/all_add_car_service.dart';
import 'package:advertising_app/presentation/screen/all_add_electronic.dart';
import 'package:advertising_app/presentation/screen/all_add_job.dart';
import 'package:advertising_app/presentation/screen/all_add_other_service.dart';
import 'package:advertising_app/presentation/screen/all_add_real_estate.dart';
import 'package:advertising_app/presentation/screen/all_add_resturant.dart';
import 'package:advertising_app/presentation/screen/car_rent_ads_screen.dart';
import 'package:advertising_app/presentation/screen/car_rent_save_ads_screen.dart';
import 'package:advertising_app/presentation/screen/car_sales_save_ads_screen.dart';
import 'package:advertising_app/presentation/screen/car_servise_save_ads.dart';
import 'package:advertising_app/presentation/screen/electronics_ad_screen.dart';
import 'package:advertising_app/presentation/screen/electronics_save_ad_screen.dart';
import 'package:advertising_app/presentation/screen/job_save_ads_screen.dart';
import 'package:advertising_app/presentation/screen/jod_ads_screen.dart';
import 'package:advertising_app/presentation/screen/other_service_ads_screen.dart';
import 'package:advertising_app/presentation/screen/other_service_save_ads_screen.dart';
import 'package:advertising_app/presentation/screen/payment_screen.dart';
import 'package:advertising_app/presentation/screen/place_an_ad.dart';
import 'package:advertising_app/presentation/screen/plan_selection_screen.dart';
import 'package:advertising_app/presentation/screen/real_estate_ads_screen.dart';
import 'package:advertising_app/presentation/screen/real_estate_save_ads_screen.dart';
import 'package:advertising_app/presentation/screen/resturant_ads_screen.dart';
import 'package:advertising_app/presentation/screen/resturant_save_ads_screen.dart';
import 'package:advertising_app/router/local_notifier.dart';
import 'package:advertising_app/presentation/screen/ads_category.dart';
import 'package:advertising_app/presentation/screen/car_details_screen.dart';
import 'package:advertising_app/presentation/screen/car_rent_details_screen.dart';
import 'package:advertising_app/presentation/screen/car_rent_offer_box.dart';
import 'package:advertising_app/presentation/screen/car_rent_screen.dart';
import 'package:advertising_app/presentation/screen/car_rent_search_screen.dart';
import 'package:advertising_app/presentation/screen/car_sales_ads_screen.dart';
import 'package:advertising_app/presentation/screen/car_sales_search_screen.dart';
import 'package:advertising_app/presentation/screen/car_service.dart';
import 'package:advertising_app/presentation/screen/car_service_details.dart';
import 'package:advertising_app/presentation/screen/car_service_offer_box.dart';
import 'package:advertising_app/presentation/screen/car_service_search_screen.dart';
import 'package:advertising_app/presentation/screen/edit_profile.dart';
import 'package:advertising_app/presentation/screen/location_picker_screen.dart';
import 'package:advertising_app/presentation/screen/electronic_details_screen.dart';
import 'package:advertising_app/presentation/screen/electronic_offer_box.dart';
import 'package:advertising_app/presentation/screen/electronic_screen.dart';
import 'package:advertising_app/presentation/screen/electronic_search_screen.dart';
import 'package:advertising_app/presentation/screen/email_code.dart';
import 'package:advertising_app/presentation/screen/email_login_screen.dart';
import 'package:advertising_app/presentation/screen/email_signup.dart';
import 'package:advertising_app/presentation/screen/favorite_screen.dart';
import 'package:advertising_app/presentation/screen/forgot_pass_email.dart';
import 'package:advertising_app/presentation/screen/forgot_pass_phone.dart';
import 'package:advertising_app/presentation/screen/car_sales_screen.dart';
import 'package:advertising_app/presentation/screen/job_details_screen.dart';
import 'package:advertising_app/presentation/screen/job_offer_box.dart';
import 'package:advertising_app/presentation/screen/job_screen.dart';
import 'package:advertising_app/presentation/screen/job_search_screen.dart';
import 'package:advertising_app/presentation/screen/login_screen.dart';
import 'package:advertising_app/presentation/screen/manage_screen.dart';
import 'package:advertising_app/presentation/screen/other_service_search_screen.dart';
import 'package:advertising_app/presentation/screen/other_services_details_screen.dart';
import 'package:advertising_app/presentation/screen/real_estate_details_screen.dart';
import 'package:advertising_app/presentation/screen/real_estate_offer_box.dart';
import 'package:advertising_app/presentation/screen/car_sales_offers_box_screen.dart';
import 'package:advertising_app/presentation/screen/other_service.dart';
import 'package:advertising_app/presentation/screen/other_service_offer_box.dart';
import 'package:advertising_app/presentation/screen/phone_code.dart';
import 'package:advertising_app/presentation/screen/post_ad_screen.dart';
import 'package:advertising_app/presentation/screen/profile_screen.dart';
import 'package:advertising_app/presentation/screen/real_estate_screen.dart';
import 'package:advertising_app/presentation/screen/real_estate_search_screen.dart';
import 'package:advertising_app/presentation/screen/reset_pass.dart';
import 'package:advertising_app/presentation/screen/restaurant_details_screen.dart';
import 'package:advertising_app/presentation/screen/restaurant_offer_box.dart';
import 'package:advertising_app/presentation/screen/restaurant_search_screen.dart';
import 'package:advertising_app/presentation/screen/restaurants_screen.dart';
import 'package:advertising_app/presentation/screen/setting_screen.dart';
import 'package:advertising_app/presentation/screen/sinup_screen.dart';
import 'package:advertising_app/presentation/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/presentation/screen/location_picker_screen.dart';

// دالة للتحقق من الصفحات العامة التي لا تحتاج تسجيل دخول
bool _isPublicRoute(String location) {
  final publicRoutes = [
    '/', // شاشة Splash
    '/login',
    '/signup',
    '/emaillogin',
    '/emailsignup',
    '/passphonelogin',
    '/forgetpassemail',
    '/phonecode',
    '/emailcode',
    '/resetpass',
  ];
  return publicRoutes.contains(location);
}

GoRouter createRouter({
  required LocaleChangeNotifier notifier,
}) {
  // دالة مساعدة لتغيير اللغة بالطريقة الجديدة
  void changeLocale(BuildContext context, Locale locale) {
    Provider.of<LocaleChangeNotifier>(context, listen: false).changeLocale(locale);
  }

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/', // المسار الأولي يبدأ من Splash
    redirect: (context, state) async {
      // التحقق من الجلسة المخزنة
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final hasValidSession = await authProvider.checkStoredSession();
      
      // إذا كان المستخدم في صفحة تسجيل الدخول وله جلسة صالحة، وجهه للصفحة الرئيسية
      if (hasValidSession && (state.matchedLocation == '/login' || state.matchedLocation == '/' || state.matchedLocation == '/emaillogin' || state.matchedLocation == '/signup' || state.matchedLocation == '/emailsignup')) {
        return '/home';
      }
      
      // إذا لم تكن له جلسة صالحة وهو في صفحة محمية، وجهه لتسجيل الدخول
      if (!hasValidSession && !_isPublicRoute(state.matchedLocation)) {
        return '/login';
      }
      
      return null; // لا تغيير في المسار
    },
    routes: [
      // شاشة Splash
      GoRoute(path: '/', builder: (context, state) => SplashGridScreen()),
        GoRoute(path: '/login', builder: (context, state) => Login2(notifier: notifier,)),
     
      // +++ الشاشات القديمة التي تتوقع 'notifier' مباشرة +++
      // GoRoute(path: '/login', builder: (context, state) => LoginScreen(notifier: notifier, onLanguageChange: (locale) {  },)),
      // GoRoute(path: '/signup', builder: (context, state) => SignUpScreen(notifier: notifier, onLanguageChange: (locale) {  },)),
      // GoRoute(path: '/emaillogin', builder: (context, state) => EmailLoginScreen(notifier: notifier)),
      // GoRoute(path: '/emailsignup', builder: (context, state) => EmailSignUpScreen(notifier: notifier)),
      // GoRoute(path: '/passphonelogin', builder: (context, state) => ForgotPassPhone(notifier: notifier)),
      GoRoute(path: '/forgetpassemail', builder: (context, state) => ForgotPassEmail(notifier: notifier)),
      //GoRoute(path: '/phonecode', builder: (context, state) => VerifyPhoneCode(notifier: notifier)),
      GoRoute(path: '/emailcode', builder: (context, state) => VerifyEmailCode(notifier: notifier)),
      GoRoute(path: '/resetpass', builder: (context, state) => ResetPassword(notifier: notifier)),
      GoRoute(path: '/setting', builder: (context, state) => SettingScreen(notifier: notifier)),

      // +++ الشاشات التي لا تحتاج إلى تغيير اللغة +++
      GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/favorite', builder: (context, state) => FavoriteScreen()),
      GoRoute(path: '/postad', builder: (context, state) => PostAdScreen()),
     GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
      GoRoute(path: '/editprofile', builder: (context, state) => EditProfile()),
       GoRoute(
        // استخدمنا هنا المسار الرئيسي الصحيح
        path: '/cars-sales',
        builder: (context, state) {
          // نقرأ الفلاتر القادمة من HomeScreen كـ 'extra'
          final filters = state.extra as Map<String, String>?;
          
          // نمرر هذه الفلاتر إلى CarSalesScreen
          return CarSalesScreen(initialFilters: filters);
        },
      ), 
       GoRoute(
        // المسار الآن يقبل ID متغيرًا
        path: '/car-details/:adId',
        builder: (context, state) {
          // نقرأ الـ ID من المسار
          final adId = int.tryParse(state.pathParameters['adId'] ?? '') ?? 0;
          
          // نمرر الـ ID فقط إلى الشاشة
          return CarDetailsScreen(adId: adId);
        },
      ),
      
      
      
      // ... (بقية المسارات التي لا تحتاج تغيير اللغة)
       GoRoute(
         path: '/real-details/:id',
         builder: (context, state) {
           final adId = state.pathParameters['id']!;
           return RealEstateDetailsScreen(adId: adId);
         },
       ),
      GoRoute(
  path: '/electronic-details/:adId',
  builder: (context, state) {
    final adId = int.parse(state.pathParameters['adId']!);
    return ElectronicDetailsScreen(adId: adId);
  },
),GoRoute(
  path: '/job-details/:adId',
  builder: (context, state) {
    final adId = int.parse(state.pathParameters['adId']!);
    return JobDetailsScreen(adId: adId);
  },
),    GoRoute(path: '/car-rent-details', builder: (context, state) => CarRentDetailsScreen (car_rent: state.extra as CarRentAdModel )),
       GoRoute(path: '/car-service-details', builder: (context, state) => CarServiceDetails (car_service: state.extra as CarServiceModel )),
       GoRoute(
         path: '/restaurant_details',
         builder: (context, state) {
           final data = state.extra as Map<String, dynamic>;
           final adId = data['id'] is String 
               ? int.tryParse(data['id']) ?? 0 
               : data['id'] as int;
           return RestaurantDetailsScreen(adId: adId);
         }
       ),
      GoRoute(
  path: '/other_service-details/:adId', // المسار الصحيح
  builder: (context, state) {
    final adId = int.parse(state.pathParameters['adId']!);
    return OtherServicesDetailsScreen(adId: adId);
  },
),
 GoRoute(path: '/offer_box', builder: (context, state) => OffersBoxScreen()),
       GoRoute(path: '/car_rent', builder: (context, state) => CarRentScreen()),
       GoRoute(path: '/realEstate', builder: (context, state) => RealEstateScreen()),
       GoRoute(path: '/electronics', builder: (context, state) => ElectronicScreen()),
       GoRoute(path: '/jobs', builder: (context, state) => JobScreen()),
       GoRoute(path: '/carServices', builder: (context, state) => CarService()),
       GoRoute(path: '/restaurants', builder: (context, state) => RestaurantsScreen()),
       GoRoute(path: '/otherServices', builder: (context, state) => OtherServiceScreen()),
       GoRoute(path: '/realestateofeerbox', builder: (context, state) => RealEstateOfferBOX()),
       GoRoute(path: '/electronicofferbox', builder: (context, state) => ElectronicOfferBox()),
       GoRoute(path: '/jobofferbox', builder: (context, state) => JobOfferBox()),
       GoRoute(path: '/carrentofferbox', builder: (context, state) => CarRentOfferBox()),
       GoRoute(path: '/carservicetofferbox', builder: (context, state) => CarServiceOfferBox()),
       GoRoute(path: '/restaurant_offerbox', builder: (context, state) => RestaurantOfferBox()),
       GoRoute(path: '/other_service_offer_box', builder: (context, state) => OtherServiceOfferBox()),
       GoRoute(path: '/real_estate_search', builder: (context, state) {
         final filters = state.extra as Map<String, String>?;
         return RealEstateSearchScreen(filters: filters);
       }),
       GoRoute(
         path: '/electronic_search',
         builder: (context, state) {
           final filters = state.extra as Map<String, String>?;
           return ElectronicSearchScreen(initialFilters: filters);
         },
       ),
       GoRoute(path: '/car_rent_search', builder: (context, state) {
         final filters = state.extra as Map<String, dynamic>?;
         return CarRentSearchScreen(filters: filters);
       }),
       GoRoute(path: '/car_service_search', builder: (context, state) {
         final filters = state.extra as Map<String, String>?;
         return CarServiceSearchScreen(initialFilters: filters);
       }),
       GoRoute(path: '/restaurant_search', builder: (context, state) {
         final filters = state.extra as Map<String, dynamic>?;
         return RestaurantSearchScreen(filters: filters);
       }),
       GoRoute(path: '/other_service_search', builder: (context, state) => OtherServiceSearchScreen()),
       GoRoute(path: '/job_search', builder: (context, state) => JobSearchScreen()),
       GoRoute(path: '/real_estate_details_screen', builder: (context, state) {
         final ad = state.extra;
         // Extract adId from the ad object
         String adId = '';
         if (ad is Map<String, dynamic>) {
           adId = ad['id']?.toString() ?? '';
         } else if (ad != null) {
           // If ad has an id property, extract it
           try {
             adId = (ad as dynamic).id?.toString() ?? '';
           } catch (e) {
             adId = '';
           }
         }
         return RealEstateDetailsScreen(adId: adId);
       }),
       GoRoute(path: '/ads_category', builder: (context, state) => AdsCategoryScreen()),
       GoRoute(path: '/placeAnAd', builder: (context, state) {
         final adData = state.extra as Map<String, dynamic>?;
         return PlaceAnAd(adData: adData);
       }),
       GoRoute(path: '/planSelection', builder: (context, state) {
         final adData = state.extra as Map<String, dynamic>;
         return PlanSelectionScreen(adData: adData);
       }),
       GoRoute(
         path: '/all_ad_car_sales/:advertiserId',
         builder: (context, state) {
           final advertiserId = state.pathParameters['advertiserId'];
           debugPrint('Router passing advertiser ID: $advertiserId');
           return AllAddScreen(advertiserId: advertiserId);
         },
       ),
       // للتوافق مع الاستدعاءات القديمة
       GoRoute(path: '/all_ad_car_sales', builder: (context, state) => AllAddScreen()),
       GoRoute(path: '/all_ad_car_rent', builder: (context, state) =>  AllAdCarRent()),
       GoRoute(path: '/AllAdsRealEstate', builder: (context, state) =>  AllAdsRealEstate()),
       GoRoute(path: '/AllAddsElectronic', builder: (context, state) =>   AllAddsElectronic()),
       GoRoute(path: '/all_add_job', builder: (context, state) =>   AllAddsJob()),
       GoRoute(path: '/AllAddsCarService', builder: (context, state) =>   AllAddsCarService()),
       GoRoute(path: '/AllAddsRestaurant', builder: (context, state) =>   AllAddsRestaurant()),
       GoRoute(path: '/all_add_other_service', builder: (context, state) =>   AllAddsOtherService()),


      // +++ الشاشات الجديدة التي تستخدم 'onLanguageChange' بالطريقة الصحيحة +++
      GoRoute(
        path: '/manage',
        builder: (context, state) => ManageScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
      GoRoute(
        path: '/car_sales_ads',
        builder: (context, state) {
          final location = state.uri.queryParameters['location'];
          final latStr = state.uri.queryParameters['lat'];
          final lngStr = state.uri.queryParameters['lng'];
          
          double? latitude;
          double? longitude;
          
          if (latStr != null && lngStr != null) {
            latitude = double.tryParse(latStr);
            longitude = double.tryParse(lngStr);
          }
          
          return CarSalesAdScreen(
            onLanguageChange: (locale) => changeLocale(context, locale),
            initialLocation: location,
            initialLatitude: latitude,
            initialLongitude: longitude,
          );
        },
      ),
      GoRoute(
        path: '/car_sales_save_ads/:adId',
        builder: (context, state) {
          final adId = int.tryParse(state.pathParameters['adId'] ?? '') ?? 0;
          return CarSalesSaveAdScreen(
            adId: adId,
            onLanguageChange: (locale) => changeLocale(context, locale),
          );
        },
      ),
      GoRoute(
        path: '/location_picker',
        builder: (context, state) {
          final latStr = state.uri.queryParameters['lat'];
          final lngStr = state.uri.queryParameters['lng'];
          final address = state.uri.queryParameters['address'];
          
          LatLng? initialLocation;
          if (latStr != null && lngStr != null) {
            final lat = double.tryParse(latStr);
            final lng = double.tryParse(lngStr);
            if (lat != null && lng != null) {
              initialLocation = LatLng(lat, lng);
            }
          }
          
          return LocationPickerScreen(
            initialLocation: initialLocation,
            initialAddress: address,
          );
        },
      ),
      GoRoute(
        path: '/car_services_ads',
        builder: (context, state) => CarServicesAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
      GoRoute(
        path: '/car_services_save_ads',
        builder: (context, state) => CarServicesSaveAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
      GoRoute(
        path: '/car_services_save_ads/:adId',
        builder: (context, state) {
          final adId = int.tryParse(state.pathParameters['adId'] ?? '') ?? 0;
          return CarServicesSaveAdScreen(
            onLanguageChange: (locale) => changeLocale(context, locale),
            adId: adId,
          );
        },
      ),
      GoRoute(
        path: '/real_estate_ads',
        builder: (context, state) => RealEstateAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
       GoRoute(
        path: '/real_estate_save_ads/:adId',
        builder: (context, state) {
          final adId = state.pathParameters['adId'] ?? '0';
          return RealEstateSaveAdScreen(
            onLanguageChange: (locale) => changeLocale(context, locale),
            adId: adId,
          );
        },
      ),
       GoRoute(
        path: '/electronics_ads',
        builder: (context, state) => ElectronicsAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
       GoRoute(
        path: '/electronics_save_ads/:adId',
        builder: (context, state) {
          final adId = int.parse(state.pathParameters['adId']!);
          return ElectronicsSaveAdScreen(
            onLanguageChange: (locale) => changeLocale(context, locale),
            adId: adId,
          );
        },
      ),
      GoRoute(
        path: '/car_rent_ads',
        builder: (context, state) => CarsRentAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
       GoRoute(
        path: '/car_rent_save_ads',
        builder: (context, state) => CarsRentSaveAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
      GoRoute(
        path: '/car_rent_save_ads/:adId',
        builder: (context, state) {
          final adId = state.pathParameters['adId'];
          return CarsRentSaveAdScreen(
            adId: adId,
            onLanguageChange: (locale) => changeLocale(context, locale),
          );
        },
      ),
       GoRoute(
        path: '/resturant_ads',
        builder: (context, state) => RestaurantsAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
       GoRoute(
        path: '/resturant_save_ads/:adId',
        builder: (context, state) => RestaurantsSaveAdScreen(adId: state.pathParameters['adId'] ?? '0'),
      ),
       GoRoute(
       path: '/other_servics_ads',
        builder: (context, state) => OtherServicesAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
       GoRoute(
        path: '/other_service_save_ads',
        builder: (context, state) => OtherServicesSaveAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
      GoRoute(
        path: '/other_service_save_ads/:adId',
        builder: (context, state) {
          final adIdParam = state.pathParameters['adId'];
          final int? adId = int.tryParse(adIdParam ?? '');
          return OtherServicesSaveAdScreen(
            adId: adId,
            onLanguageChange: (locale) => changeLocale(context, locale),
          );
        },
      ),
      GoRoute(
        path: '/job_ads',
        builder: (context, state) => JobsAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
      GoRoute(
        path: '/job_save_ads',
        builder: (context, state) => JobsSaveAdScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
      GoRoute(
        path: '/job_save_ads/:adId',
        builder: (context, state) {
          final adId = int.tryParse(state.pathParameters['adId'] ?? '');
          return JobsSaveAdScreen(
            adId: adId,
            onLanguageChange: (locale) => changeLocale(context, locale),
          );
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => PaymentScreen(onLanguageChange: (locale) => changeLocale(context, locale)),
      ),
    ],
  );
}