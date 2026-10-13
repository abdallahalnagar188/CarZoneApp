import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyAppTextTheme {
  MyAppTextTheme._();

  static TextTheme textThemeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFFEEF6FB) : const Color(0xFF0B1F2E);
    final secondary = isDark ? const Color(0xFF8EA6B6) : const Color(0xFF5F7686);

    return TextTheme(
      headlineLarge: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: primary, height: 1.25),
      headlineMedium: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: primary, height: 1.3),
      headlineSmall: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: primary, height: 1.35),
      titleLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: primary, height: 1.4),
      titleMedium: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      titleSmall: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      bodyLarge: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: primary, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: primary, height: 1.5),
      bodySmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: secondary, height: 1.45),
      labelLarge: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: primary),
      labelMedium: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: secondary),
      labelSmall: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: secondary),
    );
  }
}
