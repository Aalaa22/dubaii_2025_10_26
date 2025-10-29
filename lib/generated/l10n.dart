// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Sign Up`
  String get signUp {
    return Intl.message('Sign Up', name: 'signUp', desc: '', args: []);
  }

  /// `User Name`
  String get userName {
    return Intl.message('User Name', name: 'userName', desc: '', args: []);
  }

  /// `Phone`
  String get phone {
    return Intl.message('Phone', name: 'phone', desc: '', args: []);
  }

  /// `508236561`
  String get phoneNumberHint {
    return Intl.message(
      '508236561',
      name: 'phoneNumberHint',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Referral Code`
  String get referralCode {
    return Intl.message(
      'Referral Code',
      name: 'referralCode',
      desc: '',
      args: [],
    );
  }

  /// `I Agree Terms & Conditions`
  String get agreeTerms {
    return Intl.message(
      'I Agree Terms & Conditions',
      name: 'agreeTerms',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message('Register', name: 'register', desc: '', args: []);
  }

  /// `Or`
  String get or {
    return Intl.message('Or', name: 'or', desc: '', args: []);
  }

  /// `Guest Login`
  String get guestLogin {
    return Intl.message('Guest Login', name: 'guestLogin', desc: '', args: []);
  }

  /// `Email Sign Up`
  String get emailSignUp {
    return Intl.message(
      'Email Sign Up',
      name: 'emailSignUp',
      desc: '',
      args: [],
    );
  }

  /// `Log In`
  String get login {
    return Intl.message('Log In', name: 'login', desc: '', args: []);
  }

  /// `Already Have An Account?`
  String get haveAccount {
    return Intl.message(
      'Already Have An Account?',
      name: 'haveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Forgot Password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot Password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Email Login`
  String get emailLogin {
    return Intl.message('Email Login', name: 'emailLogin', desc: '', args: []);
  }

  /// `Don't Have An Account?`
  String get dontHaveAccount {
    return Intl.message(
      'Don\'t Have An Account?',
      name: 'dontHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Create Account`
  String get createAccount {
    return Intl.message(
      'Create Account',
      name: 'createAccount',
      desc: '',
      args: [],
    );
  }

  /// `phone sign Up`
  String get phonesignup {
    return Intl.message(
      'phone sign Up',
      name: 'phonesignup',
      desc: '',
      args: [],
    );
  }

  /// `عربي`
  String get english {
    return Intl.message('عربي', name: 'english', desc: '', args: []);
  }

  /// `English`
  String get arabic {
    return Intl.message('English', name: 'arabic', desc: '', args: []);
  }

  /// `Phone Login`
  String get phoneLogin {
    return Intl.message('Phone Login', name: 'phoneLogin', desc: '', args: []);
  }

  /// `My Profile`
  String get myProfile {
    return Intl.message('My Profile', name: 'myProfile', desc: '', args: []);
  }

  /// `Create Agent Code`
  String get createAgentCode {
    return Intl.message(
      'Create Agent Code',
      name: 'createAgentCode',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Contact Us`
  String get contactUs {
    return Intl.message('Contact Us', name: 'contactUs', desc: '', args: []);
  }

  /// `Terms & Conditions`
  String get termsAndConditions {
    return Intl.message(
      'Terms & Conditions',
      name: 'termsAndConditions',
      desc: '',
      args: [],
    );
  }

  /// `Support Center`
  String get supportCenter {
    return Intl.message(
      'Support Center',
      name: 'supportCenter',
      desc: '',
      args: [],
    );
  }

  /// `Privacy & Security`
  String get privacySecurity {
    return Intl.message(
      'Privacy & Security',
      name: 'privacySecurity',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `WhatsApp`
  String get whatsApp {
    return Intl.message('WhatsApp', name: 'whatsApp', desc: '', args: []);
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Advertiser Name`
  String get advertiserName {
    return Intl.message(
      'Advertiser Name',
      name: 'advertiserName',
      desc: '',
      args: [],
    );
  }

  /// `Advertiser Type`
  String get advertiserType {
    return Intl.message(
      'Advertiser Type',
      name: 'advertiserType',
      desc: '',
      args: [],
    );
  }

  /// `Advertiser Logo`
  String get advertiserLogo {
    return Intl.message(
      'Advertiser Logo',
      name: 'advertiserLogo',
      desc: '',
      args: [],
    );
  }

  /// `Upload Your Logo`
  String get uploadYourLogo {
    return Intl.message(
      'Upload Your Logo',
      name: 'uploadYourLogo',
      desc: '',
      args: [],
    );
  }

  /// `Advertiser Location`
  String get advertiserLocation {
    return Intl.message(
      'Advertiser Location',
      name: 'advertiserLocation',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `Locate Me`
  String get locateMe {
    return Intl.message('Locate Me', name: 'locateMe', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `optional`
  String get optional {
    return Intl.message('optional', name: 'optional', desc: '', args: []);
  }

  /// `Premium`
  String get premium {
    return Intl.message('Premium', name: 'premium', desc: '', args: []);
  }

  /// `Price`
  String get price {
    return Intl.message('Price', name: 'price', desc: '', args: []);
  }

  /// `Location`
  String get location {
    return Intl.message('Location', name: 'location', desc: '', args: []);
  }

  /// `Al Manara Motors`
  String get placeName {
    return Intl.message(
      'Al Manara Motors',
      name: 'placeName',
      desc: '',
      args: [],
    );
  }

  /// `Date: {date}`
  String date(Object date) {
    return Intl.message('Date: $date', name: 'date', desc: '', args: [date]);
  }

  /// `{price}`
  String priceOnly(Object price) {
    return Intl.message('$price', name: 'priceOnly', desc: '', args: [price]);
  }

  /// `Back`
  String get back {
    return Intl.message('Back', name: 'back', desc: '', args: []);
  }

  /// `Forgot Your Password?`
  String get forgetyourpass {
    return Intl.message(
      'Forgot Your Password?',
      name: 'forgetyourpass',
      desc: '',
      args: [],
    );
  }

  /// `Enter Your phone`
  String get enterphone {
    return Intl.message(
      'Enter Your phone',
      name: 'enterphone',
      desc: '',
      args: [],
    );
  }

  /// `Send Code`
  String get sendcode {
    return Intl.message('Send Code', name: 'sendcode', desc: '', args: []);
  }

  /// `Enter Your Email`
  String get enteremail {
    return Intl.message(
      'Enter Your Email',
      name: 'enteremail',
      desc: '',
      args: [],
    );
  }

  /// `Verify Your Number`
  String get verifnum {
    return Intl.message(
      'Verify Your Number',
      name: 'verifnum',
      desc: '',
      args: [],
    );
  }

  /// `We've sent an SMS with an activation code to your phone`
  String get phoneverify {
    return Intl.message(
      'We\'ve sent an SMS with an activation code to your phone',
      name: 'phoneverify',
      desc: '',
      args: [],
    );
  }

  /// `We've sent an Email with an activation code to your Email yourname@example.Com `
  String get emilverify {
    return Intl.message(
      'We\'ve sent an Email with an activation code to your Email yourname@example.Com ',
      name: 'emilverify',
      desc: '',
      args: [],
    );
  }

  /// `Verify`
  String get verify {
    return Intl.message('Verify', name: 'verify', desc: '', args: []);
  }

  /// `Reset Password`
  String get resetpass {
    return Intl.message(
      'Reset Password',
      name: 'resetpass',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get newpass {
    return Intl.message('New password', name: 'newpass', desc: '', args: []);
  }

  /// `Confirm Password`
  String get confirmpass {
    return Intl.message(
      'Confirm Password',
      name: 'confirmpass',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `Favorites`
  String get favorites {
    return Intl.message('Favorites', name: 'favorites', desc: '', args: []);
  }

  /// `Car Sales`
  String get carsales {
    return Intl.message('Car Sales', name: 'carsales', desc: '', args: []);
  }

  /// `Real Estate`
  String get realestate {
    return Intl.message('Real Estate', name: 'realestate', desc: '', args: []);
  }

  /// `Electronics & Home \n Appliances`
  String get electronics {
    return Intl.message(
      'Electronics & Home \n Appliances',
      name: 'electronics',
      desc: '',
      args: [],
    );
  }

  /// `Jobs`
  String get jobs {
    return Intl.message('Jobs', name: 'jobs', desc: '', args: []);
  }

  /// `Car Rent`
  String get carrent {
    return Intl.message('Car Rent', name: 'carrent', desc: '', args: []);
  }

  /// `Car Services`
  String get carservices {
    return Intl.message(
      'Car Services',
      name: 'carservices',
      desc: '',
      args: [],
    );
  }

  /// `Restaurants`
  String get restaurants {
    return Intl.message('Restaurants', name: 'restaurants', desc: '', args: []);
  }

  /// `Other Services`
  String get otherservices {
    return Intl.message(
      'Other Services',
      name: 'otherservices',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Settings`
  String get srtting {
    return Intl.message('Settings', name: 'srtting', desc: '', args: []);
  }

  /// `Manage`
  String get manage {
    return Intl.message('Manage', name: 'manage', desc: '', args: []);
  }

  /// `Posting`
  String get post {
    return Intl.message('Posting', name: 'post', desc: '', args: []);
  }

  /// `Edit my Profile`
  String get editprof4 {
    return Intl.message(
      'Edit my Profile',
      name: 'editprof4',
      desc: '',
      args: [],
    );
  }

  /// `Editing`
  String get editing1 {
    return Intl.message('Editing', name: 'editing1', desc: '', args: []);
  }

  /// `Do you want to edit your profile`
  String get editit2 {
    return Intl.message(
      'Do you want to edit your profile',
      name: 'editit2',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit3 {
    return Intl.message('Edit', name: 'edit3', desc: '', args: []);
  }

  /// `Discover Best Cars Deals`
  String get discover_best_cars_deals {
    return Intl.message(
      'Discover Best Cars Deals',
      name: 'discover_best_cars_deals',
      desc: '',
      args: [],
    );
  }

  /// `Choose Make`
  String get choose_make {
    return Intl.message('Choose Make', name: 'choose_make', desc: '', args: []);
  }

  /// `Choose Model`
  String get choose_model {
    return Intl.message(
      'Choose Model',
      name: 'choose_model',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message('Search', name: 'search', desc: '', args: []);
  }

  /// `Click For Amazing Daily Cars Deals`
  String get click_for_amazing_daily_cars_deals {
    return Intl.message(
      'Click For Amazing Daily Cars Deals',
      name: 'click_for_amazing_daily_cars_deals',
      desc: '',
      args: [],
    );
  }

  /// `Top Premium Dealers`
  String get top_premium_dealers {
    return Intl.message(
      'Top Premium Dealers',
      name: 'top_premium_dealers',
      desc: '',
      args: [],
    );
  }

  /// `See All Ads`
  String get see_all_ads {
    return Intl.message('See All Ads', name: 'see_all_ads', desc: '', args: []);
  }

  /// `Smart Search`
  String get smart_search {
    return Intl.message(
      'Smart Search',
      name: 'smart_search',
      desc: '',
      args: [],
    );
  }

  /// `Km`
  String get km {
    return Intl.message('Km', name: 'km', desc: '', args: []);
  }

  /// `Year`
  String get year {
    return Intl.message('Year', name: 'year', desc: '', args: []);
  }

  /// `Trim`
  String get trim {
    return Intl.message('Trim', name: 'trim', desc: '', args: []);
  }

  /// `Sort By The Nearest`
  String get sort {
    return Intl.message(
      'Sort By The Nearest',
      name: 'sort',
      desc: '',
      args: [],
    );
  }

  /// `ADS NO:`
  String get ad {
    return Intl.message('ADS NO:', name: 'ad', desc: '', args: []);
  }

  /// `Car Details`
  String get car_details {
    return Intl.message('Car Details', name: 'car_details', desc: '', args: []);
  }

  /// `Car Type`
  String get car_type {
    return Intl.message('Car Type', name: 'car_type', desc: '', args: []);
  }

  /// `Trans Type`
  String get trans_type {
    return Intl.message('Trans Type', name: 'trans_type', desc: '', args: []);
  }

  /// `Color`
  String get color {
    return Intl.message('Color', name: 'color', desc: '', args: []);
  }

  /// `Interior Color`
  String get interior_color {
    return Intl.message(
      'Interior Color',
      name: 'interior_color',
      desc: '',
      args: [],
    );
  }

  /// `Fuel Type`
  String get fuel_type {
    return Intl.message('Fuel Type', name: 'fuel_type', desc: '', args: []);
  }

  /// `Warranty`
  String get warranty {
    return Intl.message('Warranty', name: 'warranty', desc: '', args: []);
  }

  /// `Doors No`
  String get doors_no {
    return Intl.message('Doors No', name: 'doors_no', desc: '', args: []);
  }

  /// `Seats No`
  String get seats_no {
    return Intl.message('Seats No', name: 'seats_no', desc: '', args: []);
  }

  /// `Engine Capacity`
  String get engine_capacity {
    return Intl.message(
      'Engine Capacity',
      name: 'engine_capacity',
      desc: '',
      args: [],
    );
  }

  /// `Cylinders`
  String get cylinders {
    return Intl.message('Cylinders', name: 'cylinders', desc: '', args: []);
  }

  /// `Horse Power`
  String get horse_power {
    return Intl.message('Horse Power', name: 'horse_power', desc: '', args: []);
  }

  /// `Steering Side`
  String get steering_side {
    return Intl.message(
      'Steering Side',
      name: 'steering_side',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message('Description', name: 'description', desc: '', args: []);
  }

  /// `Agent`
  String get agent {
    return Intl.message('Agent', name: 'agent', desc: '', args: []);
  }

  /// `View All Ads`
  String get view_all_ads {
    return Intl.message(
      'View All Ads',
      name: 'view_all_ads',
      desc: '',
      args: [],
    );
  }

  /// `Report This Ad`
  String get report_this_ad {
    return Intl.message(
      'Report This Ad',
      name: 'report_this_ad',
      desc: '',
      args: [],
    );
  }

  /// `Contact us To Use This Space For Your Ads`
  String get use_this_space_for_ads {
    return Intl.message(
      'Contact us To Use This Space For Your Ads',
      name: 'use_this_space_for_ads',
      desc: '',
      args: [],
    );
  }

  /// `🌟 Top Premium Ads`
  String get priority_first_premium {
    return Intl.message(
      '🌟 Top Premium Ads',
      name: 'priority_first_premium',
      desc: '',
      args: [],
    );
  }

  /// `💎 Premium Ads`
  String get priority_premium {
    return Intl.message(
      '💎 Premium Ads',
      name: 'priority_premium',
      desc: '',
      args: [],
    );
  }

  /// `🚀 Featured Ads`
  String get priority_featured {
    return Intl.message(
      '🚀 Featured Ads',
      name: 'priority_featured',
      desc: '',
      args: [],
    );
  }

  /// `📢 Free Ads`
  String get priority_free {
    return Intl.message(
      '📢 Free Ads',
      name: 'priority_free',
      desc: '',
      args: [],
    );
  }

  /// `Add to Favorite`
  String get add_to_favorite {
    return Intl.message(
      'Add to Favorite',
      name: 'add_to_favorite',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to add this item to favorites?`
  String get confirm_add_to_favorite {
    return Intl.message(
      'Do you want to add this item to favorites?',
      name: 'confirm_add_to_favorite',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message('Yes', name: 'yes', desc: '', args: []);
  }

  /// `Item added to favorites`
  String get added_to_favorite {
    return Intl.message(
      'Item added to favorites',
      name: 'added_to_favorite',
      desc: '',
      args: [],
    );
  }

  /// `remove from favorite`
  String get remove_from_favorite {
    return Intl.message(
      'remove from favorite',
      name: 'remove_from_favorite',
      desc: '',
      args: [],
    );
  }

  /// `confirm remove from favorite`
  String get confirm_remove_from_favorite {
    return Intl.message(
      'confirm remove from favorite',
      name: 'confirm_remove_from_favorite',
      desc: '',
      args: [],
    );
  }

  /// `When enabled, others won’t know that you viewed their ad or interacted with it.`
  String get invisibleInfo {
    return Intl.message(
      'When enabled, others won’t know that you viewed their ad or interacted with it.',
      name: 'invisibleInfo',
      desc: '',
      args: [],
    );
  }

  /// `Invisible Browsing`
  String get invisibleTitle {
    return Intl.message(
      'Invisible Browsing',
      name: 'invisibleTitle',
      desc: '',
      args: [],
    );
  }

  /// `What is Invisible?`
  String get invisibleInfoTitle {
    return Intl.message(
      'What is Invisible?',
      name: 'invisibleInfoTitle',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get ok {
    return Intl.message('Ok', name: 'ok', desc: '', args: []);
  }

  /// `Discover Best Rental Deals`
  String get discover_deals {
    return Intl.message(
      'Discover Best Rental Deals',
      name: 'discover_deals',
      desc: '',
      args: [],
    );
  }

  /// `Click For Amazing Daily Rental Deals`
  String get click_for_deals {
    return Intl.message(
      'Click For Amazing Daily Rental Deals',
      name: 'click_for_deals',
      desc: '',
      args: [],
    );
  }

  /// `Discover Best Properties Deals`
  String get discover_real_estate {
    return Intl.message(
      'Discover Best Properties Deals',
      name: 'discover_real_estate',
      desc: '',
      args: [],
    );
  }

  /// `Emirate`
  String get emirate {
    return Intl.message('Emirate', name: 'emirate', desc: '', args: []);
  }

  /// `District`
  String get district {
    return Intl.message('District', name: 'district', desc: '', args: []);
  }

  /// `Property Type`
  String get property_type {
    return Intl.message(
      'Property Type',
      name: 'property_type',
      desc: '',
      args: [],
    );
  }

  /// `Contract Type`
  String get contract_type {
    return Intl.message(
      'Contract Type',
      name: 'contract_type',
      desc: '',
      args: [],
    );
  }

  /// `Click For Amazing Properties Deals`
  String get click_for_deals_real_estate {
    return Intl.message(
      'Click For Amazing Properties Deals',
      name: 'click_for_deals_real_estate',
      desc: '',
      args: [],
    );
  }

  /// `Discover Best Electronics & Appliances`
  String get discover_elect {
    return Intl.message(
      'Discover Best Electronics & Appliances',
      name: 'discover_elect',
      desc: '',
      args: [],
    );
  }

  /// `Section Type`
  String get section_type {
    return Intl.message(
      'Section Type',
      name: 'section_type',
      desc: '',
      args: [],
    );
  }

  /// `Section `
  String get section {
    return Intl.message('Section ', name: 'section', desc: '', args: []);
  }

  /// `Product`
  String get product {
    return Intl.message('Product', name: 'product', desc: '', args: []);
  }

  /// `Electronics &`
  String get electronics2 {
    return Intl.message(
      'Electronics &',
      name: 'electronics2',
      desc: '',
      args: [],
    );
  }

  /// `Home  Appliances`
  String get electronics3 {
    return Intl.message(
      'Home  Appliances',
      name: 'electronics3',
      desc: '',
      args: [],
    );
  }

  /// `Category `
  String get category {
    return Intl.message('Category ', name: 'category', desc: '', args: []);
  }

  /// `Type`
  String get type {
    return Intl.message('Type', name: 'type', desc: '', args: []);
  }

  /// `Contract`
  String get contract {
    return Intl.message('Contract', name: 'contract', desc: '', args: []);
  }

  /// `Service`
  String get service {
    return Intl.message('Service', name: 'service', desc: '', args: []);
  }

  /// `Click For Amazing Electronics & Home Appliances Deals`
  String get click_for_deals_elect {
    return Intl.message(
      'Click For Amazing Electronics & Home Appliances Deals',
      name: 'click_for_deals_elect',
      desc: '',
      args: [],
    );
  }

  /// `Category Type`
  String get category_type {
    return Intl.message(
      'Category Type',
      name: 'category_type',
      desc: '',
      args: [],
    );
  }

  /// `Click For Amazing Job Offers`
  String get click_for_deals_job {
    return Intl.message(
      'Click For Amazing Job Offers',
      name: 'click_for_deals_job',
      desc: '',
      args: [],
    );
  }

  /// `Discover Best Job Offers`
  String get discover_best_job {
    return Intl.message(
      'Discover Best Job Offers',
      name: 'discover_best_job',
      desc: '',
      args: [],
    );
  }

  /// `Service name`
  String get service_type {
    return Intl.message(
      'Service name',
      name: 'service_type',
      desc: '',
      args: [],
    );
  }

  /// `Click For Amazing  Cars Services Deals`
  String get click_for_deals_car_service {
    return Intl.message(
      'Click For Amazing  Cars Services Deals',
      name: 'click_for_deals_car_service',
      desc: '',
      args: [],
    );
  }

  /// `Discover Best Cars Services Deals`
  String get discover_car_service {
    return Intl.message(
      'Discover Best Cars Services Deals',
      name: 'discover_car_service',
      desc: '',
      args: [],
    );
  }

  /// `District`
  String get district_choose {
    return Intl.message(
      'District',
      name: 'district_choose',
      desc: '',
      args: [],
    );
  }

  /// `Click For Amazing Daily Offers`
  String get click_daily_offers {
    return Intl.message(
      'Click For Amazing Daily Offers',
      name: 'click_daily_offers',
      desc: '',
      args: [],
    );
  }

  /// `Discover Best Restaurants Offers`
  String get discover_restaurants_offers {
    return Intl.message(
      'Discover Best Restaurants Offers',
      name: 'discover_restaurants_offers',
      desc: '',
      args: [],
    );
  }

  /// `Click For Amazing Services Offers`
  String get click_daily_servir_offers {
    return Intl.message(
      'Click For Amazing Services Offers',
      name: 'click_daily_servir_offers',
      desc: '',
      args: [],
    );
  }

  /// `Discover Best Services Offers`
  String get discover_service_offers {
    return Intl.message(
      'Discover Best Services Offers',
      name: 'discover_service_offers',
      desc: '',
      args: [],
    );
  }

  /// `Place An Ad`
  String get place_an_ad {
    return Intl.message('Place An Ad', name: 'place_an_ad', desc: '', args: []);
  }

  /// `Featured`
  String get featured {
    return Intl.message('Featured', name: 'featured', desc: '', args: []);
  }

  /// `Free`
  String get free {
    return Intl.message('Free', name: 'free', desc: '', args: []);
  }

  /// `Appearance On Top Of Search List`
  String get appearance_top {
    return Intl.message(
      'Appearance On Top Of Search List',
      name: 'appearance_top',
      desc: '',
      args: [],
    );
  }

  /// `Appearance For The Nearest Viewers`
  String get appearance_nearest {
    return Intl.message(
      'Appearance For The Nearest Viewers',
      name: 'appearance_nearest',
      desc: '',
      args: [],
    );
  }

  /// `Appearance After Premium`
  String get appearance_after_star {
    return Intl.message(
      'Appearance After Premium',
      name: 'appearance_after_star',
      desc: '',
      args: [],
    );
  }

  /// `Appearance After Premium Ads`
  String get appearance_after_premium {
    return Intl.message(
      'Appearance After Premium Ads',
      name: 'appearance_after_premium',
      desc: '',
      args: [],
    );
  }

  /// `Appearance After Featured Ads`
  String get appearance_after_featured {
    return Intl.message(
      'Appearance After Featured Ads',
      name: 'appearance_after_featured',
      desc: '',
      args: [],
    );
  }

  /// `Enabled Daily Refresh`
  String get daily_refresh {
    return Intl.message(
      'Enabled Daily Refresh',
      name: 'daily_refresh',
      desc: '',
      args: [],
    );
  }

  /// `Cost`
  String get cost {
    return Intl.message('Cost', name: 'cost', desc: '', args: []);
  }

  /// `For [{days}] Days`
  String for_days(Object days) {
    return Intl.message(
      'For [$days] Days',
      name: 'for_days',
      desc: '',
      args: [days],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Top Of The Day Comes First On The Search List`
  String get top_of_day_note {
    return Intl.message(
      'Top Of The Day Comes First On The Search List',
      name: 'top_of_day_note',
      desc: '',
      args: [],
    );
  }

  /// `Cars Sales Ads`
  String get appTitle {
    return Intl.message('Cars Sales Ads', name: 'appTitle', desc: '', args: []);
  }

  /// `العربية`
  String get toggleLang {
    return Intl.message('العربية', name: 'toggleLang', desc: '', args: []);
  }

  /// `Make`
  String get make {
    return Intl.message('Make', name: 'make', desc: '', args: []);
  }

  /// `Model`
  String get model {
    return Intl.message('Model', name: 'model', desc: '', args: []);
  }

  /// `Specs`
  String get specs {
    return Intl.message('Specs', name: 'specs', desc: '', args: []);
  }

  /// `Title`
  String get title {
    return Intl.message('Title', name: 'title', desc: '', args: []);
  }

  /// `Car Type`
  String get carType {
    return Intl.message('Car Type', name: 'carType', desc: '', args: []);
  }

  /// `Trans Type`
  String get transType {
    return Intl.message('Trans Type', name: 'transType', desc: '', args: []);
  }

  /// `Fuel Type`
  String get fuelType {
    return Intl.message('Fuel Type', name: 'fuelType', desc: '', args: []);
  }

  /// `Interior Color`
  String get interiorColor {
    return Intl.message(
      'Interior Color',
      name: 'interiorColor',
      desc: '',
      args: [],
    );
  }

  /// `Engine Capacity`
  String get engineCapacity {
    return Intl.message(
      'Engine Capacity',
      name: 'engineCapacity',
      desc: '',
      args: [],
    );
  }

  /// `Horse Power`
  String get horsePower {
    return Intl.message('Horse Power', name: 'horsePower', desc: '', args: []);
  }

  /// `Doors No`
  String get doorsNo {
    return Intl.message('Doors No', name: 'doorsNo', desc: '', args: []);
  }

  /// `Seats No`
  String get seatsNo {
    return Intl.message('Seats No', name: 'seatsNo', desc: '', args: []);
  }

  /// `Steering Side`
  String get steeringSide {
    return Intl.message(
      'Steering Side',
      name: 'steeringSide',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Area`
  String get area {
    return Intl.message('Area', name: 'area', desc: '', args: []);
  }

  /// `Describe Your Car`
  String get describeYourCar {
    return Intl.message(
      'Describe Your Car',
      name: 'describeYourCar',
      desc: '',
      args: [],
    );
  }

  /// `Translate`
  String get translate {
    return Intl.message('Translate', name: 'translate', desc: '', args: []);
  }

  /// `Add Main Image`
  String get addMainImage {
    return Intl.message(
      'Add Main Image',
      name: 'addMainImage',
      desc: '',
      args: [],
    );
  }

  /// `Add 14 Images`
  String get add14Images {
    return Intl.message(
      'Add 14 Images',
      name: 'add14Images',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Cars Services Ads`
  String get carsServicesAds {
    return Intl.message(
      'Cars Services Ads',
      name: 'carsServicesAds',
      desc: '',
      args: [],
    );
  }

  /// `Service Type`
  String get serviceType {
    return Intl.message(
      'Service Type',
      name: 'serviceType',
      desc: '',
      args: [],
    );
  }

  /// `Service Name`
  String get serviceName {
    return Intl.message(
      'Service Name',
      name: 'serviceName',
      desc: '',
      args: [],
    );
  }

  /// `Add 3 Images`
  String get add3Images {
    return Intl.message('Add 3 Images', name: 'add3Images', desc: '', args: []);
  }

  /// `Real Estate Ads`
  String get realEstateAds {
    return Intl.message(
      'Real Estate Ads',
      name: 'realEstateAds',
      desc: '',
      args: [],
    );
  }

  /// `Contract Type`
  String get contractType {
    return Intl.message(
      'Contract Type',
      name: 'contractType',
      desc: '',
      args: [],
    );
  }

  /// `Property Type`
  String get propertyType {
    return Intl.message(
      'Property Type',
      name: 'propertyType',
      desc: '',
      args: [],
    );
  }

  /// `Add 9 Images`
  String get add9Images {
    return Intl.message('Add 9 Images', name: 'add9Images', desc: '', args: []);
  }

  /// `Electronics & Home Appliances Ads`
  String get electronicsAndHomeAppliancesAds {
    return Intl.message(
      'Electronics & Home Appliances Ads',
      name: 'electronicsAndHomeAppliancesAds',
      desc: '',
      args: [],
    );
  }

  /// `Product Name`
  String get productName {
    return Intl.message(
      'Product Name',
      name: 'productName',
      desc: '',
      args: [],
    );
  }

  /// `Section Type`
  String get sectionType {
    return Intl.message(
      'Section Type',
      name: 'sectionType',
      desc: '',
      args: [],
    );
  }

  /// `Add 4 Images`
  String get add4Images {
    return Intl.message('Add 4 Images', name: 'add4Images', desc: '', args: []);
  }

  /// `Cars Rent Ads`
  String get carsRentAds {
    return Intl.message(
      'Cars Rent Ads',
      name: 'carsRentAds',
      desc: '',
      args: [],
    );
  }

  /// `Day Rent`
  String get dayRent {
    return Intl.message('Day Rent', name: 'dayRent', desc: '', args: []);
  }

  /// `Month Rent`
  String get monthRent {
    return Intl.message('Month Rent', name: 'monthRent', desc: '', args: []);
  }

  /// `Add 10 Images`
  String get add10Images {
    return Intl.message(
      'Add 10 Images',
      name: 'add10Images',
      desc: '',
      args: [],
    );
  }

  /// `Add 19 Images`
  String get add19Images {
    return Intl.message(
      'Add 19 Images',
      name: 'add19Images',
      desc: '',
      args: [],
    );
  }

  /// `Restaurants Ads`
  String get restaurantsAds {
    return Intl.message(
      'Restaurants Ads',
      name: 'restaurantsAds',
      desc: '',
      args: [],
    );
  }

  /// `No restaurants found`
  String get no_restaurants_found {
    return Intl.message(
      'No restaurants found',
      name: 'no_restaurants_found',
      desc: '',
      args: [],
    );
  }

  /// `Other Services Ads`
  String get otherServicesAds {
    return Intl.message(
      'Other Services Ads',
      name: 'otherServicesAds',
      desc: '',
      args: [],
    );
  }

  /// `Jobs Ads`
  String get jobsAds {
    return Intl.message('Jobs Ads', name: 'jobsAds', desc: '', args: []);
  }

  /// `Category Type`
  String get categoryType {
    return Intl.message(
      'Category Type',
      name: 'categoryType',
      desc: '',
      args: [],
    );
  }

  /// `Job Name`
  String get jobName {
    return Intl.message('Job Name', name: 'jobName', desc: '', args: []);
  }

  /// `Salary`
  String get salary {
    return Intl.message('Salary', name: 'salary', desc: '', args: []);
  }

  /// `Valid`
  String get valid {
    return Intl.message('Valid', name: 'valid', desc: '', args: []);
  }

  /// `Pending`
  String get pending {
    return Intl.message('Pending', name: 'pending', desc: '', args: []);
  }

  /// `Expired`
  String get expired {
    return Intl.message('Expired', name: 'expired', desc: '', args: []);
  }

  /// `Rejected`
  String get rejected {
    return Intl.message('Rejected', name: 'rejected', desc: '', args: []);
  }

  /// `Post Date`
  String get postDate {
    return Intl.message('Post Date', name: 'postDate', desc: '', args: []);
  }

  /// `Expires In`
  String get expiresIn {
    return Intl.message('Expires In', name: 'expiresIn', desc: '', args: []);
  }

  /// `Search & Views`
  String get views {
    return Intl.message('Search & Views', name: 'views', desc: '', args: []);
  }

  /// `Refresh`
  String get refresh {
    return Intl.message('Refresh', name: 'refresh', desc: '', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Renew`
  String get renew {
    return Intl.message('Renew', name: 'renew', desc: '', args: []);
  }

  /// `Upgrade`
  String get upgrade {
    return Intl.message('Upgrade', name: 'upgrade', desc: '', args: []);
  }

  /// `ADS Type`
  String get adsType {
    return Intl.message('ADS Type', name: 'adsType', desc: '', args: []);
  }

  /// `Total ADS`
  String get totalAds {
    return Intl.message('Total ADS', name: 'totalAds', desc: '', args: []);
  }

  /// `Manage Ads`
  String get manageAds {
    return Intl.message('Manage Ads', name: 'manageAds', desc: '', args: []);
  }

  /// `All`
  String get all {
    return Intl.message('All', name: 'all', desc: '', args: []);
  }

  /// `Balance`
  String get balance {
    return Intl.message('Balance', name: 'balance', desc: '', args: []);
  }

  /// `Contract Expire (use Ads before) Date`
  String get contractExpire {
    return Intl.message(
      'Contract Expire (use Ads before) Date',
      name: 'contractExpire',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get amount {
    return Intl.message('Amount', name: 'amount', desc: '', args: []);
  }

  /// `Days`
  String get days {
    return Intl.message('Days', name: 'days', desc: '', args: []);
  }

  /// `Active Offers Box`
  String get activeOffersBox {
    return Intl.message(
      'Active Offers Box',
      name: 'activeOffersBox',
      desc: '',
      args: [],
    );
  }

  /// `Pay`
  String get pay {
    return Intl.message('Pay', name: 'pay', desc: '', args: []);
  }

  /// `Payment`
  String get payment {
    return Intl.message('Payment', name: 'payment', desc: '', args: []);
  }

  /// `Total`
  String get total {
    return Intl.message('Total', name: 'total', desc: '', args: []);
  }

  /// `Pay With Credit Card`
  String get payWithCreditCard {
    return Intl.message(
      'Pay With Credit Card',
      name: 'payWithCreditCard',
      desc: '',
      args: [],
    );
  }

  /// `Card Number`
  String get cardNumber {
    return Intl.message('Card Number', name: 'cardNumber', desc: '', args: []);
  }

  /// `Expire Date`
  String get expireDate {
    return Intl.message('Expire Date', name: 'expireDate', desc: '', args: []);
  }

  /// `CVV`
  String get cvv {
    return Intl.message('CVV', name: 'cvv', desc: '', args: []);
  }

  /// `Card Holder Name`
  String get cardHolderName {
    return Intl.message(
      'Card Holder Name',
      name: 'cardHolderName',
      desc: '',
      args: [],
    );
  }

  /// `Pay Now`
  String get payNow {
    return Intl.message('Pay Now', name: 'payNow', desc: '', args: []);
  }

  /// `Optional`
  String get Optional {
    return Intl.message('Optional', name: 'Optional', desc: '', args: []);
  }

  /// `No Results Found`
  String get noResultsFound {
    return Intl.message(
      'No Results Found',
      name: 'noResultsFound',
      desc: '',
      args: [],
    );
  }

  /// `Add New`
  String get addNew {
    return Intl.message('Add New', name: 'addNew', desc: '', args: []);
  }

  /// `To`
  String get to {
    return Intl.message('To', name: 'to', desc: '', args: []);
  }

  /// `Any`
  String get any {
    return Intl.message('Any', name: 'any', desc: '', args: []);
  }

  /// `Apply`
  String get apply {
    return Intl.message('Apply', name: 'apply', desc: '', args: []);
  }

  /// `From`
  String get from {
    return Intl.message('From', name: 'from', desc: '', args: []);
  }

  /// `Reset`
  String get reset {
    return Intl.message('Reset', name: 'reset', desc: '', args: []);
  }

  /// `Choose An Option`
  String get chooseAnOption {
    return Intl.message(
      'Choose An Option',
      name: 'chooseAnOption',
      desc: '',
      args: [],
    );
  }

  /// `Password Too Short`
  String get passwordTooShort {
    return Intl.message(
      'Password Too Short',
      name: 'passwordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Passwords Don't Match`
  String get passwordsDoNotMatch {
    return Intl.message(
      'Passwords Don`t Match',
      name: 'passwordsDoNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `Account Created Successfully`
  String get accountCreatedSuccessfully {
    return Intl.message(
      'Account Created Successfully',
      name: 'accountCreatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Agree Terms Validation`
  String get agreeTermsValidation {
    return Intl.message(
      'Agree Terms Validation',
      name: 'agreeTermsValidation',
      desc: '',
      args: [],
    );
  }

  /// `unknown Error`
  String get unknownError {
    return Intl.message(
      'unknown Error',
      name: 'unknownError',
      desc: '',
      args: [],
    );
  }

  /// `please Enter Valid Email`
  String get pleaseEnterValidEmail {
    return Intl.message(
      'please Enter Valid Email',
      name: 'pleaseEnterValidEmail',
      desc: '',
      args: [],
    );
  }

  /// `please Enter Phone`
  String get pleaseEnterPhone {
    return Intl.message(
      'please Enter Phone',
      name: 'pleaseEnterPhone',
      desc: '',
      args: [],
    );
  }

  /// `please Enter Username`
  String get pleaseEnterUsername {
    return Intl.message(
      'please Enter Username',
      name: 'pleaseEnterUsername',
      desc: '',
      args: [],
    );
  }

  /// `search Country`
  String get searchCountry {
    return Intl.message(
      'search Country',
      name: 'searchCountry',
      desc: '',
      args: [],
    );
  }

  /// `please Confirm Password`
  String get pleaseConfirmPassword {
    return Intl.message(
      'please Confirm Password',
      name: 'pleaseConfirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `no`
  String get no {
    return Intl.message('no', name: 'no', desc: '', args: []);
  }

  /// `read more`
  String get read_more {
    return Intl.message('read more', name: 'read_more', desc: '', args: []);
  }

  /// `show_less`
  String get show_less {
    return Intl.message('show_less', name: 'show_less', desc: '', args: []);
  }

  /// `loading`
  String get loading {
    return Intl.message('loading', name: 'loading', desc: '', args: []);
  }

  /// `delete`
  String get delete {
    return Intl.message('delete', name: 'delete', desc: '', args: []);
  }

  /// `please_select_make`
  String get please_select_make {
    return Intl.message(
      'please_select_make',
      name: 'please_select_make',
      desc: '',
      args: [],
    );
  }

  /// `please_fill_required_fields`
  String get please_fill_required_fields {
    return Intl.message(
      'please_fill_required_fields',
      name: 'please_fill_required_fields',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
