// GAP-034: the price preview follows create_order's offer rule.
import 'package:flutter_test/flutter_test.dart';
import 'package:washup/commons/models/offer_model.dart';
import 'package:washup/core/enums/enums.dart';
import 'package:washup/core/services/pricing_service.dart';

import 'qa_helpers.dart';

OfferModel _offer(String id, {List<String> branches = const ['br_test'], List<String> categories = const [], num value = 10, bool platform = false}) {
  final now = DateTime.now().toUtc();
  return OfferModel.fromJson({
    'id': id,
    'scope': platform ? 'platform' : 'wash',
    'title': {'ar': 'x', 'en': 'x'},
    'description': {'ar': '', 'en': ''},
    'discount_type': 'percent',
    'discount_value': value,
    'starts_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'ends_at': now.add(const Duration(days: 1)).toIso8601String(),
    'status': 'active',
    'offer_branches': [for (final b in branches) {'branch_id': b}],
    'offer_categories': [for (final c in categories) {'category_id': c}],
  });
}

void main() {
  test('a platform offer with no branch link is not applied (create_order joins offer_branches)', () {
    final db = freshDb()..services.add(serviceFixture(id: 'svc_ext', price: 100));
    db.offers.add(_offer('platform', branches: const [], platform: true));
    expect(PricingService().quote(branchId: 'br_test', primaryId: 'svc_ext').discount, 0);
  });

  test('an offer limited to another category is not applied', () {
    final db = freshDb()
      ..services.addAll([
        serviceFixture(id: 'svc_ext', price: 100, category: 'exterior'),
        serviceFixture(id: 'svc_full', price: 200, category: 'full'),
      ]);
    db.offers.add(_offer('full_only', categories: const ['full']));
    expect(PricingService().quote(branchId: 'br_test', primaryId: 'svc_ext').discount, 0);
    expect(PricingService().quote(branchId: 'br_test', primaryId: 'svc_full').discount, 20);
  });

  test('add-ons never get an offer badge', () {
    final db = freshDb()..services.add(serviceFixture(id: 'svc_wax', type: ServiceType.addon, price: 40));
    db.offers.add(_offer('all'));
    expect(PricingService().offerFor('br_test', 'svc_wax'), isNull);
  });

  test('equal discounts pick the lowest offer id, like create_order', () {
    final db = freshDb()..services.add(serviceFixture(id: 'svc_ext', price: 100));
    db.offers.addAll([_offer('b_offer'), _offer('a_offer')]);
    expect(PricingService().offerFor('br_test', 'svc_ext')?.id, 'a_offer');
  });

  test('a quote_order answer replaces the local totals', () {
    final db = freshDb()..services.add(serviceFixture(id: 'svc_ext', price: 100));
    final pricing = PricingService();
    final local = pricing.quote(branchId: 'br_test', primaryId: 'svc_ext');
    final q = pricing.fromServer({'subtotal': 100, 'discount': 0, 'total': 100, 'offer_id': null, 'duration_min': 30}, local);
    expect(q.discount, 0);
    expect(q.total, 100);
    expect(q.items.length, 1);
    expect(db.offers, isEmpty);
  });
}
