import 'package:get/get.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/widgets/sheets/app_bottom_sheet.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/filter_sheet.dart';

class ResultsController extends GetxController {
  final _discovery = DiscoveryService();
  final _pricing = PricingService();

  final loading = true.obs;
  final rows = <BranchListingModel>[].obs;
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
    ever(Get.find<SessionService>().areaId, (_) => load());
    ever(Get.find<CarzoneDbService>().orders, (_) => _compute());
    ever(Get.find<CarzoneDbService>().branches, (_) => _compute());
    load();
  }

  Future<void> load() async {
    loading.value = true;
    await Future.delayed(const Duration(milliseconds: 400));
    _compute();
    loading.value = false;
  }

  void _compute() {
    final base = isWashNow ? _discovery.washNow() : _discovery.listings(category: category);
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
