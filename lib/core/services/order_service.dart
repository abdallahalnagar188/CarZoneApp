import 'package:get/get.dart';

import '../../commons/models/localized_text.dart';
import '../../commons/models/order_model.dart';
import '../../commons/models/review_model.dart';
import '../enums/enums.dart';
import 'availability_service.dart';
import 'carzone_db_service.dart';
import 'pricing_service.dart';

class SlotTakenException implements Exception {}

class OrderService {
  final _availability = AvailabilityService();
  final _pricing = PricingService();

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  static const _toasts = {
    OrderStatus.confirmed: LocalizedText('تم تأكيد حجزك', 'Your booking is confirmed'),
    OrderStatus.waiting: LocalizedText('تم تسجيل وصولك', 'You have checked in'),
    OrderStatus.inService: LocalizedText('بدأ تنفيذ الخدمة', 'Service started'),
    OrderStatus.completed: LocalizedText('اكتملت الخدمة', 'Service completed'),
    OrderStatus.cancelled: LocalizedText('تم إلغاء الحجز', 'Booking cancelled'),
  };

  Future<OrderModel> create({
    required String customerId,
    required String branchId,
    required String primaryId,
    required List<String> addonIds,
    required String vehicleId,
    required DateTime slot,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final branch = _db.branch(branchId)!;
    final quote = _pricing.quote(branchId: branchId, primaryId: primaryId, addonIds: addonIds);
    if (!_availability.isAvailable(branch, slot, quote.durationMin)) throw SlotTakenException();
    final now = DateTime.now();
    final auto = branch.settings.autoConfirm;
    final order = OrderModel(
      id: 'ord_${now.microsecondsSinceEpoch}',
      number: _db.nextNumber(),
      code: _db.nextCode(),
      customerId: customerId,
      vehicleId: vehicleId,
      branchId: branchId,
      items: quote.items,
      subtotal: quote.subtotal,
      discount: quote.discount,
      offerId: quote.offer?.id,
      total: quote.total,
      durationMin: quote.durationMin,
      scheduledAt: slot,
      status: auto ? OrderStatus.confirmed : OrderStatus.pending,
      note: note,
      createdAt: now,
      timeline: [
        TimelineEntry('pending', now),
        if (auto) TimelineEntry('confirmed', now),
      ],
    );
    _db.orders.add(order);
    await _db.saveOrder(order);
    _db.notify(
      userId: customerId,
      type: 'created',
      title: const LocalizedText('تم إنشاء الحجز', 'Booking created'),
      body: LocalizedText('${order.number} · ${branch.name.ar}', '${order.number} · ${branch.name.en}'),
      orderId: order.id,
    );
    return order;
  }

  bool insideFreeWindow(OrderModel order) {
    final branch = _db.branch(order.branchId);
    final mins = order.scheduledAt.difference(DateTime.now()).inMinutes;
    return mins < (branch?.settings.freeCancelMin ?? 60);
  }

  Future<void> cancel(OrderModel order, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
    order
      ..lateCancel = insideFreeWindow(order)
      ..cancelReason = reason
      ..status = OrderStatus.cancelled
      ..timeline.add(TimelineEntry('cancelled', DateTime.now()));
    _db.orders.refresh();
    await _db.saveOrder(order);
    _db.notify(
      userId: order.customerId,
      type: 'cancelled',
      title: _toasts[OrderStatus.cancelled]!,
      body: LocalizedText(order.number, order.number),
      orderId: order.id,
    );
  }

  Future<void> reschedule(OrderModel order, DateTime slot) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final branch = _db.branch(order.branchId)!;
    if (!_availability.isAvailable(branch, slot, order.durationMin, excludeOrderId: order.id)) {
      throw SlotTakenException();
    }
    order
      ..scheduledAt = slot
      ..timeline.add(TimelineEntry('rescheduled', DateTime.now()));
    _db.orders.refresh();
    await _db.saveOrder(order);
  }

  Future<void> review(OrderModel order, int stars, List<String> tags, String comment) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final customer = _db.customerById(order.customerId);
    final rev = ReviewModel(
      id: 'rv_${DateTime.now().microsecondsSinceEpoch}',
      orderId: order.id,
      customerName: customer?.name ?? '',
      branchId: order.branchId,
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
    await Future.delayed(const Duration(milliseconds: 500));
    final ticket = _db.nextTicket();
    final row = {
      'id': 'cp_${DateTime.now().microsecondsSinceEpoch}',
      'ticket_number': ticket,
      'order_id': order.id,
      'customer_id': order.customerId,
      'reason': category,
      'details': description,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    };
    _db.complaints.add(row);
    _db.saveComplaint(row);
    order.complaintId = ticket;
    _db.orders.refresh();
    _db.saveOrder(order);
    return ticket;
  }

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
        _db.saveOrder(order);
      }
      return;
    }
    order
      ..status = next
      ..timeline.add(TimelineEntry(next.key, DateTime.now()));
    _db.orders.refresh();
    _db.saveOrder(order);
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
