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
}
