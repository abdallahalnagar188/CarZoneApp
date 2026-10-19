// Regression tests for bugs found in the QA review (docs/qa/QA_REPORT.md).
// They describe the CORRECT behaviour, so they fail until each bug is fixed.
import 'package:carzone/commons/models/order_model.dart';
import 'package:carzone/commons/models/offer_model.dart';
import 'package:carzone/core/services/pricing_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qa_helpers.dart';

void main() {
  // QA-H9: offers link to services through offer_categories, never service_ids,
  // so OfferModel.serviceIds is always empty and no discount is ever applied.
  test('QA-H9 a live offer row from Supabase discounts its branch services', () {
    final now = DateTime.now().toUtc();
    final row = <String, dynamic>{
      // Exact shape returned by: offers?select=*,offer_branches(branch_id)
      'id': 'of_deep',
      'scope': 'wash',
      'business_id': 'biz_carzen',
      'title': {'ar': 'خصم', 'en': 'Deal'},
      'description': {'ar': '', 'en': ''},
      'discount_type': 'percent',
      'discount_value': 15.0,
      'starts_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      'ends_at': now.add(const Duration(days: 1)).toIso8601String(),
      'status': 'active',
      'featured': false,
      'offer_branches': [
        {'branch_id': 'br_test'},
      ],
    };
    final db = freshDb();
    db.services.add(serviceFixture(id: 'svc_ext', price: 100));
    db.offers.add(OfferModel.fromJson(row));

    final q = PricingService().quote(branchId: 'br_test', primaryId: 'svc_ext');
    expect(q.discount, 15, reason: 'advertised 15% offer was not applied at checkout');
  });

  // QA-H10 (read side): the server returns UTC; the UI must show local time.
  test('QA-H10 order timestamps from the server are converted to local time', () {
    final o = OrderModel.fromJson({
      'id': 'ord_tz',
      'status': 'pending',
      'scheduled_at': '2030-01-01T08:00:00+00:00',
      'created_at': '2030-01-01T07:00:00+00:00',
      'order_events': [
        {'status': 'pending', 'at': '2030-01-01T07:00:00+00:00'},
      ],
    });
    expect(o.scheduledAt.isUtc, isFalse);
    expect(o.scheduledAt, DateTime.utc(2030, 1, 1, 8).toLocal());
    expect(o.timeline.single.key, 'pending', reason: 'order_events rows carry status, not key');
  });

  // QA-C4 is fixed on the server (next_order_number in create_order),
  // covered by qa/db/security_phase1.test.mjs.

  // QA-H7: complaint tickets are still numbered on the device, so every device starts at TK-501.
  test('QA-H7 two fresh devices never generate the same complaint ticket', () {
    final first = freshDb().nextTicket();
    final second = freshDb().nextTicket();
    expect(first, isNot(second), reason: 'both devices produced $first');
  });
}
