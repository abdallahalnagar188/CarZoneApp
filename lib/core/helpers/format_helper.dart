import 'dart:math' as math;

import 'package:get/get.dart';

import '../../commons/models/country_model.dart';
import '../services/availability_service.dart';
import '../services/session_service.dart';
import '../services/washup_db_service.dart';

class FormatHelper {
  FormatHelper._();

  static const _arMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const _enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _arDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];
  static const _enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static bool get isAr => (Get.locale?.languageCode ?? 'ar') == 'ar';

  /// [amount] in the currency of [branchId]'s country, or of the country
  /// being browsed when there is no branch. Whole amounts drop the decimals;
  /// others keep as many as the currency has (3 for the Kuwaiti dinar).
  static String money(num amount, {String? branchId}) {
    final db = Get.isRegistered<WashUpDbService>() ? Get.find<WashUpDbService>() : null;
    final country = branchId != null && db != null
        ? db.countryOfBranch(branchId)
        : Get.isRegistered<SessionService>()
            ? Get.find<SessionService>().country
            : CountryModel.egypt;
    final whole = amount == amount.roundToDouble();
    final fixed = whole ? amount.round().toString() : amount.toStringAsFixed(math.max(country.currencyDecimals, 1));
    final parts = fixed.split('.');
    final n = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    final text = parts.length > 1 ? '$n.${parts[1]}' : n;
    return '$text ${country.currencySymbol.value}';
  }

  static String time(DateTime d, {String? timezone}) {
    final local = d.isUtc ? d.add(BranchTimeHelper.offsetFor(timezone, d)) : d;
    final pm = local.hour >= 12;
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return isAr ? '$h:$m ${pm ? 'م' : 'ص'}' : '$h:$m ${pm ? 'PM' : 'AM'}';
  }

  static String dayName(DateTime d, {String? timezone}) {
    final local = d.isUtc ? d.add(BranchTimeHelper.offsetFor(timezone, d)) : d;
    return isAr ? _arDays[local.weekday - 1] : _enDays[local.weekday - 1];
  }

  static String date(DateTime d, {String? timezone}) {
    final local = d.isUtc ? d.add(BranchTimeHelper.offsetFor(timezone, d)) : d;
    final month = isAr ? _arMonths[local.month - 1] : _enMonths[local.month - 1];
    return '${dayName(local)} ${local.day} $month';
  }

  static String shortDate(DateTime d, {String? timezone}) {
    final local = d.isUtc ? d.add(BranchTimeHelper.offsetFor(timezone, d)) : d;
    final month = isAr ? _arMonths[local.month - 1] : _enMonths[local.month - 1];
    return '${local.day} $month';
  }

  static String dateTime(DateTime d) => '${date(d)} · ${time(d)}';

  static String distance(double km) {
    final n = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return isAr ? '$n كم' : '$n km';
  }

  static String minutes(int mins) => isAr ? '$mins د' : '$mins min';

  static String relativeDay(DateTime d, [DateTime? now]) {
    final ref = now ?? DateTime.now();
    final a = DateTime(ref.year, ref.month, ref.day);
    final b = DateTime(d.year, d.month, d.day);
    final days = a.difference(b).inDays;
    if (days == 0) return isAr ? 'اليوم' : 'Today';
    if (days == 1) return isAr ? 'أمس' : 'Yesterday';
    if (days == -1) return isAr ? 'غدًا' : 'Tomorrow';
    if (days > 1) return isAr ? 'منذ $days يوم' : '$days days ago';
    return isAr ? 'بعد ${days.abs()} يوم' : 'in ${days.abs()} days';
  }

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    final value = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return value.isEmpty ? '؟' : value;
  }

  /// Arabic-Indic (٠١٢) and Persian (۰۱۲) digits as 0-9: an Arabic keyboard
  /// types those, and plates and years are compared and stored with 0-9.
  static String latinDigits(String text) => text.replaceAllMapped(
        RegExp('[\u0660-\u0669\u06F0-\u06F9]'),
        (m) => String.fromCharCode(48 + (m[0]!.codeUnitAt(0) & 0xF)),
      );

  /// One spelling per plate, for comparing and searching: 0-9 digits, no
  /// spaces or dashes, and the Arabic letter forms people mix up made the same.
  static String normalizePlate(String plate) => latinDigits(plate)
      .toUpperCase()
      .replaceAll(RegExp(r'[\s\-_.]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');

  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final s = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(s));
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int clockToMinutes(String hhmm) {
    final parts = hhmm.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }
}
