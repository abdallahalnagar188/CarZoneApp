// GAP-017: money from the numeric columns keeps its decimals end to end.
import 'package:flutter_test/flutter_test.dart';
import 'package:washup/commons/models/offer_model.dart';
import 'package:washup/commons/models/order_model.dart';
import 'package:washup/commons/models/wash_service_model.dart';
import 'package:washup/core/enums/enums.dart';
import 'package:washup/core/helpers/format_helper.dart';
import 'package:washup/core/services/pricing_service.dart';

import 'qa_helpers.dart';

OfferModel _offer(Map<String, dynamic> extra) {
  final now = DateTime.now().toUtc();
  return OfferModel.fromJson({
    'id': 'of_1',
    'title': {'ar': 'x', 'en': 'x'},
    'description': {'ar': '', 'en': ''},
    'starts_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'ends_at': now.add(const Duration(days: 1)).toIso8601String(),
    'status': 'active',
    'offer_branches': [
      {'branch_id': 'br_test'},
    ],
    ...extra,
  });
}

void main() {
  test('service, item and order money keep their decimals', () {
    expect(WashServiceModel.fromJson({'id': 's', 'price': 2.75}).price, 2.75);
    final order = OrderModel.fromJson({
      'id': 'o',
      'status': 'pending',
      'subtotal': 3.5,
      'discount_amount': 0.25,
      'total': 3.25,
      'order_items': [
        {'service_id': 's', 'name': {'ar': 'x', 'en': 'x'}, 'type': 'primary', 'price': 2.75, 'duration_min': 30},
        {'service_id': 'a', 'name': {'ar': 'x', 'en': 'x'}, 'type': 'addon', 'price': 0.75, 'duration_min': 10},
      ],
    });
    expect(order.subtotal, 3.5);
    expect(order.discount, 0.25);
    expect(order.total, 3.25);
    expect(order.items.first.price, 2.75);
  });

  test('a missing discount is zero', () {
    expect(OrderModel.fromJson({'id': 'o', 'status': 'pending'}).discount, 0);
  });

  test('a decimal quote is not truncated', () {
    final db = freshDb();
    db.services.addAll([
      WashServiceModel.fromJson({'id': 'svc_p', 'branch_id': 'br_test', 'type': 'primary', 'price': 2.75}),
      WashServiceModel.fromJson({'id': 'svc_a', 'branch_id': 'br_test', 'type': 'addon', 'price': 0.5}),
    ]);
    final q = PricingService().quote(branchId: 'br_test', primaryId: 'svc_p', addonIds: ['svc_a']);
    expect(q.subtotal, 3.25);
    expect(q.total, 3.25);
  });

  test('fixed discounts keep decimals and never exceed the price', () {
    final fixed = _offer({'discount_type': 'fixed', 'discount_value': 0.5});
    expect(fixed.discountType, DiscountType.fixed);
    expect(fixed.discountFor(2.75), 0.5);
    expect(fixed.discountFor(0.25), 0.25);
  });

  test('percent discounts round like create_order', () {
    final percent = _offer({'discount_type': 'percent', 'discount_value': 15.0});
    expect(percent.discountFor(100), 15);
    expect(percent.discountFor(250), 38); // round(37.5) = 38
    expect(percent.badge, '15%');
  });

  test('decimal amounts are shown with the currency decimals', () {
    // No services registered: the default (Egypt, 2 decimals) country is used.
    expect(FormatHelper.money(2.5), contains('2.50'));
    expect(FormatHelper.money(150.0), startsWith('150 '));
  });
}
