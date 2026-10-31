import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_helper.dart';
import 'cache_helper.dart';
import 'translation_bridge.dart';

const String _langKey = 'langCode';
const String _defaultLang = 'ar';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_initialLocale()) {
    AppTranslationsBridge.currentLanguage = state.languageCode;
  }

  static Locale _initialLocale() {
    final saved = CacheHelper.sharedPreferences.getString(_langKey) ?? _defaultLang;
    return Locale(saved);
  }

  bool get isArabic => state.languageCode == 'ar';

  Future<void> changeLanguage(String languageCode) async {
    if (state.languageCode == languageCode) return;
    state = Locale(languageCode);
    AppTranslationsBridge.currentLanguage = languageCode;
    await CacheHelper.sharedPreferences.setString(_langKey, languageCode);
    await DioHelper.updateHeadersManually();
  }

  Future<void> toggle() => changeLanguage(isArabic ? 'en' : 'ar');
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

