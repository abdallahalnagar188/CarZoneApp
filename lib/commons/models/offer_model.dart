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
}
