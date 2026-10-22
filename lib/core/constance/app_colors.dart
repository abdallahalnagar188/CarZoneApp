import 'package:flutter/material.dart';

/// Wash Up palette. Brand hues are sampled from the logo (assets/logo):
/// the ribbon runs cyan -> bright blue -> royal, the wordmark is navy "WASH"
/// with a bright blue "UP". Text colors are tuned to WCAG AA on bg/surface.
class AppColors {
  AppColors._();

  static bool _isDark = false;

  static bool get isDark => _isDark;

  static void applyDark(bool value) {
    _isDark = value;
  }

  /// Primary action blue: the logo's bright blue deepened just enough to carry
  /// white text at AA (4.7:1).
  static const Color brand = Color(0xFF0070E8);

  /// Royal half of the ribbon.
  static const Color brandDeep = Color(0xFF01398C);

  /// Navy of the "WASH" wordmark; the brand's text color.
  static const Color brandNight = Color(0xFF01193A);

  /// Bright blue of "UP".
  static const Color brandSky = Color(0xFF0396FB);

  /// Cyan highlight at the start of the ribbon.
  static const Color brandCyan = Color(0xFF01BDFE);

  static const Color glow = Color(0xFF6FD3FF);
  static const Color sand = Color(0xFFE4F1FF);
  static const Color sandInk = Color(0xFF01398C);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static Color get primary =>
      _isDark ? const Color(0xFF2F8CFF) : brand;

  static Color get primaryDark =>
      _isDark ? const Color(0xFF6FB4FF) : const Color(0xFF0055B8);

  static Color get primary500 =>
      _isDark ? const Color(0xFF4DA3FF) : brandSky;

  static Color get primarySoft =>
      _isDark ? const Color(0xFF0D2142) : const Color(0xFFE8F2FF);

  static Color get primarySoft2 =>
      _isDark ? const Color(0xFF133060) : const Color(0xFFCCE3FF);

  static Color get accent => brandCyan;

  static Color get secondary => sand;

  static Color get secondarySoft =>
      _isDark ? const Color(0xFF0C1F3D) : const Color(0xFFF0F7FF);

  /// Text and icons on [secondarySoft] (sandInk stays fixed for the always-light [sand]).
  static Color get secondaryInk =>
      _isDark ? const Color(0xFF9CCBFF) : sandInk;

  static Color get secondaryStrong =>
      _isDark ? const Color(0xFF6FD3FF) : brandSky;

  static Color get bg =>
      _isDark ? const Color(0xFF020B1A) : const Color(0xFFF5F8FC);

  static Color get surface =>
      _isDark ? const Color(0xFF0A1830) : const Color(0xFFFFFFFF);

  static Color get line =>
      _isDark ? const Color(0xFF1A2A47) : const Color(0xFFE2E9F3);

  static Color get ink900 =>
      _isDark ? const Color(0xFFEEF4FF) : brandNight;

  static Color get ink700 =>
      _isDark ? const Color(0xFFC8D4EA) : const Color(0xFF2A3B5C);

  static Color get ink500 =>
      _isDark ? const Color(0xFF8D9BB5) : const Color(0xFF5B6B85);

  static Color get ink300 =>
      _isDark ? const Color(0xFF2C3D5E) : const Color(0xFFC5D0E0);

  static Color get blackText => ink900;

  static Color get grayText => ink500;

  static Color get hintGray => ink500.withValues(alpha: 0.8);

  // State colors are dark enough for text on white in light mode and lifted
  // for dark surfaces; all clear AA for text.
  static Color get success =>
      _isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);

  static Color get warning =>
      _isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  static Color get danger =>
      _isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

  static Color get info =>
      _isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);

  static Color get star => const Color(0xFFF5A524);

  static Color get statusPending => warning;

  static Color get statusConfirmed =>
      _isDark ? const Color(0xFF6FB4FF) : brand;

  static Color get statusWaiting =>
      _isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);

  static Color get statusInService =>
      _isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

  static Color get statusCompleted => success;

  static Color get statusCancelled => danger;

  static Color get statusNoShow =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  static Color get scrim =>
      brandNight.withValues(alpha: _isDark ? 0.7 : 0.5);

  static Color get shadow => _isDark
      ? const Color(0xFF000000).withValues(alpha: 0.4)
      : brandNight.withValues(alpha: 0.08);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: _isDark
              ? Colors.black.withValues(alpha: 0.4)
              : brandNight.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get liftShadow => [
        BoxShadow(
          color: _isDark
              ? Colors.black.withValues(alpha: 0.45)
              : brandNight.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: _isDark
              ? brand.withValues(alpha: 0.35)
              : brand.withValues(alpha: 0.4),
          blurRadius: 22,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ];

  /// Buttons and selected states; white text sits on the [brand] middle.
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [brandSky, brand, brandDeep],
        stops: [0, 0.55, 1],
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
      );

  /// The logo ribbon itself, for decorative accents that carry no text.
  static LinearGradient get ribbonGradient => const LinearGradient(
        colors: [brandCyan, Color(0xFF0182FD), brandDeep],
        stops: [0, 0.5, 1],
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
      );

  static LinearGradient get headerGradient => const LinearGradient(
        colors: [brandDeep, brand, brandSky],
        stops: [0, 0.5, 1],
        begin: AlignmentDirectional.centerEnd,
        end: AlignmentDirectional.centerStart,
      );

  /// Deep end on the reading side so hero text keeps its contrast in both
  /// RTL and LTR.
  static LinearGradient get heroGradient => const LinearGradient(
        colors: [brandSky, brand, brandNight],
        stops: [0, 0.5, 1],
        begin: AlignmentDirectional.topEnd,
        end: AlignmentDirectional.bottomStart,
      );

  static LinearGradient get sandGradient => const LinearGradient(
        colors: [Color(0xFFF0F7FF), sand, Color(0xFFCFE5FF)],
        stops: [0, 0.6, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get dangerGradient => const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
