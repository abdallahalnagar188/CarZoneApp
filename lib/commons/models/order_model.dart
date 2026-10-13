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
}

class TimelineEntry {
  final String key;
  final DateTime at;

  const TimelineEntry(this.key, this.at);
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

  OrderItem get primary =>
      items.firstWhere((i) => i.type == ServiceType.primary,
          orElse: () => items.first);

  List<OrderItem> get addons =>
      items.where((i) => i.type == ServiceType.addon).toList();

  bool get showsQr => const [
        OrderStatus.confirmed,
        OrderStatus.waiting,
        OrderStatus.inService,
      ].contains(status);
}
