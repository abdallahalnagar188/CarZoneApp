import 'package:carzone/commons/models/localized_text.dart';
import 'package:carzone/commons/models/offer_model.dart';
import 'package:carzone/core/enums/enums.dart';
import 'package:carzone/core/services/pricing_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qa_helpers.dart';

OfferModel _offer({
  String id = 'of_test',
  List<String> branches = const ['br_test'],
  List<String> services = const ['svc_ext'],
  DiscountType type = DiscountType.percent,
  int value = 10,
  String status = 'active',
  Duration startAgo = const Duration(days: 1),
  Duration endIn = const Duration(days: 1),
}) {
  final now = DateTime.now();
  return OfferModel(
    id: id,
    platform: false,
    branchIds: branches,
    serviceIds: services,
    title: const LocalizedText('x', 'x'),
    description: const LocalizedText('x', 'x'),
    discountType: type,
    discountValue: value,
    startAt: now.subtract(startAgo),
    endAt: now.add(endIn),
    status: status,
  );
}

void main() {
  late PricingService pricing;

  setUp(() {
    final db = freshDb();
    db.services.addAll([
      serviceFixture(id: 'svc_ext', price: 100, durationMin: 30),
      serviceFixture(id: 'svc_full', price: 250, durationMin: 60, category: 'full'),
      serviceFixture(id: 'svc_wax', type: ServiceType.addon, price: 40, durationMin: 15),
    ]);
    pricing = PricingService();
  });

  test('quote sums primary + add-ons for price and duration', () {
    final q = pricing.quote(branchId: 'br_test', primaryId: 'svc_ext', addonIds: ['svc_wax']);
    expect(q.subtotal, 140);
    expect(q.durationMin, 45);
    expect(q.discount, 0);
    expect(q.total, 140);
    expect(q.items.map((i) => i.serviceId), ['svc_ext', 'svc_wax']);
  });

  test('missing primary gives an empty quote instead of crashing', () {
    expect(pricing.quote(branchId: 'br_test', primaryId: null).total, 0);
    expect(pricing.quote(branchId: 'br_test', primaryId: 'nope').total, 0);
  });

  test('percent offer discounts the primary service only', () {
    freshDbWith(offers: [_offer(value: 10)]);
    final q = PricingService().quote(branchId: 'br_test', primaryId: 'svc_ext', addonIds: ['svc_wax']);
    expect(q.discount, 10); // 10% of 100, add-on excluded
    expect(q.total, 130);
  });

  test('fixed offer never exceeds the service price', () {
    freshDbWith(offers: [_offer(type: DiscountType.fixed, value: 500)]);
    final q = PricingService().quote(branchId: 'br_test', primaryId: 'svc_ext');
    expect(q.discount, 100);
    expect(q.total, 0);
  });

  test('best offer wins when several apply', () {
    freshDbWith(offers: [
      _offer(id: 'a', value: 10),
      _offer(id: 'b', type: DiscountType.fixed, value: 30),
    ]);
    expect(PricingService().quote(branchId: 'br_test', primaryId: 'svc_ext').offer?.id, 'b');
  });

  test('expired, future, disabled and other-branch offers are ignored', () {
    freshDbWith(offers: [
      _offer(id: 'expired', startAgo: const Duration(days: 3), endIn: const Duration(days: -1)),
      _offer(id: 'future', startAgo: const Duration(days: -1), endIn: const Duration(days: 3)),
      _offer(id: 'disabled', status: 'disabled'),
      _offer(id: 'other', branches: const ['br_other']),
    ]);
    expect(PricingService().quote(branchId: 'br_test', primaryId: 'svc_ext').discount, 0);
  });

  test('fromPrice returns the cheapest active primary service', () {
    expect(pricing.fromPrice('br_test'), 100);
    expect(pricing.fromPrice('br_test', category: 'full'), 250);
    expect(pricing.fromPrice('br_empty'), isNull);
  });
}

void freshDbWith({List<OfferModel> offers = const []}) {
  final db = freshDb();
  db.services.addAll([
    serviceFixture(id: 'svc_ext', price: 100, durationMin: 30),
    serviceFixture(id: 'svc_wax', type: ServiceType.addon, price: 40, durationMin: 15),
  ]);
  db.offers.addAll(offers);
}
