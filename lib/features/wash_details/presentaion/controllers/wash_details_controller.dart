import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/branch_model.dart';
import '../../../../commons/models/offer_model.dart';
import '../../../../commons/models/review_model.dart';
import '../../../../commons/models/wash_service_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../booking/presentaion/controllers/booking_controller.dart';
import '../../../favorites/presentaion/controllers/favorites_controller.dart';

class WashDetailsController extends GetxController {
  final _discovery = DiscoveryService();
  final _availability = AvailabilityService();
  final _pricing = PricingService();

  final loading = true.obs;
  final listing = Rxn<BranchListingModel>();
  final primaries = <WashServiceModel>[].obs;
  final addons = <WashServiceModel>[].obs;
  final nextSlots = <SlotModel>[].obs;
  final reviews = <ReviewModel>[].obs;
  final hoursExpanded = false.obs;
  final reviewStarFilter = 0.obs;

  late final String branchId;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  BranchModel? get branch => listing.value?.branch;

  @override
  void onInit() {
    super.onInit();
    branchId = Get.arguments?.toString() ?? 'br_nasr';
    load();
    ever(_db.branches, (_) => _compute());
    ever(_db.services, (_) => _compute());
    ever(_db.reviews, (_) => _compute());
    ever(_db.orders, (_) => _compute());
  }

  Future<void> load() async {
    loading.value = true;
    await Future.delayed(const Duration(milliseconds: 400));
    _compute();
    loading.value = false;
  }

  void _compute() {
    final b = _db.branch(branchId);
    if (b == null) return;
    listing.value = _discovery.decorate(b);
    final services = _db.servicesFor(branchId);
    primaries.assignAll(services.where((s) => s.isPrimary));
    addons.assignAll(services.where((s) => s.type == ServiceType.addon));
    nextSlots.assignAll(_availability.nextSlots(b));
    reviews.assignAll(_db.reviewsFor(branchId));
  }

  List<int> get distribution {
    final counts = List.filled(5, 0);
    for (final r in reviews) {
      counts[r.stars - 1]++;
    }
    return counts;
  }

  List<ReviewModel> get filteredReviews => reviewStarFilter.value == 0
      ? reviews
      : reviews.where((r) => r.stars == reviewStarFilter.value).toList();

  OfferModel? offerFor(WashServiceModel s) => _pricing.offerFor(branchId, s.id);

  int get galleryCount => 8;

  bool get isFavorite => Get.find<FavoritesController>().ids.contains(branchId);

  void toggleFavorite() => Get.find<FavoritesController>().toggle(branchId);

  void toggleHours() => hoursExpanded.toggle();

  void call() {
    if (branch != null) MapsService.call(branch!.phone);
  }

  void navigate() {
    if (branch != null) MapsService.openDirections(branch!.lat, branch!.lng);
  }

  Future<void> share() async {
    final b = branch;
    final name = b?.name.value ?? 'CarZone Wash';
    final address = b?.address.value ?? '';
    final rating = listing.value?.rating.toStringAsFixed(1) ?? '4.8';
    final shareUrl = DeepLinkService.buildShareUrl(branchId);

    final text = '🚗 $name\n'
        '⭐ $rating (${listing.value?.reviewCount ?? 0} تقييم)\n'
        '📍 $address\n\n'
        'احجز موعد غسيل سيارتك الآن على CarZone:\n'
        '$shareUrl';

    try {
      await Share.share(
        text,
        subject: name,
      );
      _recordShareAnalytics();
    } catch (e) {
      dev.log('[WashDetailsController] Share error: $e');
    }
  }

  void _recordShareAnalytics() {
    try {
      final session = Get.find<SessionService>();
      SupabaseService.client.from('branch_shares').insert({
        'branch_id': branchId,
        'user_id': session.userId,
        'platform': 'native_share',
      }).then((_) {
        dev.log('[WashDetailsController] Share event recorded in Supabase.');
      }).catchError((err) {
        dev.log('[WashDetailsController] Error recording share event: $err');
      });
    } catch (_) {}
  }

  void openGallery(int index) => Get.toNamed(Routes.galleryRoute, arguments: {'branchId': branchId, 'index': index});

  void openReviews() => Get.toNamed(Routes.reviewsRoute, arguments: branchId);

  void book({String? serviceId, DateTime? slot}) {
    Get.find<BookingController>().start(branchId, serviceId: serviceId, slot: slot);
  }
}
