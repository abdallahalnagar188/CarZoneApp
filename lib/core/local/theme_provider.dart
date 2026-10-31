import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constance/app_colors.dart';
import '../enums/enums.dart';
import '../utils/system_ui.dart';
import 'cache_controller.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_initialTheme()) {
    final dark = state == ThemeMode.dark;
    AppColors.applyDark(dark);
    SystemUi.apply();
  }

  static ThemeMode _initialTheme() {
    final cached = CacheController().getter(key: CacheKeys.theme);
    final isDark = cached is bool ? cached : false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> setDarkMode(bool value) async {
    final newMode = value ? ThemeMode.dark : ThemeMode.light;
    if (state == newMode) return;
    state = newMode;
    AppColors.applyDark(value);
    await CacheController().setter(key: CacheKeys.theme, value: value);
    SystemUi.apply();
  }

  Future<void> toggleDarkMode() => setDarkMode(!isDarkMode);
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

