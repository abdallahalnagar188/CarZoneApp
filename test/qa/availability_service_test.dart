import 'package:carzone/commons/models/branch_model.dart';
import 'package:carzone/commons/models/order_model.dart';
import 'package:carzone/core/enums/enums.dart';
import 'package:carzone/core/services/availability_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qa_helpers.dart';

OrderModel _order(String id, String branchId, DateTime at, {int mins = 30, OrderStatus status = OrderStatus.confirmed}) {
  return OrderModel(
    id: id,
    number: 'CZ-$id',
    code: 'AAAAA',
    customerId: 'cu_test',
    vehicleId: 'veh_test',
    branchId: branchId,
    items: const [],
    subtotal: 100,
    discount: 0,
    total: 100,
    durationMin: mins,
    scheduledAt: at,
    status: status,
    createdAt: DateTime.now(),
  );
}

void main() {
  late AvailabilityService svc;

  setUp(() {
    freshDb();
    svc = AvailabilityService();
  });

  test('09:00-12:00 with 30 min interval gives 6 slots for a 30 min service', () {
    final slots = svc.slotsFor(branchFixture(), futureDay(), durationMin: 30);
    expect(slots.length, 6);
    expect(slots.first.start.hour, 9);
    expect(slots.last.start.hour, 11);
    expect(slots.last.start.minute, 30);
  });

  test('a long service does not get a slot that runs past closing time', () {
    final slots = svc.slotsFor(branchFixture(), futureDay(), durationMin: 90);
    final lastEnd = slots.last.start.add(const Duration(minutes: 90));
    expect(lastEnd.hour <= 12 && (lastEnd.hour < 12 || lastEnd.minute == 0), isTrue);
  });

  test('closed day has no slots', () {
    final day = futureDay();
    final hours = List.generate(7, (i) => i == day.weekday % 7 ? const WorkingDay('09:00', '12:00', closed: true) : const WorkingDay('09:00', '12:00'));
    expect(svc.slotsFor(branchFixture(hours: hours), day), isEmpty);
  });

  test('inactive branch or suspended business is not bookable', () {
    expect(svc.slotsFor(branchFixture(active: false), futureDay()), isEmpty);
    expect(svc.slotsFor(branchFixture(businessActive: false), futureDay()), isEmpty);
  });

  test('capacity is consumed by overlapping active orders only', () {
    final db = freshDb();
    final b = branchFixture(capacity: 2);
    db.branches.add(b);
    final nine = futureDay().add(const Duration(hours: 9));
    db.orders.addAll([
      _order('1', b.id, nine),
      _order('2', b.id, nine, status: OrderStatus.cancelled), // ignored
      _order('3', 'br_other', nine), // other branch, ignored
    ]);
    final slot9 = svc.slotsFor(b, futureDay()).firstWhere((s) => s.start == nine);
    expect(slot9.free, 1);
    expect(slot9.fewLeft, isTrue);

    db.orders.add(_order('4', b.id, nine));
    expect(svc.slotsFor(b, futureDay()).any((s) => s.start == nine), isFalse, reason: 'full slot must disappear');
    expect(svc.isAvailable(b, nine, 30, excludeOrderId: '4'), isTrue, reason: 'rescheduling own order frees its seat');
  });

  test('lead time hides slots that start too soon', () {
    final now = DateTime.now();
    final b = branchFixture(
      hours: List.generate(7, (_) => const WorkingDay('00:00', '23:59')),
      settings: const BranchSettings(slotIntervalMin: 30, leadTimeMin: 120, maxAdvanceDays: 7),
    );
    final today = DateTime(now.year, now.month, now.day);
    final slots = svc.slotsFor(b, today);
    expect(slots.every((s) => !s.start.isBefore(now.add(const Duration(minutes: 120)))), isTrue);
  });

  test('isOpenNow respects working hours', () {
    final b = branchFixture(hours: List.generate(7, (_) => const WorkingDay('09:00', '12:00')));
    final d = futureDay();
    expect(svc.isOpenNow(b, d.add(const Duration(hours: 10))), isTrue);
    expect(svc.isOpenNow(b, d.add(const Duration(hours: 12))), isFalse);
    expect(svc.isOpenNow(b, d.add(const Duration(hours: 8, minutes: 59))), isFalse);
  });
}
