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

  final String? customerId;
  final String? businessId;
  final String? serviceId;

  const ReviewModel({
    required this.id,
    required this.customerName,
    required this.branchId,
    required this.serviceName,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.orderId,
    this.customerId,
    this.businessId,
    this.serviceId,
    this.tags = const [],
    this.reply,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List?;
    final tags = rawTags?.map((e) => e.toString()).toList() ?? [];

    final rawComment = json['comment'];
    final commentText = rawComment is Map
        ? LocalizedText.fromJson(rawComment).value
        : (rawComment?.toString() ?? '');

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? json['branchId']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString(),
      serviceId: json['service_id']?.toString() ?? json['serviceId']?.toString(),
      serviceName: LocalizedText.fromJson(json['service_name'] ?? json['serviceName']),
      stars: (json['stars'] as num?)?.toInt() ?? 5,
      comment: commentText,
      tags: tags,
      reply: json['reply']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId ?? '',
    'branch_id': branchId,
    'business_id': businessId ?? '',
    'customer_id': customerId ?? '',
    if (serviceId != null) 'service_id': serviceId,
    'stars': stars,
    'comment': {'ar': comment, 'en': comment},
    'tags': tags,
    if (reply != null) 'reply': reply,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}
