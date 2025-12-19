import 'dart:io' show Platform;

import 'package:ayet_sdk_v2/ayet_sdk_v2.dart';

/// Ayet SDK Configuration
///
/// Modify these values to match your Ayet account settings.
class AyetConfig {
  // Platform-specific placement IDs
  static const int placementIdAndroid = 21478;
  static const int placementIdIos = 21481;

  // Get the correct placement ID for the current platform
  static int get placementId =>
      Platform.isIOS ? placementIdIos : placementIdAndroid;

  // Ad slot names (as configured in your Ayet dashboard)
  static const String adslotOfferwall = 'FlutterSdkV2DemoOfferwall';
  static const String adslotSurveywall = 'FlutterSdkV2DemoSurveywall';
  static const String adslotFeed = 'FlutterSdkV2DemoOfferwallApi';

  // User targeting defaults
  static const AyetGender defaultGender = AyetGender.male;
  static const int defaultAge = 27;
  static const String defaultCustom1 = 'demo_app_example_custom';
}
