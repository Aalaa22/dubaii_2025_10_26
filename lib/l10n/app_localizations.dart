import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'508236561'**
  String get phoneNumberHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I Agree Terms & Conditions'**
  String get agreeTerms;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @guestLogin.
  ///
  /// In en, this message translates to:
  /// **'Guest Login'**
  String get guestLogin;

  /// No description provided for @emailSignUp.
  ///
  /// In en, this message translates to:
  /// **'Email Sign Up'**
  String get emailSignUp;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already Have An Account?'**
  String get haveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @emailLogin.
  ///
  /// In en, this message translates to:
  /// **'Email Login'**
  String get emailLogin;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Have An Account?'**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @phonesignup.
  ///
  /// In en, this message translates to:
  /// **'phone sign Up'**
  String get phonesignup;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'عربي'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get arabic;

  /// No description provided for @phoneLogin.
  ///
  /// In en, this message translates to:
  /// **'Phone Login'**
  String get phoneLogin;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @createAgentCode.
  ///
  /// In en, this message translates to:
  /// **'Create Agent Code'**
  String get createAgentCode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get supportCenter;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @advertiserName.
  ///
  /// In en, this message translates to:
  /// **'Advertiser Name'**
  String get advertiserName;

  /// No description provided for @advertiserType.
  ///
  /// In en, this message translates to:
  /// **'Advertiser Type'**
  String get advertiserType;

  /// No description provided for @advertiserLogo.
  ///
  /// In en, this message translates to:
  /// **'Advertiser Logo'**
  String get advertiserLogo;

  /// No description provided for @uploadYourLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Logo'**
  String get uploadYourLogo;

  /// No description provided for @advertiserLocation.
  ///
  /// In en, this message translates to:
  /// **'Advertiser Location'**
  String get advertiserLocation;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @locateMe.
  ///
  /// In en, this message translates to:
  /// **'Locate Me'**
  String get locateMe;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @please_select_emirate.
  ///
  /// In en, this message translates to:
  /// **'Please select emirate'**
  String get please_select_emirate;

  /// No description provided for @please_select_district.
  ///
  /// In en, this message translates to:
  /// **'Please select district'**
  String get please_select_district;

  /// No description provided for @please_select_category.
  ///
  /// In en, this message translates to:
  /// **'Please select category'**
  String get please_select_category;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Al Manara Motors'**
  String get placeName;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String date(Object date);

  /// No description provided for @priceOnly.
  ///
  /// In en, this message translates to:
  /// **'{price}'**
  String priceOnly(Object price);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @forgetyourpass.
  ///
  /// In en, this message translates to:
  /// **'Forgot Your Password?'**
  String get forgetyourpass;

  /// No description provided for @enterphone.
  ///
  /// In en, this message translates to:
  /// **'Enter Your phone'**
  String get enterphone;

  /// No description provided for @sendcode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendcode;

  /// No description provided for @enteremail.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Email'**
  String get enteremail;

  /// No description provided for @verifnum.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Number'**
  String get verifnum;

  /// No description provided for @phoneverify.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent an whatsApp with an activation code to your phone'**
  String get phoneverify;

  /// No description provided for @emilverify.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent an Email with an activation code to your Email yourname@example.Com '**
  String get emilverify;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resetpass.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetpass;

  /// No description provided for @newpass.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newpass;

  /// No description provided for @confirmpass.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmpass;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @incompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Incomplete profile'**
  String get incompleteProfile;

  /// No description provided for @profileWarning.
  ///
  /// In en, this message translates to:
  /// **'You must complete the following fields in your profile before adding the advertisement:'**
  String get profileWarning;

  /// No description provided for @carsales.
  ///
  /// In en, this message translates to:
  /// **'Car Sales'**
  String get carsales;

  /// No description provided for @realestate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get realestate;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics & Home \n Appliances'**
  String get electronics;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @carrent.
  ///
  /// In en, this message translates to:
  /// **'Car Rent'**
  String get carrent;

  /// No description provided for @carservices.
  ///
  /// In en, this message translates to:
  /// **'Car Services'**
  String get carservices;

  /// No description provided for @restaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get restaurants;

  /// No description provided for @otherservices.
  ///
  /// In en, this message translates to:
  /// **'Other Services'**
  String get otherservices;

  /// No description provided for @enjoyFreeAds.
  ///
  /// In en, this message translates to:
  /// **'Enjoy Free Ads'**
  String get enjoyFreeAds;

  /// No description provided for @enterpassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Password'**
  String get enterpassword;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordRequiredToCompleteLogin.
  ///
  /// In en, this message translates to:
  /// **'Please enter password to complete login'**
  String get passwordRequiredToCompleteLogin;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during login'**
  String get loginError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(Object error);

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @byContinueIAgreeTo.
  ///
  /// In en, this message translates to:
  /// **'By continuing I agree to the'**
  String get byContinueIAgreeTo;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @passwordResetComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Password reset will be available soon'**
  String get passwordResetComingSoon;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @srtting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get srtting;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Posting'**
  String get post;

  /// No description provided for @editprof4.
  ///
  /// In en, this message translates to:
  /// **'Edit my Profile'**
  String get editprof4;

  /// No description provided for @editing1.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editing1;

  /// No description provided for @editit2.
  ///
  /// In en, this message translates to:
  /// **'Do you want to edit your profile'**
  String get editit2;

  /// No description provided for @edit3.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit3;

  /// No description provided for @discover_best_cars_deals.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Cars Deals'**
  String get discover_best_cars_deals;

  /// No description provided for @choose_make.
  ///
  /// In en, this message translates to:
  /// **'Choose Make'**
  String get choose_make;

  /// No description provided for @choose_model.
  ///
  /// In en, this message translates to:
  /// **'Choose Model'**
  String get choose_model;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @click_for_amazing_daily_cars_deals.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing Daily Cars Deals'**
  String get click_for_amazing_daily_cars_deals;

  /// No description provided for @top_premium_dealers.
  ///
  /// In en, this message translates to:
  /// **'Top Premium Dealers'**
  String get top_premium_dealers;

  /// No description provided for @see_all_ads.
  ///
  /// In en, this message translates to:
  /// **'See All Ads'**
  String get see_all_ads;

  /// No description provided for @smart_search.
  ///
  /// In en, this message translates to:
  /// **'Smart Search'**
  String get smart_search;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'Km'**
  String get km;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @trim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get trim;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort By The Nearest'**
  String get sort;

  /// No description provided for @ad.
  ///
  /// In en, this message translates to:
  /// **'ADS NO:'**
  String get ad;

  /// No description provided for @car_details.
  ///
  /// In en, this message translates to:
  /// **'Car Details'**
  String get car_details;

  /// No description provided for @car_type.
  ///
  /// In en, this message translates to:
  /// **'Car Type'**
  String get car_type;

  /// No description provided for @trans_type.
  ///
  /// In en, this message translates to:
  /// **'Trans Type'**
  String get trans_type;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @interior_color.
  ///
  /// In en, this message translates to:
  /// **'Interior Color'**
  String get interior_color;

  /// No description provided for @fuel_type.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get fuel_type;

  /// No description provided for @warranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warranty;

  /// No description provided for @doors_no.
  ///
  /// In en, this message translates to:
  /// **'Doors No'**
  String get doors_no;

  /// No description provided for @seats_no.
  ///
  /// In en, this message translates to:
  /// **'Seats No'**
  String get seats_no;

  /// No description provided for @engine_capacity.
  ///
  /// In en, this message translates to:
  /// **'Engine Capacity'**
  String get engine_capacity;

  /// No description provided for @cylinders.
  ///
  /// In en, this message translates to:
  /// **'Cylinders'**
  String get cylinders;

  /// No description provided for @horse_power.
  ///
  /// In en, this message translates to:
  /// **'Horse Power'**
  String get horse_power;

  /// No description provided for @steering_side.
  ///
  /// In en, this message translates to:
  /// **'Steering Side'**
  String get steering_side;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// No description provided for @view_all_ads.
  ///
  /// In en, this message translates to:
  /// **'View All Ads'**
  String get view_all_ads;

  /// No description provided for @report_this_ad.
  ///
  /// In en, this message translates to:
  /// **'Report This Ad'**
  String get report_this_ad;

  /// No description provided for @use_this_space_for_ads.
  ///
  /// In en, this message translates to:
  /// **'Contact us To Use This Space For Your Ads'**
  String get use_this_space_for_ads;

  /// No description provided for @adNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ad not found.'**
  String get adNotFound;

  /// No description provided for @errorFetchingData.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while fetching data: {error}'**
  String errorFetchingData(Object error);

  /// No description provided for @newMainImageSelected.
  ///
  /// In en, this message translates to:
  /// **'New main image selected'**
  String get newMainImageSelected;

  /// No description provided for @currentMainImage.
  ///
  /// In en, this message translates to:
  /// **'Current main image'**
  String get currentMainImage;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @noAdIdForUpdate.
  ///
  /// In en, this message translates to:
  /// **'No ad ID to update'**
  String get noAdIdForUpdate;

  /// No description provided for @noChangesToSave.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get noChangesToSave;

  /// No description provided for @cannotAddMoreImages.
  ///
  /// In en, this message translates to:
  /// **'Cannot add more images. Maximum is {max} images'**
  String cannotAddMoreImages(Object max);

  /// No description provided for @limitedImagesSelected.
  ///
  /// In en, this message translates to:
  /// **'Only {count} images selected. Maximum {max} images total'**
  String limitedImagesSelected(Object count, Object max);

  /// No description provided for @rankAdInProgress.
  ///
  /// In en, this message translates to:
  /// **'Ranking the ad...'**
  String get rankAdInProgress;

  /// No description provided for @rankAdSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ad ranked successfully'**
  String get rankAdSuccess;

  /// No description provided for @rankAdFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rank the ad'**
  String get rankAdFailed;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User Id'**
  String get userId;

  /// No description provided for @priority_first_premium.
  ///
  /// In en, this message translates to:
  /// **'🌟 Top Premium Ads'**
  String get priority_first_premium;

  /// No description provided for @priority_premium.
  ///
  /// In en, this message translates to:
  /// **'💎 Premium Ads'**
  String get priority_premium;

  /// No description provided for @priority_featured.
  ///
  /// In en, this message translates to:
  /// **'🚀 Featured Ads'**
  String get priority_featured;

  /// No description provided for @priority_free.
  ///
  /// In en, this message translates to:
  /// **'📢 Free Ads'**
  String get priority_free;

  /// No description provided for @add_to_favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorite'**
  String get add_to_favorite;

  /// No description provided for @confirm_add_to_favorite.
  ///
  /// In en, this message translates to:
  /// **'Do you want to add this item to favorites?'**
  String get confirm_add_to_favorite;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @added_to_favorite.
  ///
  /// In en, this message translates to:
  /// **'Item added to favorites'**
  String get added_to_favorite;

  /// No description provided for @remove_from_favorite.
  ///
  /// In en, this message translates to:
  /// **'remove from favorite'**
  String get remove_from_favorite;

  /// No description provided for @confirm_remove_from_favorite.
  ///
  /// In en, this message translates to:
  /// **'confirm remove from favorite'**
  String get confirm_remove_from_favorite;

  /// No description provided for @invisibleInfo.
  ///
  /// In en, this message translates to:
  /// **'When enabled, others won’t know that you viewed their ad or interacted with it.'**
  String get invisibleInfo;

  /// No description provided for @invisibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Invisible Browsing'**
  String get invisibleTitle;

  /// No description provided for @invisibleInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Invisible?'**
  String get invisibleInfoTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @discover_deals.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Rental Deals'**
  String get discover_deals;

  /// No description provided for @click_for_deals.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing Daily Rental Deals'**
  String get click_for_deals;

  /// No description provided for @discover_real_estate.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Properties Deals'**
  String get discover_real_estate;

  /// No description provided for @emirate.
  ///
  /// In en, this message translates to:
  /// **'Emirate'**
  String get emirate;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @property_type.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get property_type;

  /// No description provided for @contract_type.
  ///
  /// In en, this message translates to:
  /// **'Contract Type'**
  String get contract_type;

  /// No description provided for @click_for_deals_real_estate.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing Properties Deals'**
  String get click_for_deals_real_estate;

  /// No description provided for @discover_elect.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Electronics & Appliances'**
  String get discover_elect;

  /// No description provided for @section_type.
  ///
  /// In en, this message translates to:
  /// **'Section Type'**
  String get section_type;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section '**
  String get section;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @electronics2.
  ///
  /// In en, this message translates to:
  /// **'Electronics &'**
  String get electronics2;

  /// No description provided for @electronics3.
  ///
  /// In en, this message translates to:
  /// **'Home  Appliances'**
  String get electronics3;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category '**
  String get category;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @click_for_deals_elect.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing Electronics & Home Appliances Deals'**
  String get click_for_deals_elect;

  /// No description provided for @category_type.
  ///
  /// In en, this message translates to:
  /// **'Category Type'**
  String get category_type;

  /// No description provided for @click_for_deals_job.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing Job Offers'**
  String get click_for_deals_job;

  /// No description provided for @discover_best_job.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Job Offers'**
  String get discover_best_job;

  /// No description provided for @service_type.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get service_type;

  /// No description provided for @click_for_deals_car_service.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing  Cars Services Deals'**
  String get click_for_deals_car_service;

  /// No description provided for @discover_car_service.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Cars Services Deals'**
  String get discover_car_service;

  /// No description provided for @district_choose.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district_choose;

  /// No description provided for @click_daily_offers.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing Daily Offers'**
  String get click_daily_offers;

  /// No description provided for @discover_restaurants_offers.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Restaurants Offers'**
  String get discover_restaurants_offers;

  /// No description provided for @click_daily_servir_offers.
  ///
  /// In en, this message translates to:
  /// **'Click For Amazing Services Offers'**
  String get click_daily_servir_offers;

  /// No description provided for @discover_service_offers.
  ///
  /// In en, this message translates to:
  /// **'Discover Best Services Offers'**
  String get discover_service_offers;

  /// No description provided for @place_an_ad.
  ///
  /// In en, this message translates to:
  /// **'Place An Ad'**
  String get place_an_ad;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @appearance_top.
  ///
  /// In en, this message translates to:
  /// **'Appearance On Top Of Search List'**
  String get appearance_top;

  /// No description provided for @appearance_nearest.
  ///
  /// In en, this message translates to:
  /// **'Appearance For The Nearest Viewers'**
  String get appearance_nearest;

  /// No description provided for @appearance_after_star.
  ///
  /// In en, this message translates to:
  /// **'Appearance After Premium'**
  String get appearance_after_star;

  /// No description provided for @appearance_after_premium.
  ///
  /// In en, this message translates to:
  /// **'Appearance After Premium Ads'**
  String get appearance_after_premium;

  /// No description provided for @appearance_after_featured.
  ///
  /// In en, this message translates to:
  /// **'Appearance After Featured Ads'**
  String get appearance_after_featured;

  /// No description provided for @daily_refresh.
  ///
  /// In en, this message translates to:
  /// **'Enabled Daily Refresh'**
  String get daily_refresh;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @for_days.
  ///
  /// In en, this message translates to:
  /// **'For [{days}] Days'**
  String for_days(Object days);

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @top_of_day_note.
  ///
  /// In en, this message translates to:
  /// **'Top Of The Day Comes First On The Search List'**
  String get top_of_day_note;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cars Sales Ads'**
  String get appTitle;

  /// No description provided for @toggleLang.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get toggleLang;

  /// No description provided for @make.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get make;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @specs.
  ///
  /// In en, this message translates to:
  /// **'Specs'**
  String get specs;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @carType.
  ///
  /// In en, this message translates to:
  /// **'Car Type'**
  String get carType;

  /// No description provided for @transType.
  ///
  /// In en, this message translates to:
  /// **'Trans Type'**
  String get transType;

  /// No description provided for @fuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get fuelType;

  /// No description provided for @interiorColor.
  ///
  /// In en, this message translates to:
  /// **'Interior Color'**
  String get interiorColor;

  /// No description provided for @engineCapacity.
  ///
  /// In en, this message translates to:
  /// **'Engine Capacity'**
  String get engineCapacity;

  /// No description provided for @horsePower.
  ///
  /// In en, this message translates to:
  /// **'Horse Power'**
  String get horsePower;

  /// No description provided for @doorsNo.
  ///
  /// In en, this message translates to:
  /// **'Doors No'**
  String get doorsNo;

  /// No description provided for @seatsNo.
  ///
  /// In en, this message translates to:
  /// **'Seats No'**
  String get seatsNo;

  /// No description provided for @steeringSide.
  ///
  /// In en, this message translates to:
  /// **'Steering Side'**
  String get steeringSide;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @describeYourCar.
  ///
  /// In en, this message translates to:
  /// **'Describe Your Car'**
  String get describeYourCar;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @addMainImage.
  ///
  /// In en, this message translates to:
  /// **'Add Main Image'**
  String get addMainImage;

  /// No description provided for @add19Images.
  ///
  /// In en, this message translates to:
  /// **'Add 19 Images'**
  String get add19Images;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @carsServicesAds.
  ///
  /// In en, this message translates to:
  /// **'Cars Services Ads'**
  String get carsServicesAds;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get serviceType;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @add3Images.
  ///
  /// In en, this message translates to:
  /// **'Add 3 Images'**
  String get add3Images;

  /// No description provided for @realEstateAds.
  ///
  /// In en, this message translates to:
  /// **'Real Estate Ads'**
  String get realEstateAds;

  /// No description provided for @contractType.
  ///
  /// In en, this message translates to:
  /// **'Contract Type'**
  String get contractType;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyType;

  /// No description provided for @add9Images.
  ///
  /// In en, this message translates to:
  /// **'Add 9 Images'**
  String get add9Images;

  /// No description provided for @electronicsAndHomeAppliancesAds.
  ///
  /// In en, this message translates to:
  /// **'Electronics & Home Appliances Ads'**
  String get electronicsAndHomeAppliancesAds;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @sectionType.
  ///
  /// In en, this message translates to:
  /// **'Section Type'**
  String get sectionType;

  /// No description provided for @add4Images.
  ///
  /// In en, this message translates to:
  /// **'Add 4 Images'**
  String get add4Images;

  /// No description provided for @carsRentAds.
  ///
  /// In en, this message translates to:
  /// **'Cars Rent Ads'**
  String get carsRentAds;

  /// No description provided for @dayRent.
  ///
  /// In en, this message translates to:
  /// **'Day Rent'**
  String get dayRent;

  /// No description provided for @monthRent.
  ///
  /// In en, this message translates to:
  /// **'Month Rent'**
  String get monthRent;

  /// No description provided for @add10Images.
  ///
  /// In en, this message translates to:
  /// **'Add 10 Images'**
  String get add10Images;

  /// No description provided for @restaurantsAds.
  ///
  /// In en, this message translates to:
  /// **'Restaurants Ads'**
  String get restaurantsAds;

  /// No description provided for @no_restaurants_found.
  ///
  /// In en, this message translates to:
  /// **'No restaurants found'**
  String get no_restaurants_found;

  /// No description provided for @otherServicesAds.
  ///
  /// In en, this message translates to:
  /// **'Other Services Ads'**
  String get otherServicesAds;

  /// No description provided for @jobsAds.
  ///
  /// In en, this message translates to:
  /// **'Jobs Ads'**
  String get jobsAds;

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Category Type'**
  String get categoryType;

  /// No description provided for @jobName.
  ///
  /// In en, this message translates to:
  /// **'Job Name'**
  String get jobName;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @valid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @postDate.
  ///
  /// In en, this message translates to:
  /// **'Post Date'**
  String get postDate;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires In'**
  String get expiresIn;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Search & Views'**
  String get views;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editAd.
  ///
  /// In en, this message translates to:
  /// **'Edit Ad'**
  String get editAd;

  /// No description provided for @renew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renew;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @adsType.
  ///
  /// In en, this message translates to:
  /// **'ADS Type'**
  String get adsType;

  /// No description provided for @totalAds.
  ///
  /// In en, this message translates to:
  /// **'Total ADS'**
  String get totalAds;

  /// No description provided for @manageAds.
  ///
  /// In en, this message translates to:
  /// **'Manage Ads'**
  String get manageAds;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @contractExpire.
  ///
  /// In en, this message translates to:
  /// **'Contract Expire (use Ads before) Date'**
  String get contractExpire;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @activeOffersBox.
  ///
  /// In en, this message translates to:
  /// **'Active Offers Box'**
  String get activeOffersBox;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @payWithCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Pay With Credit Card'**
  String get payWithCreditCard;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @expireDate.
  ///
  /// In en, this message translates to:
  /// **'Expire Date'**
  String get expireDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @cardHolderName.
  ///
  /// In en, this message translates to:
  /// **'Card Holder Name'**
  String get cardHolderName;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get noResultsFound;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @chooseAnOption.
  ///
  /// In en, this message translates to:
  /// **'Choose An Option'**
  String get chooseAnOption;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password Too Short'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords Don`t Match'**
  String get passwordsDoNotMatch;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully'**
  String get accountCreatedSuccessfully;

  /// No description provided for @agreeTermsValidation.
  ///
  /// In en, this message translates to:
  /// **'Agree Terms Validation'**
  String get agreeTermsValidation;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown Error'**
  String get unknownError;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'please Enter Valid Email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'please Enter Phone'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'please Enter Username'**
  String get pleaseEnterUsername;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'search Country'**
  String get searchCountry;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'please Confirm Password'**
  String get pleaseConfirmPassword;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get no;

  /// No description provided for @read_more.
  ///
  /// In en, this message translates to:
  /// **'read more'**
  String get read_more;

  /// No description provided for @show_less.
  ///
  /// In en, this message translates to:
  /// **'show_less'**
  String get show_less;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get loading;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get delete;

  /// No description provided for @please_select_make.
  ///
  /// In en, this message translates to:
  /// **'Please select make'**
  String get please_select_make;

  /// No description provided for @please_select_model.
  ///
  /// In en, this message translates to:
  /// **'Please select model'**
  String get please_select_model;

  /// No description provided for @please_fill_required_fields.
  ///
  /// In en, this message translates to:
  /// **'please_fill_required_fields'**
  String get please_fill_required_fields;

  /// No description provided for @searchForLocation.
  ///
  /// In en, this message translates to:
  /// **'Search for a location'**
  String get searchForLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @pickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick Location'**
  String get pickLocation;

  /// No description provided for @enterArea.
  ///
  /// In en, this message translates to:
  /// **'Enter Area'**
  String get enterArea;

  /// No description provided for @areaName.
  ///
  /// In en, this message translates to:
  /// **'Area Name'**
  String get areaName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterServiceName.
  ///
  /// In en, this message translates to:
  /// **'Enter service name'**
  String get enterServiceName;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get enterProductName;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your title'**
  String get enterTitle;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your description'**
  String get enterDescription;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get totalPrice;

  /// No description provided for @enterContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter phone or WhatsApp or email'**
  String get enterContactInfo;

  /// No description provided for @please_select_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please select all fields'**
  String get please_select_all_fields;

  /// No description provided for @please_select_emirate_and_section_type_first.
  ///
  /// In en, this message translates to:
  /// **'Please select emirate and section type first'**
  String get please_select_emirate_and_section_type_first;

  /// No description provided for @please_select_emirate_and_category_type.
  ///
  /// In en, this message translates to:
  /// **'Please select emirate and category type'**
  String get please_select_emirate_and_category_type;

  /// No description provided for @please_select_service_type.
  ///
  /// In en, this message translates to:
  /// **'Please select a service type'**
  String get please_select_service_type;

  /// No description provided for @please_select_section_type.
  ///
  /// In en, this message translates to:
  /// **'Please select section type'**
  String get please_select_section_type;

  /// No description provided for @secureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Account'**
  String get secureYourAccount;

  /// No description provided for @setPasswordToUpgradeDescription.
  ///
  /// In en, this message translates to:
  /// **'Before upgrading to an Advertiser account, please set a password to safeguard your account and confirm the update.'**
  String get setPasswordToUpgradeDescription;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPassword;

  /// No description provided for @passwordSetSuccessUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Password set successfully and your account upgraded to advertiser'**
  String get passwordSetSuccessUpgraded;

  /// No description provided for @errorSettingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error setting password'**
  String get errorSettingPassword;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @freeAdNotEligibleMessage.
  ///
  /// In en, this message translates to:
  /// **'Free ads are only available for cars priced under {price} AED. Please choose another plan.'**
  String freeAdNotEligibleMessage(Object price);

  /// No description provided for @adDataIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Ad data is incomplete'**
  String get adDataIncomplete;

  /// No description provided for @adPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ad posted successfully!'**
  String get adPublishedSuccessfully;

  /// No description provided for @planExpiredOrInactivePleasePay.
  ///
  /// In en, this message translates to:
  /// **'Plan expired or no active plan. Please pay to complete posting'**
  String get planExpiredOrInactivePleasePay;

  /// No description provided for @errorOccurredWithMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {message}'**
  String errorOccurredWithMessage(Object message);

  /// No description provided for @favoritesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites: {error}'**
  String favoritesLoadFailed(Object error);

  /// No description provided for @favoriteRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ad removed from favorites'**
  String get favoriteRemovedSuccess;

  /// No description provided for @favoriteRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove ad: {error}'**
  String favoriteRemoveFailed(Object error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'You must log in first to view your favorites'**
  String get loginRequiredDescription;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// No description provided for @favoritesEmptySection.
  ///
  /// In en, this message translates to:
  /// **'No favorite items in this section'**
  String get favoritesEmptySection;

  /// No description provided for @removeFromFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavoritesTitle;

  /// No description provided for @removeFromFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this ad from favorites?'**
  String get removeFromFavoritesMessage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please log in first'**
  String get pleaseLoginFirst;

  /// No description provided for @adIdNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ad ID not available'**
  String get adIdNotAvailable;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact: {info}'**
  String contactLabel(Object info);

  /// No description provided for @couldNotLaunch.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {url}'**
  String couldNotLaunch(Object url);

  /// No description provided for @whatsappInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid WhatsApp number format'**
  String get whatsappInvalid;

  /// No description provided for @whatsappNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number not available'**
  String get whatsappNotAvailable;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format'**
  String get phoneInvalid;

  /// No description provided for @phoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number not available'**
  String get phoneNotAvailable;

  /// No description provided for @whatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp: {number}'**
  String whatsappLabel(Object number);

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone: {number}'**
  String phoneLabel(Object number);

  /// No description provided for @offerBoxActivating.
  ///
  /// In en, this message translates to:
  /// **'Activating {boxName}...'**
  String offerBoxActivating(Object boxName);

  /// No description provided for @offerBoxActivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer box activated for this ad'**
  String get offerBoxActivatedSuccess;

  /// No description provided for @offerBoxActivationFailed.
  ///
  /// In en, this message translates to:
  /// **'Offer box activation failed'**
  String get offerBoxActivationFailed;

  /// No description provided for @deleteAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Ad'**
  String get deleteAdTitle;

  /// No description provided for @deleteAdConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this ad?'**
  String get deleteAdConfirmation;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get yesDelete;

  /// No description provided for @adDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ad deleted'**
  String get adDeletedSuccess;

  /// No description provided for @adDeletedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete ad'**
  String get adDeletedFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
