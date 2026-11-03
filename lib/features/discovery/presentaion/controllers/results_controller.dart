import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/branch_model.dart';
import '../../../../commons/widgets/sheets/app_bottom_sheet.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/washup_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../widgets/filter_sheet.dart';

class ResultsController extends GetxController {
  final _db = Get.find<WashUpDbService>();
  final _session = Get.find<SessionService>();
  final _discovery = DiscoveryService();
  final _pricing = PricingService();

  final scrollController = ScrollController();

  final loading = true.obs;
  final loadingMore = false.obs;
  final hasMore = true.obs;
  final page = 0.obs;
  final pageSize = 10;

  final rows = <BranchListingModel>[].obs;
  final _loadedBranches = <BranchModel>[].obs;
  final filters = const DiscoveryFilters().obs;
  final draft = const DiscoveryFilters().obs;

  String mode = 'nearby';
  String? category;

  bool get isWashNow => mode == 'washnow';

  String get title {
    if (category != null) return _db.categoryName(category!);
    if (isWashNow) return 'home.washNow'.tr;
    return 'home.nearby'.tr;
  }

  final isClosedHours = false.obs;

  /// Why the first page failed; null after a successful load.
  final error = RxnString();

  Worker? _reconnect;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      mode = args['mode']?.toString() ?? 'nearby';
      category = args['category']?.toString();
      if (args['filters'] == true) Future.delayed(const Duration(milliseconds: 500), openFilters);
    }
    if (isWashNow) filters.value = const DiscoveryFilters(sort: SortMode.earliest);

    scrollController.addListener(_onScroll);

    everAll([_session.areaId, _session.countryCode, _session.position], (_) => load());
    ever(_db.orders, (_) {
      if (!loading.value) _compute();
    });
    ever(_db.branches, (_) {
      if (!loading.value) _compute();
    });
    ever(_db.services, (_) {
      if (!loading.value) _compute();
    });
    _reconnect = ConnectivityService.maybe?.onReconnect(() {
      if (error.value != null) load();
    });
    load();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      loadNextPage();
    }
  }

  @override
  void onClose() {
    _reconnect?.dispose();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    page.value = 0;
    hasMore.value = true;
    try {
      final fetched = await _fetch(0);
      if (fetched.length < pageSize) {
        hasMore.value = false;
      }
      error.value = null;
      _loadedBranches.assignAll(fetched);
      _compute();
    } catch (e) {
      // Cached branches (if any) are still listed; the error shows when there are none.
      error.value = ApiException.messageFor(e);
      _compute();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (loadingMore.value || !hasMore.value || loading.value) return;
    loadingMore.value = true;
    try {
      final nextPage = page.value + 1;
      final fetched = await _fetch(nextPage);
      if (fetched.isEmpty) {
        hasMore.value = false;
      } else {
        if (fetched.length < pageSize) {
          hasMore.value = false;
        }
        page.value = nextPage;
        final existingIds = _loadedBranches.map((b) => b.id).toSet();
        for (final b in fetched) {
          if (!existingIds.contains(b.id)) {
            _loadedBranches.add(b);
          }
        }
        _compute();
      }
    } catch (e) {
      // Keep existing state; scrolling to the end again retries.
      Utils.getSnakBar(message: ApiException.messageFor(e), type: TosterTypes.failed);
    } finally {
      loadingMore.value = false;
    }
  }

  /// One page of washes in the browsed country, nearest first, so later pages
  /// never hold a wash closer than one already shown.
  Future<List<BranchModel>> _fetch(int page) async {
    final rows = await _db.discover(
      lat: _session.lat,
      lng: _session.lng,
      country: _session.countryCode.value,
      category: category,
      maxKm: filters.value.maxKm,
      limit: pageSize,
      offset: page * pageSize,
      throwOnError: true,
    );
    return rows.map((r) => r.branch).toList();
  }

  void _compute() {
    final country = _session.countryCode.value;
    final branchesToUse = (_loadedBranches.isNotEmpty ? _loadedBranches : _db.branches)
        .where((b) => _db.countryOfBranch(b.id).code == country)
        .toList();
    List<BranchListingModel> base;
    if (isWashNow) {
      final limit = DateTime.now().add(const Duration(minutes: 90));
      final immediate = branchesToUse
          .where((b) => b.bookable)
          .map((b) => _discovery.decorate(b, category: category))
          .where((r) => r.open && r.nextSlot != null && r.nextSlot!.isBefore(limit))
          .toList();

      if (immediate.isNotEmpty) {
        isClosedHours.value = false;
        base = immediate;
      } else {
        // Outside operating hours or no slots in 90 mins:
        // Do not show an empty view! Gracefully show all bookable branches in the area,
        // sorted by their earliest available slot so the customer can book their appointment.
        isClosedHours.value = true;
        base = branchesToUse
            .where((b) => b.bookable)
            .where((b) => category == null || _db.servicesFor(b.id).any((s) => s.isPrimary && s.category == category))
            .map((b) => _discovery.decorate(b, category: category))
            .toList();
      }
    } else {
      isClosedHours.value = false;
      base = branchesToUse
          .where((b) => b.bookable)
          .where((b) => category == null || _db.servicesFor(b.id).any((s) => s.isPrimary && s.category == category))
          .map((b) => _discovery.decorate(b, category: category))
          .toList();
    }

    _unfiltered = base;
    var list = _discovery.apply(base, filters.value);
    if (category != null) {
      list = list.map((r) => r.withPrice(_pricing.fromPrice(r.branch.id, category: category))).toList();
    }
    rows.assignAll(list);
  }

  List<BranchListingModel> _unfiltered = const [];

  /// Lowest and highest "from" price among the results, for the price slider;
  /// null when there is nothing to choose between.
  ({double min, double max})? get priceRange {
    final prices = _unfiltered.map((r) => r.fromPrice).whereType<num>().toList();
    if (prices.length < 2) return null;
    final lo = prices.reduce((a, b) => a < b ? a : b).floorToDouble();
    final hi = prices.reduce((a, b) => a > b ? a : b).ceilToDouble();
    return hi > lo ? (min: lo, max: hi) : null;
  }

  void setSort(SortMode sort) {
    filters.value = filters.value.copyWith(sort: sort);
    _compute();
  }

  void openFilters() {
    draft.value = filters.value;
    AppBottomSheet.show(title: 'filter'.tr, child: const FilterSheet());
  }

  void updateDraft(DiscoveryFilters value) => draft.value = value;

  void resetDraft() => draft.value = DiscoveryFilters(sort: filters.value.sort);

  void applyDraft() {
    final radiusChanged = draft.value.maxKm != filters.value.maxKm;
    filters.value = draft.value;
    Get.back();
    // The distance limit is applied by the server, so a new one needs a reload.
    radiusChanged ? load() : _compute();
  }

  void clearFilters() {
    final hadRadius = filters.value.maxKm != null;
    filters.value = DiscoveryFilters(sort: filters.value.sort);
    hadRadius ? load() : _compute();
  }

  void openWash(String id) => Get.toNamed(Routes.washDetailsRoute, arguments: id);

  void changeArea() => Get.back();
}
