import '../../core/enums/enums.dart';
import 'localized_text.dart';

class OrderItem {
  final String serviceId;
  final LocalizedText name;
  final ServiceType type;
  final int price;
  final int durationMin;

  const OrderItem({
    required this.serviceId,
    required this.name,
    required this.type,
    required this.price,
    required this.durationMin,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type']?.toString() ?? 'primary').toLowerCase();
    return OrderItem(
      serviceId: json['service_id']?.toString() ?? json['serviceId']?.toString() ?? '',
      name: LocalizedText.fromJson(json['name']),
      type: typeStr == 'addon' ? ServiceType.addon : ServiceType.primary,
      price: (json['price'] as num?)?.toInt() ?? 0,
      durationMin: (json['duration_min'] ?? json['durationMin'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'service_id': serviceId,
    'name': name.toJson(),
    'type': type == ServiceType.addon ? 'addon' : 'primary',
    'price': price,
    'duration_min': durationMin,
  };
}

class TimelineEntry {
  final String key;
  final DateTime at;

  const TimelineEntry(this.key, this.at);

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      (json['key'] ?? json['status'])?.toString() ?? '',
      DateTime.tryParse(json['at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'at': at.toIso8601String(),
  };
}

class OrderModel {
  final String id;
  final String number;
  final String code;
  final String customerId;
  String vehicleId;
  final String branchId;
  final List<OrderItem> items;
  final int subtotal;
  final int discount;
  final String? offerId;
  final int total;
  final int durationMin;
  DateTime scheduledAt;
  OrderStatus status;
  PaymentStatus paymentStatus;
  final String? note;
  final List<TimelineEntry> timeline;
  String? cancelReason;
  bool lateCancel;
  String? complaintId;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.number,
    required this.code,
    required this.customerId,
    required this.vehicleId,
    required this.branchId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.durationMin,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    this.paymentStatus = PaymentStatus.pending,
    this.offerId,
    this.note,
    this.cancelReason,
    this.lateCancel = false,
    this.complaintId,
    List<TimelineEntry>? timeline,
  }) : timeline = timeline ?? [];

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMin));

  static const fallbackItem = OrderItem(
    serviceId: '',
    name: LocalizedText('خدمة غسيل', 'Car Wash'),
    type: ServiceType.primary,
    price: 0,
    durationMin: 30,
  );

  OrderItem get primary => items.firstWhere(
        (i) => i.type == ServiceType.primary,
        orElse: () => items.isNotEmpty ? items.first : fallbackItem,
      );

  List<OrderItem> get addons =>
      items.where((i) => i.type == ServiceType.addon).toList();

  bool get showsQr => const [
        OrderStatus.confirmed,
        OrderStatus.waiting,
        OrderStatus.inService,
      ].contains(status);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['order_items'] ?? json['items']) as List?;
    final items = rawItems != null
        ? rawItems.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <OrderItem>[];

    final rawTimeline = (json['order_events'] ?? json['timeline']) as List?;
    final timeline = rawTimeline != null
        ? rawTimeline.map((e) => TimelineEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <TimelineEntry>[];

    final statusStr = json['status']?.toString() ?? 'pending';
    final status = OrderStatus.values.firstWhere(
      (s) => s.name == statusStr || s.key == statusStr,
      orElse: () => OrderStatus.pending,
    );

    final paymentStr = (json['payment_status'] ?? json['paymentStatus'])?.toString() ?? 'pending';
    final paymentStatus = PaymentStatus.values.firstWhere(
      (p) => p.name == paymentStr,
      orElse: () => PaymentStatus.pending,
    );

    return OrderModel(
      id: json['id']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? json['vehicleId']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? json['branchId']?.toString() ?? '',
      items: items,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discount: (json['discount_amount'] ?? json['discount'] as num?)?.toInt() ?? 0,
      offerId: json['offer_id']?.toString() ?? json['offerId']?.toString(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      durationMin: (json['duration_min'] ?? json['durationMin'] as num?)?.toInt() ?? 30,
      scheduledAt: DateTime.tryParse(json['scheduled_at'] ?? json['scheduledAt'] ?? '')?.toLocal() ?? DateTime.now(),
      status: status,
      paymentStatus: paymentStatus,
      note: json['note']?.toString(),
      timeline: timeline,
      cancelReason: json['cancel_reason']?.toString() ?? json['cancelReason']?.toString(),
      lateCancel: json['late_cancel'] ?? json['lateCancel'] ?? false,
      complaintId: json['complaint_id']?.toString() ?? json['complaintId']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'code': code,
    'customer_id': customerId,
    'vehicle_id': vehicleId,
    'branch_id': branchId,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'offer_id': offerId,
    'total': total,
    'duration_min': durationMin,
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    'status': status.key,
    'payment_status': paymentStatus.name,
    'note': note,
    'timeline': timeline.map((t) => t.toJson()).toList(),
    'cancel_reason': cancelReason,
    'late_cancel': lateCancel,
    'complaint_id': complaintId,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}
