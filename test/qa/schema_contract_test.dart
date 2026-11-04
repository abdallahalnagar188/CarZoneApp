// Contract tests: every payload the app writes to Supabase must only use real
// columns and must include every required column, checked against
// supabase/database.types.ts. Regenerate that file whenever the schema changes.
import 'package:washup/commons/models/customer_model.dart';
import 'package:washup/commons/models/localized_text.dart';
import 'package:washup/commons/models/notification_model.dart';
import 'package:washup/commons/models/order_model.dart';
import 'package:washup/commons/models/review_model.dart';
import 'package:washup/commons/models/vehicle_model.dart';
import 'package:washup/core/enums/enums.dart';
import 'package:washup/core/services/order_service.dart';
import 'package:washup/core/services/washup_db_service.dart';
import 'package:get/get.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qa_helpers.dart';

void expectMatchesSchema(String table, Map<String, dynamic> payload) {
  final schema = schemaFor(table);
  final unknown = payload.keys.toSet().difference(schema.columns);
  final missing = schema.required.difference(payload.keys.toSet());
  expect(unknown, isEmpty, reason: '$table: app sends columns that do not exist: $unknown');
  expect(missing, isEmpty, reason: '$table: app omits required columns: $missing');
}

OrderModel _order() => OrderModel(
      id: 'ord_1',
      number: 'CZ-10001',
      code: 'ABCDE',
      customerId: 'cu_1',
      vehicleId: 'veh_1',
      branchId: 'br_nasr',
      items: const [],
      subtotal: 100,
      discount: 10,
      total: 90,
      durationMin: 30,
      scheduledAt: DateTime(2030, 1, 1, 10),
      status: OrderStatus.pending,
      createdAt: DateTime(2030, 1, 1, 9),
    );

void main() {
  test('schema parser reads the generated types', () {
    expect(schemaFor('orders').columns, contains('scheduled_at'));
    expect(schemaFor('orders').required, contains('branch_id'));
  });

  // orders / order_items / order_events are written only by the create_order,
  // cancel_order and reschedule_order RPCs; see qa/db/security_phase1.test.mjs.

  test('vehicles: VehicleModel.toJson matches schema', () {
    final v = VehicleModel(id: 'veh_1', customerId: 'cu_1', make: 'Kia', model: 'Rio', color: 'white', plate: 'ABC 123');
    expectMatchesSchema('vehicles', v.toJson());
  });

  test('customers: CustomerModel.toJson matches schema', () {
    final json = CustomerModel(id: 'cu_1', name: 'QA', phone: '+201000000000').toJson();
    final unknown = json.keys.toSet().difference(schemaFor('customers').columns);
    expect(unknown, isEmpty, reason: 'customers: unknown columns $unknown');
  });

  test('customer_notifications: NotificationModel.toJson matches schema', () {
    final n = NotificationModel(
      id: 'nt_1',
      userId: 'cu_1',
      type: 'created',
      title: const LocalizedText('a', 'b'),
      body: const LocalizedText('a', 'b'),
      createdAt: DateTime(2030),
    );
    expectMatchesSchema('customer_notifications', n.toJson());
  });

  // QA-H6: reviews are never saved (unknown columns + missing business_id/customer_id).
  test('reviews: ReviewModel.toJson matches schema', () {
    final r = ReviewModel(
      id: 'rv_1',
      orderId: 'ord_1',
      customerName: 'QA',
      branchId: 'br_nasr',
      serviceName: const LocalizedText('a', 'b'),
      stars: 5,
      comment: 'ok',
      createdAt: DateTime(2030),
    );
    expectMatchesSchema('reviews', r.toJson());
  });

  // QA-H7: complaints are never saved (ticket_number/reason/details are not columns).
  test('complaints: OrderService.report payload matches schema', () async {
    Get.reset();
    final db = Get.put<WashUpDbService>(_ComplaintDb());
    final order = _order();
    db.orders.add(order);
    final ticket = await OrderService().report(order, 'quality', 'bad wash');
    expectMatchesSchema('complaints', Map<String, dynamic>.from(db.complaints.single));
    // The ticket shown is the one the database gave, not one made on the phone.
    expect(ticket, 'TK-1041');
    expect((db as _ComplaintDb).sent!.containsKey('ticket'), isFalse);
  });
}

/// Answers the complaint insert like the database: it numbers the ticket.
class _ComplaintDb extends WashUpDbService {
  Map<String, dynamic>? sent;

  @override
  Future<String> insertComplaint(Map<String, dynamic> complaint) async {
    sent = complaint;
    return 'TK-1041';
  }
}
