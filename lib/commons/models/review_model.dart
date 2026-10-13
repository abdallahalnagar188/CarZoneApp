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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List?;
    final tags = rawTags?.map((e) => e.toString()).toList() ?? [];

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? json['branchId']?.toString() ?? '',
      serviceName: LocalizedText.fromJson(json['service_name'] ?? json['serviceName']),
      stars: (json['stars'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      tags: tags,
      reply: json['reply']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'customer_name': customerName,
    'branch_id': branchId,
    'service_name': serviceName.toJson(),
    'stars': stars,
    'comment': comment,
    'tags': tags,
    'reply': reply,
    'created_at': createdAt.toIso8601String(),
  };
}
