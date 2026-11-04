import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup/commons/models/area_model.dart';
import 'package:washup/commons/models/country_model.dart';
import 'package:washup/commons/models/localized_text.dart';
import 'package:washup/core/helpers/format_helper.dart';

import 'qa_helpers.dart';

void main() {
  setUp(() {
    Get.locale = const Locale('en');
    final db = freshDb();
    db.countries.add(const CountryModel(
      code: 'AE',
      name: LocalizedText('الإمارات', 'UAE'),
      currency: 'AED',
      currencySymbol: LocalizedText('د.إ', 'AED'),
      currencyDecimals: 2,
      timezone: 'Asia/Dubai',
      lat: 25.2,
      lng: 55.27,
    ));
    db.areas.add(const AreaModel(id: 'dxb', name: LocalizedText('دبي', 'Dubai'), countryCode: 'AE'));
    db.branches.add(branchFixture(id: 'br_dxb', areaId: 'dxb'));
  });

  test('a booking shows the branch clock whatever the phone zone', () {
    // 08:00 UTC is 12:00 in Dubai; the order model keeps it as a local DateTime.
    final at = DateTime.utc(2026, 11, 3, 8).toLocal();
    expect(FormatHelper.time(at, branchId: 'br_dxb'), '12:00 PM');
    expect(FormatHelper.date(at, branchId: 'br_dxb'), 'Tue 3 Nov');
  });

  test('a slot picked in the branch day is printed as it is', () {
    expect(FormatHelper.time(DateTime(2026, 11, 3, 9, 30)), '9:30 AM');
  });
}
