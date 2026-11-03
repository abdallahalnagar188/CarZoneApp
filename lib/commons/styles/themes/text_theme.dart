import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';

class MyAppTextTheme {
  MyAppTextTheme._();

  /// Material's type scale adds letter spacing (up to 0.5) that is meant for
  /// Latin text; on Arabic it pulls the joined letters apart. Every script's
  /// scale gets 0, so buttons, fields and app bars render tight too.
  static Typography typography() => Typography.material2021(
        englishLike: _tight(Typography.englishLike2021),
        dense: _tight(Typography.dense2021),
        tall: _tight(Typography.tall2021),
      );

  static TextTheme _tight(TextTheme t) => TextTheme(
        displayLarge: t.displayLarge?.copyWith(letterSpacing: 0),
        displayMedium: t.displayMedium?.copyWith(letterSpacing: 0),
        displaySmall: t.displaySmall?.copyWith(letterSpacing: 0),
        headlineLarge: t.headlineLarge?.copyWith(letterSpacing: 0),
        headlineMedium: t.headlineMedium?.copyWith(letterSpacing: 0),
        headlineSmall: t.headlineSmall?.copyWith(letterSpacing: 0),
        titleLarge: t.titleLarge?.copyWith(letterSpacing: 0),
        titleMedium: t.titleMedium?.copyWith(letterSpacing: 0),
        titleSmall: t.titleSmall?.copyWith(letterSpacing: 0),
        bodyLarge: t.bodyLarge?.copyWith(letterSpacing: 0),
        bodyMedium: t.bodyMedium?.copyWith(letterSpacing: 0),
        bodySmall: t.bodySmall?.copyWith(letterSpacing: 0),
        labelLarge: t.labelLarge?.copyWith(letterSpacing: 0),
        labelMedium: t.labelMedium?.copyWith(letterSpacing: 0),
        labelSmall: t.labelSmall?.copyWith(letterSpacing: 0),
      );

  static TextTheme textThemeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFFEEF4FF) : AppColors.brandNight;
    final secondary = isDark ? const Color(0xFF8D9BB5) : const Color(0xFF5B6B85);

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
