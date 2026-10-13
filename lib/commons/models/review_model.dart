import 'localized_text.dart';

class ReviewModel {
  final String id;
  final String? orderId;
  final String customerName;
  final String branchId;
  final LocalizedText serviceName;
  final int stars;
  final String comment;
  final List<String> tags;
  final String? reply;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.customerName,
    required this.branchId,
    required this.serviceName,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.orderId,
    this.tags = const [],
    this.reply,
  });
}
