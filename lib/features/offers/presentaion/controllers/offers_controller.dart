import 'package:get/get.dart';

import '../../../../commons/models/offer_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/washup_db_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/pricing_service.dart';

class OffersController extends GetxController {
  final _pricing = PricingService();
  final _discovery = DiscoveryService();

  final loading = true.obs;
  final offers = <OfferModel>[].obs;

  WashUpDbService get _db => Get.find<WashUpDbService>();

  /// Why the offers could not be loaded; null after a successful load.
  String? get error => _db.hasError.value ? _db.errorMessage.value : null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Offers arrive with the home catalog; fetch it again when it failed or
  /// on pull to refresh.
  Future<void> load() async {
    loading.value = offers.isEmpty;
    if (_db.offers.isEmpty || offers.isNotEmpty) await _db.fetchFromSupabase();
    offers.assignAll(_pricing.liveOffers());
    loading.value = false;
  }

  String washName(OfferModel offer) {
    if (offer.platform) return 'app.name'.tr;
    final bid = offer.branchIds.firstOrNull;
    if (bid == null || bid.isEmpty) return 'app.name'.tr;
    return _db.branch(bid)?.name.value ?? 'app.name'.tr;
  }

  /// A wash offer opens its wash; a Wash Up offer (or one without a wash)
  /// opens the nearest wash, like the home carousel, or the nearby list when
  /// none is known. Never a seed branch id (GAP-040).
  void open(OfferModel offer) {
    final own = offer.platform ? null : offer.branchIds.firstOrNull;
    final target = own ?? _nearestWashId();
    if (target == null) {
      Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby'});
      return;
    }
    Get.toNamed(Routes.washDetailsRoute, arguments: target);
  }

  String? _nearestWashId() {
    final rows = _discovery.listings()..sort((a, b) => a.km.compareTo(b.km));
    return rows.firstOrNull?.branch.id;
  }
}
