import '../../core/enums/enums.dart';
import 'localized_text.dart';

class OfferModel {
  final String id;
  final bool platform;
  final List<String> branchIds;
  final List<String> serviceIds;
  final LocalizedText title;
  final LocalizedText description;
  final DiscountType discountType;
  final int discountValue;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final bool featured;
  final int photoIndex;

  const OfferModel({
    required this.id,
    required this.platform,
    required this.branchIds,
    required this.serviceIds,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.featured = false,
    this.photoIndex = 0,
  });

  bool isLive(DateTime now) =>
      status == 'active' && now.isAfter(startAt) && now.isBefore(endAt);

  int discountFor(int price) => discountType == DiscountType.percent
      ? (price * discountValue / 100).round()
      : discountValue.clamp(0, price);

  String get offerLabel => '\u2066−$badge\u2069';

  String get badge => discountType == DiscountType.percent
      ? '$discountValue%'
      : '$discountValue';

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final dtStr = (json['discount_type'] ?? json['discountType'])?.toString() ?? 'percent';
    final discountType = dtStr == 'fixed' ? DiscountType.fixed : DiscountType.percent;

    final rawBranchIds = (json['branch_ids'] ?? json['branchIds']) as List?;
    final branchIds = rawBranchIds?.map((e) => e.toString()).toList() ?? [];

    final rawServiceIds = (json['service_ids'] ?? json['serviceIds']) as List?;
    final serviceIds = rawServiceIds?.map((e) => e.toString()).toList() ?? [];

    final start = DateTime.tryParse(json['start_at'] ?? json['startAt'] ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(json['end_at'] ?? json['endAt'] ?? '') ?? DateTime.now().add(const Duration(days: 7));

    return OfferModel(
      id: json['id']?.toString() ?? '',
      platform: json['platform'] as bool? ?? false,
      branchIds: branchIds,
      serviceIds: serviceIds,
      title: LocalizedText.fromJson(json['title']),
      description: LocalizedText.fromJson(json['description']),
      discountType: discountType,
      discountValue: (json['discount_value'] ?? json['discountValue'] as num?)?.toInt() ?? 0,
      startAt: start,
      endAt: end,
      status: json['status']?.toString() ?? 'active',
      featured: json['featured'] as bool? ?? false,
      photoIndex: (json['photo_index'] ?? json['photoIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'branch_ids': branchIds,
    'service_ids': serviceIds,
    'title': title.toJson(),
    'description': description.toJson(),
    'discount_type': discountType == DiscountType.fixed ? 'fixed' : 'percent',
    'discount_value': discountValue,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt.toIso8601String(),
    'status': status,
    'featured': featured,
    'photo_index': photoIndex,
  };
}
