import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool _isDark = false;

  static bool get isDark => _isDark;

  static void applyDark(bool value) {
    _isDark = value;
  }

  static const Color brand = Color(0xFF0B6BA8);
  static const Color brandDeep = Color(0xFF063E66);
  static const Color brandNight = Color(0xFF062A45);
  static const Color brandSky = Color(0xFF1FA2E0);
  static const Color glow = Color(0xFF7FE3FF);
  static const Color sand = Color(0xFFF8E7C9);
  static const Color sandInk = Color(0xFF7A5320);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static Color get primary =>
      _isDark ? const Color(0xFF4CC3F5) : const Color(0xFF0B6BA8);

  static Color get primaryDark =>
      _isDark ? const Color(0xFF7FE3FF) : const Color(0xFF08548A);

  static Color get primary500 =>
      _isDark ? const Color(0xFF2AA8E0) : const Color(0xFF1689C9);

  static Color get primarySoft =>
      _isDark ? const Color(0xFF0C2638) : const Color(0xFFE6F5FC);

  static Color get primarySoft2 =>
      _isDark ? const Color(0xFF11334A) : const Color(0xFFC4E7F8);

  static Color get accent => const Color(0xFF2CC6F2);

  static Color get secondary => sand;

  static Color get secondarySoft =>
      _isDark ? const Color(0xFF2A2216) : const Color(0xFFFDF6EA);

  static Color get secondaryStrong =>
      _isDark ? const Color(0xFFE8C48A) : const Color(0xFFD9A55A);

  static Color get bg =>
      _isDark ? const Color(0xFF03111C) : const Color(0xFFF5F8FB);

  static Color get surface =>
      _isDark ? const Color(0xFF0A1E2D) : const Color(0xFFFFFFFF);

  static Color get line =>
      _isDark ? const Color(0xFF17344A) : const Color(0xFFE1EBF2);

  static Color get ink900 =>
      _isDark ? const Color(0xFFEEF6FB) : const Color(0xFF0B1F2E);

  static Color get ink700 =>
      _isDark ? const Color(0xFFC9DCE8) : const Color(0xFF2C4456);

  static Color get ink500 =>
      _isDark ? const Color(0xFF8EA6B6) : const Color(0xFF5F7686);

  static Color get ink300 =>
      _isDark ? const Color(0xFF2F4757) : const Color(0xFFC3D3DE);

  static Color get blackText => ink900;

  static Color get grayText => ink500;

  static Color get hintGray => ink500.withValues(alpha: 0.8);

  static Color get success => const Color(0xFF16A34A);

  static Color get warning => const Color(0xFFF59E0B);

  static Color get danger => const Color(0xFFE5484D);

  static Color get info => const Color(0xFF0EA5E9);

  static Color get star => const Color(0xFFF5A524);

  static Color get statusPending => const Color(0xFFF59E0B);

  static Color get statusConfirmed =>
      _isDark ? const Color(0xFF4CC3F5) : const Color(0xFF1689C9);

  static Color get statusWaiting => const Color(0xFF7C5CFC);

  static Color get statusInService => const Color(0xFF0FB5A6);

  static Color get statusCompleted => const Color(0xFF16A34A);

  static Color get statusCancelled => const Color(0xFFE5484D);

  static Color get statusNoShow => const Color(0xFF64748B);

  static Color get scrim =>
      const Color(0xFF041828).withValues(alpha: _isDark ? 0.65 : 0.5);

  static Color get shadow => _isDark
      ? const Color(0xFF000000).withValues(alpha: 0.4)
      : brand.withValues(alpha: 0.08);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: _isDark
              ? Colors.black.withValues(alpha: 0.4)
              : brand.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get liftShadow => [
        BoxShadow(
          color: _isDark
              ? Colors.black.withValues(alpha: 0.45)
              : brand.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: _isDark
              ? accent.withValues(alpha: 0.35)
              : brand.withValues(alpha: 0.45),
          blurRadius: 22,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ];

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [brandSky, brand, brandDeep],
        stops: [0, 0.55, 1],
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
      );

  static LinearGradient get headerGradient => const LinearGradient(
        colors: [brandDeep, brand, Color(0xFF1484C4)],
        stops: [0, 0.45, 1],
        begin: AlignmentDirectional.centerEnd,
        end: AlignmentDirectional.centerStart,
      );

  static LinearGradient get heroGradient => const LinearGradient(
        colors: [Color(0xFF0F7BBD), brand, brandNight],
        stops: [0, 0.5, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get sandGradient => const LinearGradient(
        colors: [Color(0xFFFDF6EA), sand, Color(0xFFF1D5A6)],
        stops: [0, 0.6, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get dangerGradient => const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFE5484D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get disabledGradient => LinearGradient(
        colors: [ink300, ink300],
      );

  static LinearGradient get photoShade => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brandNight.withValues(alpha: 0.05),
          brandNight.withValues(alpha: 0.35),
          brandNight.withValues(alpha: 0.88),
        ],
        stops: const [0, 0.45, 1],
      );

  static Color tint(Color color, [double alpha = 0.12]) =>
      color.withValues(alpha: _isDark ? alpha + 0.06 : alpha);
}
