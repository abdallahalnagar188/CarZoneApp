// GAP-039: the Bookings tab pages through older orders.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup/commons/models/customer_model.dart';
import 'package:washup/core/services/session_service.dart';
import 'package:washup/features/bookings/presentaion/controllers/bookings_controller.dart';

import 'qa_helpers.dart';

void main() {
  tearDown(Get.reset);

  test('a guest has nothing to page through', () async {
    freshDb();
    Get.put(SessionService());
    final c = BookingsController();
    await c.loadMore();
    expect(c.loadingMore.value, isFalse);
  });

  test('a failed page keeps the list and lets the next scroll try again later', () async {
    final db = freshDb();
    final session = Get.put(SessionService());
    final me = CustomerModel(id: 'cu_1', name: 'x', phone: '+201000000000');
    db.customers.add(me);
    session.user.value = me;
    final c = BookingsController();
    // No Supabase in unit tests: the page request fails.
    await c.loadMore();
    expect(c.loadingMore.value, isFalse);
    expect(c.hasMore.value, isTrue);
  });
}
