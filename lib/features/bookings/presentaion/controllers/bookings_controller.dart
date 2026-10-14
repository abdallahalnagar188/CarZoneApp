import 'package:get/get.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../main/presentaion/controllers/main_controller.dart';

class BookingsController extends GetxController {
  final tab = 0.obs;
  final upcoming = <OrderModel>[].obs;
  final history = <OrderModel>[].obs;
  final loading = false.obs;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get session => Get.find<SessionService>();

  @override
  void onInit() {
    super.onInit();
    _compute();
    everAll([_db.orders, session.user], (_) => _compute());
  }

  Future<void> refreshList() async {
    loading.value = true;
    await _db.fetchFromSupabase();
    _compute();
    loading.value = false;
  }

  void _compute() {
    final uid = session.userId;
    final mine = uid == null ? <OrderModel>[] : _db.orders.where((o) => o.customerId == uid).toList();
    upcoming.assignAll(mine.where((o) => o.status.isUpcoming).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));
    history.assignAll(mine.where((o) => !o.status.isUpcoming).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt)));
  }

  String branchName(OrderModel o) => _db.branch(o.branchId)?.name.value ?? '';

  void setTab(int i) => tab.value = i;

  void open(OrderModel o) => Get.toNamed(Routes.bookingDetailsRoute, arguments: o.id);

  void login() => AuthGuard.run(() {});

  void bookWash() => Get.find<MainController>().changeTab(0);
}
