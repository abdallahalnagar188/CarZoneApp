// GAP-015: the notification history loaded at launch must never roll a
// cached order back to an older status.
import 'package:flutter_test/flutter_test.dart';
import 'package:washup/commons/models/localized_text.dart';
import 'package:washup/commons/models/notification_model.dart';
import 'package:washup/commons/models/order_model.dart';
import 'package:washup/core/enums/enums.dart';
import 'package:washup/core/services/live_booking_service.dart';

NotificationModel _notif(String id, String type, DateTime at) => NotificationModel(
      id: id,
      userId: 'cu_1',
      type: type,
      title: const LocalizedText('x', 'x'),
      body: const LocalizedText('x', 'x'),
      orderId: 'ord_1',
      createdAt: at,
    );

void main() {
  final t0 = DateTime.utc(2030, 1, 1, 8);

  OrderModel completedOrder() => OrderModel.fromJson({
        'id': 'ord_1',
        'status': 'completed',
        'scheduled_at': t0.toIso8601String(),
        'created_at': t0.toIso8601String(),
        'updated_at': t0.add(const Duration(minutes: 40)).toIso8601String(),
        'order_events': [
          {'status': 'pending', 'at': t0.toIso8601String()},
          {'status': 'confirmed', 'at': t0.add(const Duration(minutes: 5)).toIso8601String()},
          {'status': 'waiting', 'at': t0.add(const Duration(minutes: 10)).toIso8601String()},
          {'status': 'in_service', 'at': t0.add(const Duration(minutes: 15)).toIso8601String()},
          {'status': 'completed', 'at': t0.add(const Duration(minutes: 40)).toIso8601String()},
        ],
      });

  test('a completed order with 5 older notifications stays completed', () {
    final order = completedOrder();
    final history = [
      _notif('n1', 'created', t0),
      _notif('n2', 'confirmed', t0.add(const Duration(minutes: 5))),
      _notif('n3', 'waiting', t0.add(const Duration(minutes: 10))),
      _notif('n4', 'in_service', t0.add(const Duration(minutes: 15))),
      _notif('n5', 'completed', t0.add(const Duration(minutes: 40))),
    ];
    for (final n in history) {
      expect(LiveBookingService.statusFromNotification(order, n), isNull, reason: n.type);
    }
    expect(order.status, OrderStatus.completed);
  });

  test('a notification newer than the cached order moves it on', () {
    final order = OrderModel.fromJson({
      'id': 'ord_1',
      'status': 'pending',
      'scheduled_at': t0.toIso8601String(),
      'created_at': t0.toIso8601String(),
      'updated_at': t0.toIso8601String(),
      'order_events': [
        {'status': 'pending', 'at': t0.toIso8601String()},
      ],
    });
    final n = _notif('n2', 'confirmed', t0.add(const Duration(minutes: 3)));
    expect(LiveBookingService.statusFromNotification(order, n), OrderStatus.confirmed);
  });

  test('non-status notifications are ignored', () {
    final order = completedOrder();
    final n = _notif('n9', 'review_reminder', t0.add(const Duration(days: 1)));
    expect(LiveBookingService.statusFromNotification(order, n), isNull);
  });

  test('last known change is the latest of updated_at and the timeline', () {
    final order = completedOrder();
    expect(LiveBookingService.lastKnownChange(order).toUtc(), t0.add(const Duration(minutes: 40)));
  });
}
