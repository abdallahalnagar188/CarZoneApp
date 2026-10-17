import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/branch_model.dart';
import '../../../../commons/widgets/sheets/app_bottom_sheet.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/filter_sheet.dart';

class ResultsController extends GetxController {
  final _db = Get.find<CarzoneDbService>();
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
    if (category != null) return 'cat.$category'.tr;
    if (isWashNow) return 'home.washNow'.tr;
    return 'home.nearby'.tr;
  }

  final isClosedHours = false.obs;

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

    ever(_session.areaId, (_) => load());
    ever(_db.orders, (_) {
      if (!loading.value) _compute();
    });
    ever(_db.branches, (_) {
      if (!loading.value) _compute();
    });
    ever(_db.services, (_) {
      if (!loading.value) _compute();
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
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    page.value = 0;
    hasMore.value = true;
    try {
      final areaId = _session.areaId.value;
      final fetched = await _db.fetchPaginatedBranches(
        page: 0,
        pageSize: pageSize,
        areaId: areaId.isNotEmpty ? areaId : null,
        category: category,
      );
      if (fetched.length < pageSize) {
        hasMore.value = false;
      }
      _loadedBranches.assignAll(fetched);
      _compute();
    } catch (_) {
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
      final areaId = _session.areaId.value;
      final fetched = await _db.fetchPaginatedBranches(
        page: nextPage,
        pageSize: pageSize,
        areaId: areaId.isNotEmpty ? areaId : null,
        category: category,
      );
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
    } catch (_) {
      // Keep existing state
    } finally {
      loadingMore.value = false;
    }
  }

  void _compute() {
    final branchesToUse = _loadedBranches.isNotEmpty ? _loadedBranches : _db.branches;
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

    var list = _discovery.apply(base, filters.value);
    if (category != null) {
      list = list.map((r) => r.withPrice(_pricing.fromPrice(r.branch.id, category: category))).toList();
    }
    rows.assignAll(list);
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
    filters.value = draft.value;
    Get.back();
    _compute();
  }

  void clearFilters() {
    filters.value = DiscoveryFilters(sort: filters.value.sort);
    _compute();
  }

  void openWash(String id) => Get.toNamed(Routes.washDetailsRoute, arguments: id);

  void changeArea() => Get.back();
}
