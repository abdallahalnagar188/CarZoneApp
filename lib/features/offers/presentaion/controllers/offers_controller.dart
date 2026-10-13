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

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    await Future.delayed(const Duration(milliseconds: 350));
    offers.assignAll(_pricing.liveOffers());
    loading.value = false;
  }

  String washName(OfferModel offer) =>
      offer.platform ? 'app.name'.tr : (_db.branch(offer.branchIds.first)?.name.value ?? '');

  void open(OfferModel offer) =>
      Get.toNamed(Routes.washDetailsRoute, arguments: offer.platform ? 'br_nasr' : offer.branchIds.first);
}
