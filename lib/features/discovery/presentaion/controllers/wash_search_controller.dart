import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/area_model.dart';
import '../../../../commons/models/branch_listing_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/local/cache_controller.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/session_service.dart';

class WashSearchController extends GetxController {
  final _discovery = DiscoveryService();
  final textController = TextEditingController();

  final query = ''.obs;
  final recent = <String>[].obs;
  final washes = <BranchListingModel>[].obs;
  final categories = <String>[].obs;
  final areas = <AreaModel>[].obs;

  Timer? _debounce;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  bool get hasResults => washes.isNotEmpty || categories.isNotEmpty || areas.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final cached = CacheController().getter(key: CacheKeys.recentSearches);
    if (cached is List) recent.assignAll(cached.cast<String>());
  }

  void onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(value));
  }

  void _search(String value) {
    query.value = value.trim();
    if (query.value.isEmpty) {
      washes.clear();
      categories.clear();
      areas.clear();
      return;
    }
    final q = query.value;
    washes.assignAll(
      _discovery.listings().where((r) => r.branch.name.matches(q) || _db.area(r.branch.areaId).name.matches(q)),
    );
    categories.assignAll(
      ['exterior', 'interior', 'full', 'deep'].where((c) {
        final svc = _db.services.firstWhereOrNull((s) => s.category == c && s.isPrimary);
        return ('cat.$c'.tr.toLowerCase().contains(q.toLowerCase())) || (svc?.name.matches(q) ?? false);
      }),
    );
    areas.assignAll(_db.areas.where((a) => a.name.matches(q)));
  }

  void useRecent(String value) {
    textController.text = value;
    _search(value);
  }

  Future<void> _remember() async {
    final q = query.value;
    if (q.isEmpty) return;
    final next = [q, ...recent.where((x) => x != q)].take(5).toList();
    recent.assignAll(next);
    await CacheController().setter(key: CacheKeys.recentSearches, value: next);
  }

  Future<void> clearRecent() async {
    recent.clear();
    await CacheController().setter(key: CacheKeys.recentSearches, value: <String>[]);
  }

  void openWash(String id) {
    _remember();
    Get.toNamed(Routes.washDetailsRoute, arguments: id);
  }

  void openCategory(String id) {
    _remember();
    Get.toNamed(Routes.resultsRoute, arguments: {'category': id});
  }

  Future<void> openArea(String id) async {
    _remember();
    await Get.find<SessionService>().setArea(id);
    Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby'});
  }

  void submit(String value) {
    _search(value);
    _remember();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    textController.dispose();
    super.onClose();
  }
}
