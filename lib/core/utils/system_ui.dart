import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constance/app_colors.dart';

class SystemUi {
  SystemUi._();

  static SystemUiOverlayStyle get adaptive => AppColors.isDark ? _lightIcons : _darkIcons;

  static SystemUiOverlayStyle get onBrand => _lightIcons;

  static SystemUiOverlayStyle get _lightIcons => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.bg,
        systemNavigationBarIconBrightness: AppColors.isDark ? Brightness.light : Brightness.dark,
        systemStatusBarContrastEnforced: false,
      );

  static SystemUiOverlayStyle get _darkIcons => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bg,
        systemNavigationBarIconBrightness: AppColors.isDark ? Brightness.light : Brightness.dark,
        systemStatusBarContrastEnforced: false,
      );

  static void apply() => SystemChrome.setSystemUIOverlayStyle(adaptive);
}
