import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constance/app_colors.dart';
import 'text_theme.dart';

class MyAppTheme {
  MyAppTheme._();

  static const String fontFamily = 'IPM';

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF020B1A) : const Color(0xFFF5F8FC);
    final surface = isDark ? const Color(0xFF0A1830) : const Color(0xFFFFFFFF);
    final primary = isDark ? const Color(0xFF2F8CFF) : AppColors.brand;
    final onSurface = isDark ? const Color(0xFFEEF4FF) : AppColors.brandNight;
    final line = isDark ? const Color(0xFF1A2A47) : const Color(0xFFE2E9F3);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: brightness,
      textTheme: MyAppTextTheme.textThemeFor(brightness).apply(fontFamily: fontFamily),
      primaryColor: primary,
      hintColor: isDark ? const Color(0xFF8D9BB5) : const Color(0xFF5B6B85),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      dividerColor: line,
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      canvasColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.sand,
        onSecondary: AppColors.sandInk,
        error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.25),
        selectionHandleColor: primary,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(primaryColor: primary, brightness: brightness),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.brandNight.withValues(alpha: 0.5),
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : line,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
