import 'dart:developer' as dev;

import 'package:get/get.dart';

import '../network/api_call.dart';
import 'supabase_service.dart';

/// Support phone, email and hours shown on the help screen. They are managed
/// from the super admin (Platform settings ← General) and read through the
/// get_support_info() RPC; the defaults cover offline and older backends.
class SupportInfo {
  final String phone;
  final String email;
  final String? hoursAr;
  final String? hoursEn;

  const SupportInfo({required this.phone, required this.email, this.hoursAr, this.hoursEn});

  /// Nothing built in (GAP-040): no personal number or mailbox ships in the
  /// app. The help screen hides an empty phone or email; the company contact
  /// comes only from get_support_info() (super admin → Platform settings).
  static const fallback = SupportInfo(phone: '', email: '');

  bool get hasPhone => phone.isNotEmpty;
  bool get hasEmail => email.isNotEmpty;

  /// Hours in the app's language, or null to use the built-in text.
  String? get hours => Get.locale?.languageCode == 'en' ? (hoursEn ?? hoursAr) : (hoursAr ?? hoursEn);

  factory SupportInfo.fromJson(Map<String, dynamic> json) {
    String? text(Object? v) => (v is String && v.trim().isNotEmpty) ? v.trim() : null;
    final hours = json['hours'];
    return SupportInfo(
      phone: text(json['phone']) ?? fallback.phone,
      email: text(json['email']) ?? fallback.email,
      hoursAr: hours is Map ? text(hours['ar']) : text(hours),
      hoursEn: hours is Map ? text(hours['en']) : text(hours),
    );
  }

  static Future<SupportInfo> load() async {
    try {
      final res = await ApiCall.read(
        () => SupabaseService.client.rpc('get_support_info'),
        tag: 'get_support_info',
      );
      if (res is Map) return SupportInfo.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      dev.log('[SupportInfo] load error: $e');
    }
    return fallback;
  }
}
