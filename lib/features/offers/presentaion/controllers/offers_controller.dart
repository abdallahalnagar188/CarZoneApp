import 'package:get/get.dart';

import '../../../../commons/models/offer_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/pricing_service.dart';

class OffersController extends GetxController {
  final _pricing = PricingService();

  final loading = true.obs;
  final offers = <OfferModel>[].obs;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

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

  void open(OfferModel offer) {
    final bid = offer.platform ? 'br_nasr' : (offer.branchIds.firstOrNull ?? 'br_nasr');
    Get.toNamed(Routes.washDetailsRoute, arguments: bid);
  }
}
