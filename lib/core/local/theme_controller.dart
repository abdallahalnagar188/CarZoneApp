import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../constance/app_colors.dart';
import '../enums/enums.dart';
import 'cache_controller.dart';

class ThemeController extends GetxController {
  final isDarkMode = false.obs;

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    final cached = CacheController().getter(key: CacheKeys.theme);
    final dark = cached is bool ? cached : false;
    isDarkMode.value = dark;
    AppColors.applyDark(dark);
  }

  Future<void> setDarkMode(bool value) async {
    if (isDarkMode.value == value) return;
    isDarkMode.value = value;
    AppColors.applyDark(value);
    await CacheController().setter(key: CacheKeys.theme, value: value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    Get.forceAppUpdate();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: value ? Brightness.light : Brightness.dark,
        statusBarBrightness: value ? Brightness.dark : Brightness.light,
      ),
    );
    update();
  }

  Future<void> toggleDarkMode() => setDarkMode(!isDarkMode.value);
}
