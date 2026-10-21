import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../commons/models/localized_text.dart';
import '../../commons/models/order_model.dart';
import '../../commons/models/review_model.dart';
import '../enums/enums.dart';
import 'availability_service.dart';
import 'carzone_db_service.dart';
import 'supabase_service.dart';

class SlotTakenException implements Exception {}
class SlotTooSoonException implements Exception {}
class SlotOutsideHoursException implements Exception {}

/// A booking RPC refused the request. [code] is the server's reason,
/// e.g. `branch_unavailable`, `order_not_cancellable` (see migration 20261019120000).
class BookingException implements Exception {
  final String code;

  const BookingException(this.code);

  @override
  String toString() => 'BookingException($code)';
}

class OrderService {
  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  static const _toasts = {
    OrderStatus.confirmed: LocalizedText('تم تأكيد حجزك', 'Your booking is confirmed'),
    OrderStatus.waiting: LocalizedText('تم تسجيل وصولك', 'You have checked in'),
    OrderStatus.inService: LocalizedText('بدأ تنفيذ الخدمة', 'Service started'),
    OrderStatus.completed: LocalizedText('اكتملت الخدمة', 'Service completed'),
    OrderStatus.cancelled: LocalizedText('تم إلغاء الحجز', 'Booking cancelled'),
  };

  /// Orders are written only by server RPCs, which price, number and validate
  /// the booking. Slot errors become [SlotTakenException], the rest [BookingException].
  Future<Map<String, dynamic>> _rpc(String fn, Map<String, dynamic> params) async {
    try {
      final res = await SupabaseService.client.rpc(fn, params: params);
      return Map<String, dynamic>.from(res as Map);
    } on PostgrestException catch (e) {
      dev.log('[OrderService] $fn refused: ${e.code} ${e.message}');
      if (e.message == 'slot_too_soon') throw SlotTooSoonException();
      if (e.message == 'slot_outside_hours') throw SlotOutsideHoursException();
      if (e.message.startsWith('slot_')) throw SlotTakenException();
      throw BookingException(e.message);
    }
  }

  /// Copies the server's view of an order onto the instance the UI holds.
  void _applyServerState(OrderModel order, Map<String, dynamic> json) {
    final fresh = OrderModel.fromJson(json);
    order
      ..status = fresh.status
      ..paymentStatus = fresh.paymentStatus
      ..scheduledAt = fresh.scheduledAt
      ..cancelReason = fresh.cancelReason
      ..timeline.clear()
      ..timeline.addAll(fresh.timeline);
    _db.orders.refresh();
  }

  Future<OrderModel> create({
    required String branchId,
    required String primaryId,
    required List<String> addonIds,
    required String vehicleId,
    required DateTime slot,
    // Not stored yet: orders has no note column (QA-M7).
    String? note,
  }) async {
    final json = await _rpc('create_order', {
      'p_branch_id': branchId,
      'p_vehicle_id': vehicleId,
      'p_primary_service_id': primaryId,
      'p_scheduled_at': AvailabilityService.toUtcIsoString(slot),
      'p_addon_service_ids': addonIds,
    });
    final order = OrderModel.fromJson(json);
    _db.upsertOrders([order]);
    // The "created" notification comes from the orders trigger on the server.
    return order;
  }

  bool insideFreeWindow(OrderModel order) {
    final branch = _db.branch(order.branchId);
    final mins = order.scheduledAt.difference(DateTime.now()).inMinutes;
    return mins < (branch?.settings.freeCancelMin ?? 60);
  }

  Future<void> cancel(OrderModel order, String reason) async {
    final json = await _rpc('cancel_order', {'p_order_id': order.id, 'p_reason': reason});
    _applyServerState(order, json);
    order.lateCancel = json['late_cancel'] == true;
    // The "cancelled" notification comes from the orders trigger on the server.
  }

  Future<void> reschedule(OrderModel order, DateTime slot) async {
    final json = await _rpc('reschedule_order', {
      'p_order_id': order.id,
      'p_scheduled_at': AvailabilityService.toUtcIsoString(slot),
    });
    _applyServerState(order, json);
    order.timeline.add(TimelineEntry('rescheduled', DateTime.now()));
  }

  Future<void> review(OrderModel order, int stars, List<String> tags, String comment) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final customer = _db.customerById(order.customerId);
    final branch = _db.branch(order.branchId);
    final rev = ReviewModel(
      id: 'rv_${DateTime.now().microsecondsSinceEpoch}',
      orderId: order.id,
      customerName: customer?.name ?? '',
      branchId: order.branchId,
      businessId: branch?.businessId ?? 'biz_default',
      customerId: order.customerId,
      serviceId: order.primary.serviceId,
      serviceName: order.primary.name,
      stars: stars,
      comment: comment,
      tags: tags,
      createdAt: DateTime.now(),
    );
    _db.reviews.insert(0, rev);
    _db.saveReview(rev);
  }

  Future<String> report(OrderModel order, String category, String description) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final ticket = _db.nextTicket();
    final branch = _db.branch(order.branchId);
    final row = {
      'id': 'cp_${DateTime.now().microsecondsSinceEpoch}',
      'ticket': ticket,
      'order_id': order.id,
      'customer_id': order.customerId,
      'branch_id': order.branchId,
      'business_id': branch?.businessId ?? 'biz_default',
      'category': category,
      'description': description,
      'status': 'open',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _db.complaints.add(row);
    _db.saveComplaint(row);
    order.complaintId = ticket;
    _db.orders.refresh();
    return ticket;
  }

  /// Debug-only simulation of the car wash moving an order along. It changes
  /// the local copy only: on the server, only staff can change an order's status.
  void advance(OrderModel order) {
    final next = switch (order.status) {
      OrderStatus.pending => OrderStatus.confirmed,
      OrderStatus.confirmed => OrderStatus.waiting,
      OrderStatus.waiting => OrderStatus.inService,
      OrderStatus.inService => OrderStatus.completed,
      _ => null,
    };
    if (next == null) {
      if (order.status == OrderStatus.completed && order.paymentStatus == PaymentStatus.pending) {
        order.paymentStatus = PaymentStatus.paid;
        _db.orders.refresh();
      }
      return;
    }
    order
      ..status = next
      ..timeline.add(TimelineEntry(next.key, DateTime.now()));
    _db.orders.refresh();
    final title = _toasts[next];
    if (title != null) {
      _db.notify(
        userId: order.customerId,
        type: next.key,
        title: title,
        body: LocalizedText(order.number, order.number),
        orderId: order.id,
      );
    }
  }
}
