import 'branch_model.dart';

class BranchListingModel {
  final BranchModel branch;
  final double km;
  final double rating;
  final int reviewCount;
  final int? fromPrice;
  final bool open;
  final DateTime? nextSlot;

  const BranchListingModel({
    required this.branch,
    required this.km,
    required this.rating,
    required this.reviewCount,
    required this.fromPrice,
    required this.open,
    required this.nextSlot,
  });

  BranchListingModel withPrice(int? price) => BranchListingModel(
        branch: branch,
        km: km,
        rating: rating,
        reviewCount: reviewCount,
        fromPrice: price,
        open: open,
        nextSlot: nextSlot,
      );
}
