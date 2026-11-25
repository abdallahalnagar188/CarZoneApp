import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/branch_model.dart';
import '../../../../commons/models/offer_model.dart';
import '../../../../commons/models/review_model.dart';
import '../../../../commons/models/wash_service_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/helpers/route_argument_stack.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/services/washup_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../booking/presentaion/controllers/booking_controller.dart';
import '../../../favorites/presentaion/controllers/favorites_controller.dart';

class WashDetailsController extends GetxController with RouteArgumentStack {
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

  /// Why the branch could not be loaded; shown only when nothing is cached.
  final error = RxnString();

  /// The wash shown: the top-most open wash page's (GAP-032). Empty when the
  /// page was opened without one; then "not found" shows.
  String get branchId => activeArgument.value;

  final _workers = <Worker>[];

  /// Bumped on every switch, so a slow load for the previous wash is dropped.
  int _generation = 0;

  WashUpDbService get _db => Get.find<WashUpDbService>();

  BranchModel? get branch => listing.value?.branch;

  @override
  void onInit() {
    super.onInit();
    initArgument(Get.arguments?.toString());
    load();
    _workers.addAll([
      ever(_db.branches, (_) => _compute()),
      ever(_db.services, (_) => _compute()),
      ever(_db.reviews, (_) => _compute()),
      ever(_db.orders, (_) => _compute()),
    ]);
    final reconnect = ConnectivityService.maybe?.onReconnect(() {
      if (error.value != null) load();
    });
    if (reconnect != null) _workers.add(reconnect);
  }

  @override
  void onArgumentChanged() {
    listing.value = null;
    primaries.clear();
    addons.clear();
    nextSlots.clear();
    reviews.clear();
    hoursExpanded.value = false;
    reviewStarFilter.value = 0;
    error.value = null;
    load();
  }

  Future<void> load() async {
    final id = branchId;
    final generation = ++_generation;
    if (id.isEmpty) {
      loading.value = false;
      return;
    }
    loading.value = true;
    try {
      await _db.fetchBranchDetails(id, throwOnError: true);
      if (generation != _generation) return;
      error.value = null;
    } catch (e) {
      if (generation != _generation) return;
      error.value = ApiException.messageFor(e);
    } finally {
      if (generation == _generation) {
        _compute();
        loading.value = false;
      }
    }
    if (generation == _generation) await _loadNextSlots(generation);
  }

  @override
  void onClose() {
    for (final w in _workers) {
      w.dispose();
    }
    _workers.clear();
    super.onClose();
  }

  void _compute() {
    if (branchId.isEmpty) return;
    final b = _db.branch(branchId);
    if (b == null) return;
    listing.value = _discovery.decorate(b);
    final services = _db.servicesFor(branchId);
    primaries.assignAll(services.where((s) => s.isPrimary));
    addons.assignAll(services.where((s) => s.type == ServiceType.addon));
    reviews.assignAll(_db.reviewsFor(branchId));
  }

  /// The next free times from get_branch_slots (bookings and blocked times
  /// included), on the wash's own days; none when they cannot be loaded (GAP-016).
  Future<void> _loadNextSlots(int generation, {int count = 3}) async {
    final b = _db.branch(branchId);
    if (b == null || !b.bookable) {
      nextSlots.clear();
      return;
    }
    final w = FormatHelper.wallClock(DateTime.now(), branchId: b.id);
    final duration = primaries.isEmpty ? 30 : primaries.map((s) => s.durationMin).reduce((a, c) => a < c ? a : c);
    try {
      for (var i = 0; i <= b.settings.maxAdvanceDays; i++) {
        final day = DateTime(w.year, w.month, w.day + i);
        if (b.hoursKnown && b.hoursFor(day).closed) continue;
        final slots = await _availability.fetchRemoteSlots(b, day, durationMin: duration);
        if (generation != _generation) return;
        final free = slots.where((s) => !s.full).toList();
        if (free.isNotEmpty) {
          nextSlots.assignAll(free.take(count));
          return;
        }
      }
      nextSlots.clear();
    } catch (e) {
      dev.log('[WashDetailsController] next slots unavailable: $e');
      if (generation == _generation) nextSlots.clear();
    }
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

  /// The wash's own photos only (GAP-016).
  int get galleryCount => branch?.photos.length ?? 0;

  bool get isFavorite => Get.find<FavoritesController>().ids.contains(branchId);

  void toggleFavorite() => Get.find<FavoritesController>().toggle(branchId);

  void toggleHours() => hoursExpanded.toggle();

  void call() {
    if (branch != null) MapsService.call(branch!.phone);
  }

  void navigate() {
    if (branch != null) MapsService.openDirections(branch!.lat, branch!.lng);
  }

  /// [origin] is the share button's on-screen rect; iOS 26 and iPad anchor the
  /// share sheet to it and refuse to open without one.
  Future<void> share([Rect? origin]) async {
    final b = branch;
    final name = b?.name.value ?? 'Wash Up';
    final address = b?.address.value ?? '';
    final shareUrl = DeepLinkService.buildShareUrl(branchId);
    // The wash's real rating, or "new" when nobody rated it yet (GAP-033), in
    // the app's language (GAP-071).
    final row = listing.value;
    final ratingLine = row == null || row.reviewCount == 0
        ? 'wash.shareNew'.tr
        : 'wash.shareRated'.trParams({'rating': row.rating.toStringAsFixed(1), 'count': '${row.reviewCount}'});

    final text = '🚗 $name\n'
        '$ratingLine\n'
        '📍 $address\n\n'
        '${'wash.shareCta'.tr}\n'
        '$shareUrl';

    try {
      await Share.share(
        text,
        subject: name,
        sharePositionOrigin: origin,
      );
      _recordShareAnalytics();
    } catch (e) {
      dev.log('[WashDetailsController] Share error: $e');
      Utils.getSnakBar(message: 'error.title'.tr, type: TosterTypes.failed);
    }
  }

  void _recordShareAnalytics() {
    final session = Get.find<SessionService>();
    ApiCall.write(
      () => SupabaseService.client.from('branch_shares').insert({
        'branch_id': branchId,
        'user_id': session.userId,
        'platform': 'native_share',
      }),
      tag: 'record share',
    ).then((_) {
      dev.log('[WashDetailsController] Share event recorded in Supabase.');
    }).catchError((Object err) {
      dev.log('[WashDetailsController] Error recording share event: $err');
    });
  }

  void openGallery(int index) => Get.toNamed(Routes.galleryRoute, arguments: {'branchId': branchId, 'index': index});

  void openReviews() => Get.toNamed(Routes.reviewsRoute, arguments: branchId);

  void book({String? serviceId, DateTime? slot}) {
    Get.find<BookingController>().start(branchId, serviceId: serviceId, slot: slot);
  }
}
