import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'text_theme.dart';

class MyAppTheme {
  MyAppTheme._();

  static const String fontFamily = 'IPM';

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF03111C) : const Color(0xFFF5F8FB);
    final surface = isDark ? const Color(0xFF0A1E2D) : const Color(0xFFFFFFFF);
    final primary = isDark ? const Color(0xFF4CC3F5) : const Color(0xFF0075C4);
    final onSurface = isDark ? const Color(0xFFEEF6FB) : const Color(0xFF0B1F2E);
    final line = isDark ? const Color(0xFF17344A) : const Color(0xFFE1EBF2);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: brightness,
      textTheme: MyAppTextTheme.textThemeFor(brightness).apply(fontFamily: fontFamily),
      primaryColor: primary,
      hintColor: isDark ? const Color(0xFF8EA6B6) : const Color(0xFF5F7686),
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
        secondary: const Color(0xFFDDF3FD),
        onSecondary: const Color(0xFF03477E),
        error: const Color(0xFFE5484D),
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
        modalBarrierColor: const Color(0xFF041828).withValues(alpha: 0.5),
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
