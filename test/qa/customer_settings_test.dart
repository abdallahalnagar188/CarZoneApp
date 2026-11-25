// GAP-036: language and push settings are kept on the customer row.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup/commons/models/customer_model.dart';
import 'package:washup/core/services/session_service.dart';

import 'qa_helpers.dart';

void main() {
  test('push settings are read from the customer row, null when the columns are missing', () {
    final withPrefs = CustomerModel.fromJson({'id': 'cu_1', 'notify_reminders': false, 'notify_offers': true, 'locale': 'en'});
    expect(withPrefs.notifyReminders, isFalse);
    expect(withPrefs.notifyOffers, isTrue);
    expect(withPrefs.locale, 'en');
    final older = CustomerModel.fromJson({'id': 'cu_1'});
    expect(older.notifyReminders, isNull);
    expect(older.notifyOffers, isNull);
  });

  test('a setting the server did not save is reported and not applied', () async {
    freshDb();
    final session = Get.put(SessionService());
    final me = CustomerModel(id: 'cu_1', name: 'x', phone: '+201000000000', locale: 'ar');
    session.user.value = me;
    // No Supabase in unit tests: the update fails.
    expect(await session.saveCustomerSettings({'locale': 'en', 'notify_offers': false}), isFalse);
    expect(me.locale, 'ar');
    expect(me.notifyOffers, isNull);
    Get.reset();
  });

  test('signed out: nothing is sent', () async {
    freshDb();
    final session = Get.put(SessionService());
    expect(await session.saveCustomerSettings({'locale': 'en'}), isFalse);
    Get.reset();
  });
}
