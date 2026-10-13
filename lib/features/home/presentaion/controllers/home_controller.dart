import 'package:get/get.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/offer_model.dart';
import '../../../../commons/models/order_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../commons/widgets/sheets/app_bottom_sheet.dart';
import '../../../../core/utils/utils.dart';
import '../../../main/presentaion/controllers/main_controller.dart';
import '../widgets/area_picker_sheet.dart';

class HomeCategory {
  final String id;
  final int? from;

  const HomeCategory(this.id, this.from);
}

class HomeController extends GetxController {
  final _discovery = DiscoveryService();
  final _pricing = PricingService();

  final loading = true.obs;
  final nearby = <BranchListingModel>[].obs;
  final categories = <HomeCategory>[].obs;
  final offers = <OfferModel>[].obs;
  final activeOrder = Rxn<OrderModel>();
  final unreviewed = Rxn<OrderModel>();
  final unread = 0.obs;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get session => Get.find<SessionService>();

  static const categoryIds = ['exterior', 'interior', 'full', 'deep'];

  @override
  void onInit() {
    super.onInit();
    load();
    everAll([_db.orders, _db.reviews, _db.notifications, session.user, session.areaId], (_) => _compute());
  }

  Future<void> load() async {
    loading.value = true;
    await Future.delayed(const Duration(milliseconds: 450));
    _compute();
    loading.value = false;
  }

  void _compute() {
    nearby.assignAll(
      _discovery.apply(_discovery.listings(), const DiscoveryFilters()).take(8),
    );
    categories.assignAll(categoryIds.map((id) {
      final prices = _db.services
          .where((s) => s.category == id && s.isPrimary && (_db.branch(s.branchId)?.bookable ?? false))
          .map((s) => s.price)
          .toList()
        ..sort();
      return HomeCategory(id, prices.isEmpty ? null : prices.first);
    }));
    offers.assignAll(_pricing.liveOffers().take(6));
    final uid = session.userId;
    final now = DateTime.now();
    activeOrder.value = uid == null
        ? null
        : _db.orders.firstWhereOrNull((o) =>
            o.customerId == uid && o.status.isUpcoming && FormatHelper.sameDay(o.scheduledAt, now));
    final done = uid == null
        ? <OrderModel>[]
        : (_db.orders
            .where((o) =>
                o.customerId == uid &&
                o.status == OrderStatus.completed &&
                !_db.reviews.any((r) => r.orderId == o.id))
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt)));
    unreviewed.value = done.isEmpty ? null : done.first;
    unread.value = uid == null
        ? 0
        : _db.notifications.where((n) => n.userId == uid && !n.read).length;
  }

  String branchName(String branchId) => _db.branch(branchId)?.name.value ?? '';

  String offerWashName(OfferModel offer) => offer.platform
      ? 'app.name'.tr
      : branchName(offer.branchIds.first);

  void openSearch() => Get.toNamed(Routes.searchRoute);

  void openFilters() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby', 'filters': true});

  void openWashNow() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'washnow'});

  void openCategory(String id) => Get.toNamed(Routes.resultsRoute, arguments: {'category': id});

  void openNearby() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby'});

  void openWash(String id) => Get.toNamed(Routes.washDetailsRoute, arguments: id);

  void openOffers() => Get.toNamed(Routes.offersRoute);

  void openOffer(OfferModel offer) => Get.toNamed(
        Routes.washDetailsRoute,
        arguments: offer.platform ? nearby.first.branch.id : offer.branchIds.first,
      );

  void openMap() => Get.find<MainController>().changeTab(1);

  void openProfile() => Get.find<MainController>().changeTab(3);

  void openNotifications() => Get.toNamed(Routes.notificationsRoute);

  void openOrder(OrderModel order) => Get.toNamed(Routes.bookingDetailsRoute, arguments: order.id);

  void openReview(OrderModel order) => Get.toNamed(Routes.reviewRoute, arguments: order.id);

  void pickArea() => AppBottomSheet.show(title: 'loc.title'.tr, child: const AreaPickerSheet());

  void useMyLocation() async {
    Get.back();
    final allow = await Utils.confirm(title: 'loc.ask'.tr, okText: 'loc.allow'.tr, cancelText: 'loc.deny'.tr);
    if (allow) {
      await session.setArea('nasr');
    } else {
      pickArea();
    }
  }

  Future<void> selectArea(String id) async {
    await session.setArea(id);
    Get.back();
  }
}
