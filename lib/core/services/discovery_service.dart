import 'package:get/get.dart';

import '../../commons/models/branch_listing_model.dart';
import '../../commons/models/branch_model.dart';
import '../enums/enums.dart';
import '../helpers/format_helper.dart';
import 'availability_service.dart';
import 'carzone_db_service.dart';
import 'pricing_service.dart';
import 'session_service.dart';

class DiscoveryFilters {
  final double? maxKm;
  final double? minRating;
  final double priceMin;
  final double priceMax;
  final bool openNow;
  final bool availableToday;
  final SortMode sort;

  const DiscoveryFilters({
    this.maxKm,
    this.minRating,
    this.priceMin = 0,
    this.priceMax = 500,
    this.openNow = false,
    this.availableToday = false,
    this.sort = SortMode.nearest,
  });

  int get activeCount => [
        maxKm != null,
        minRating != null,
        priceMin > 0 || priceMax < 500,
        openNow,
        availableToday,
      ].where((x) => x).length;

  DiscoveryFilters copyWith({
    double? Function()? maxKm,
    double? Function()? minRating,
    double? priceMin,
    double? priceMax,
    bool? openNow,
    bool? availableToday,
    SortMode? sort,
  }) =>
      DiscoveryFilters(
        maxKm: maxKm != null ? maxKm() : this.maxKm,
        minRating: minRating != null ? minRating() : this.minRating,
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        openNow: openNow ?? this.openNow,
        availableToday: availableToday ?? this.availableToday,
        sort: sort ?? this.sort,
      );
}

class DiscoveryService {
  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get _session => Get.find<SessionService>();
  final _availability = AvailabilityService();
  final _pricing = PricingService();

  BranchListingModel decorate(BranchModel b, {String? category}) {
    final liveRating = _db.ratingFor(b.id);
    final rating = liveRating.count > 0 ? liveRating.rating : (b.rating > 0 ? b.rating : 5.0);
    final reviewCount = liveRating.count > 0 ? liveRating.count : b.reviewCount;
    return BranchListingModel(
      branch: b,
      km: FormatHelper.haversineKm(_session.lat, _session.lng, b.lat, b.lng),
      rating: rating,
      reviewCount: reviewCount,
      fromPrice: _pricing.fromPrice(b.id, category: category),
      open: _availability.isOpenNow(b),
      nextSlot: _availability.nextSlot(b),
    );
  }

  List<BranchListingModel> listings({String? category}) => _db.branches
      .where((b) => b.bookable)
      .where((b) => category == null ||
          _db.servicesFor(b.id).any((s) => s.isPrimary && s.category == category))
      .map((b) => decorate(b, category: category))
      .toList();

  List<BranchListingModel> apply(List<BranchListingModel> rows, DiscoveryFilters f) {
    final now = DateTime.now();
    final list = rows.where((r) {
      if (f.maxKm != null && r.km > f.maxKm!) return false;
      if (f.minRating != null && r.rating < f.minRating!) return false;
      final price = r.fromPrice ?? 0;
      if (price < f.priceMin || price > f.priceMax) return false;
      if (f.openNow && !r.open) return false;
      if (f.availableToday &&
          (r.nextSlot == null || !FormatHelper.sameDay(r.nextSlot!, now))) {
        return false;
      }
      return true;
    }).toList();
    final far = DateTime(9999);
    switch (f.sort) {
      case SortMode.nearest:
        list.sort((a, b) => a.km.compareTo(b.km));
      case SortMode.rated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortMode.price:
        list.sort((a, b) => (a.fromPrice ?? 9999).compareTo(b.fromPrice ?? 9999));
      case SortMode.earliest:
        list.sort((a, b) => (a.nextSlot ?? far).compareTo(b.nextSlot ?? far));
    }
    return list;
  }

  List<BranchListingModel> washNow() {
    final limit = DateTime.now().add(const Duration(minutes: 90));
    return apply(
      listings().where((r) => r.open && r.nextSlot != null && r.nextSlot!.isBefore(limit)).toList(),
      const DiscoveryFilters(sort: SortMode.earliest),
    );
  }
}
