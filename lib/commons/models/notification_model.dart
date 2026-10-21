import 'localized_text.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final LocalizedText title;
  final LocalizedText body;
  final String? orderId;
  bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.read = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['customer_id']?.toString() ?? json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: LocalizedText.fromJson(json['title']),
      body: LocalizedText.fromJson(json['body']),
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString(),
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': userId,
    'type': type,
    'title': title.toJson(),
    'body': body.toJson(),
    'order_id': orderId,
    'href': orderId != null ? '/booking_details?id=$orderId' : '/notifications',
    'read': read,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}
