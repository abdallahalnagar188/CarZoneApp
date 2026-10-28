import 'package:carzone/core/services/support_info_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() => Get.locale = null);

  test('reads phone, email and hours from get_support_info', () {
    final info = SupportInfo.fromJson({
      'phone': ' +20 100 000 0000 ',
      'email': 'support@washup.app',
      'hours': {'ar': 'يوميًا ٩ص – ٩م', 'en': 'Daily 9 AM – 9 PM'},
    });
    expect(info.phone, '+20 100 000 0000');
    expect(info.email, 'support@washup.app');

    Get.locale = const Locale('ar');
    expect(info.hours, 'يوميًا ٩ص – ٩م');
    Get.locale = const Locale('en');
    expect(info.hours, 'Daily 9 AM – 9 PM');
  });

  test('missing or blank values fall back to the built-in contact', () {
    final info = SupportInfo.fromJson({'phone': '  ', 'email': null, 'hours': null});
    expect(info.phone, SupportInfo.fallback.phone);
    expect(info.email, SupportInfo.fallback.email);
    expect(info.hours, isNull);
  });

  test('plain string hours are used for both languages', () {
    final info = SupportInfo.fromJson({'hours': '24/7'});
    Get.locale = const Locale('en');
    expect(info.hours, '24/7');
  });
}
