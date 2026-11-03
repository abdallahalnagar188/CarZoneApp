import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/area_model.dart';
import '../../../../commons/models/branch_listing_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/local/cache_controller.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/washup_db_service.dart';
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

  WashUpDbService get _db => Get.find<WashUpDbService>();

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

  /// The latest query sent, so a slower earlier answer is not shown over it.
  int _ticket = 0;

  Future<void> _search(String value) async {
    query.value = value.trim();
    if (query.value.isEmpty) {
      washes.clear();
      categories.clear();
      areas.clear();
      return;
    }
    final q = query.value;
    final session = Get.find<SessionService>();
    final country = session.countryCode.value;
    categories.assignAll(
      _db.categories.where((c) => c.name.matches(q) || 'cat.${c.id}'.tr.toLowerCase().contains(q.toLowerCase())).map((c) => c.id),
    );
    areas.assignAll(_db.areasIn(country).where((a) => a.name.matches(q)));

    // Every wash in the country matching the name or area, not only the loaded ones.
    final ticket = ++_ticket;
    final rows = await _db.discover(lat: session.lat, lng: session.lng, country: country, query: q, limit: 30);
    if (ticket != _ticket) return;
    final ids = rows.map((r) => r.branch.id).toSet();
    washes.assignAll(_discovery.listings().where((r) => ids.contains(r.branch.id)).toList()
      ..sort((a, b) => a.km.compareTo(b.km)));
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
