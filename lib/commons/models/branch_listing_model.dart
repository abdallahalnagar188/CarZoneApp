import 'package:get/get.dart';

import 'branch_model.dart';

class BranchListingModel {
  final BranchModel branch;
  final double km;
  final double rating;
  final int reviewCount;
  final num? fromPrice;
  final bool open;
  final DateTime? nextSlot;

  /// "New" for a wash nobody has rated yet, else its average (GAP-033).
  String get ratingLabel => reviewCount == 0 ? 'rating.new'.tr : rating.toStringAsFixed(1);

  const BranchListingModel({
    required this.branch,
    required this.km,
    required this.rating,
    required this.reviewCount,
    required this.fromPrice,
    required this.open,
    required this.nextSlot,
  });

  BranchListingModel withPrice(num? price) => BranchListingModel(
        branch: branch,
        km: km,
        rating: rating,
        reviewCount: reviewCount,
        fromPrice: price,
        open: open,
        nextSlot: nextSlot,
      );
}
