import 'dart:math' as math;

import 'package:get/get.dart';

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

  static String money(num amount) {
    final n = amount.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
    return isAr ? '$n ج.م' : '$n EGP';
  }

  static String time(DateTime d) {
    final pm = d.hour >= 12;
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return isAr ? '$h:$m ${pm ? 'م' : 'ص'}' : '$h:$m ${pm ? 'PM' : 'AM'}';
  }

  static String dayName(DateTime d) =>
      isAr ? _arDays[d.weekday - 1] : _enDays[d.weekday - 1];

  static String date(DateTime d) {
    final month = isAr ? _arMonths[d.month - 1] : _enMonths[d.month - 1];
    return '${dayName(d)} ${d.day} $month';
  }

  static String shortDate(DateTime d) {
    final month = isAr ? _arMonths[d.month - 1] : _enMonths[d.month - 1];
    return '${d.day} $month';
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

  static String normalizePlate(String plate) =>
      plate.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

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

  static String? parseEgPhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('20') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!RegExp(r'^1[0125]\d{8}$').hasMatch(digits)) return null;
    return '+20 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }
}
