import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class AdMobConfig {
  static String get androidAppId => dotenv.env['ADMOB_ANDROID_APP_ID'] ?? '';
  static String get iosAppId => dotenv.env['ADMOB_IOS_APP_ID'] ?? '';

  static String get androidNativeAdId =>
      dotenv.env['ADMOB_ANDROID_NATIVE'] ?? '';
  static String get androidBannerAdId =>
      dotenv.env['ADMOB_ANDROID_BANNER'] ??
      dotenv.env['ADMOB_ANDROID_BUNNER'] ??
      '';
  static String get iosNativeAdId => dotenv.env['ADMOB_IOS_NATIVE'] ?? '';
  static String get iosBannerAdId =>
      dotenv.env['ADMOB_IOS_BANNER'] ?? dotenv.env['ADMOB_IOS_BUNNER'] ?? '';

  // プラットフォーム別のアプリID
  static String get appId {
    if (Platform.isAndroid) {
      return androidAppId;
    } else if (Platform.isIOS) {
      return iosAppId;
    }
    return '';
  }

  // プラットフォーム別のネイティブ広告ID
  static String get nativeAdId {
    if (Platform.isAndroid) {
      return androidNativeAdId;
    } else if (Platform.isIOS) {
      return iosNativeAdId;
    }
    return '';
  }

  // プラットフォーム別のバナー広告ID
  static String get bannerAdId {
    if (Platform.isAndroid) {
      return androidBannerAdId;
    } else if (Platform.isIOS) {
      return iosBannerAdId;
    }
    return '';
  }
}
