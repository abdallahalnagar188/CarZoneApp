import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/dio_helper.dart';
import '../services/session_service.dart';
import 'cache_helper.dart';

class LanguageGetxController extends GetxController {
  static const String langKey = 'langCode';
  static const String defaultLang = 'ar';

  String lang = defaultLang;

  bool get isArabic => lang == 'ar';

  static Locale get cachedLocale {
    final saved =
        CacheHelper.sharedPreferences.getString(langKey) ?? defaultLang;
    return Locale(saved);
  }

  @override
  void onInit() {
    super.onInit();
    lang = cachedLocale.languageCode;
  }

  Future<void> changeLanguage(String languageCode) async {
    if (lang == languageCode) return;
    lang = languageCode;
    await CacheHelper.sharedPreferences.setString(langKey, languageCode);
    await Get.updateLocale(Locale(languageCode));
    await DioHelper.updateHeadersManually();
    update();
    // Push notifications follow customers.locale (GAP-036).
    if (Get.isRegistered<SessionService>()) Get.find<SessionService>().syncLocale(languageCode);
  }

  Future<void> toggle() => changeLanguage(isArabic ? 'en' : 'ar');
}
