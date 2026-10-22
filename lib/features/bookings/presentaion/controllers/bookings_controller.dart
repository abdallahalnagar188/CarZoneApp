import 'package:get/get.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/enums/enums.dart';
import '../../../main/presentaion/controllers/main_controller.dart';

class BookingsController extends GetxController {
  final tab = 0.obs;
  final upcoming = <OrderModel>[].obs;
  final history = <OrderModel>[].obs;
  final loading = false.obs;

  /// Why the last load failed; null after a successful one.
  final error = RxnString();

  Worker? _reconnect;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get session => Get.find<SessionService>();

  @override
  void onInit() {
    super.onInit();
    loadBookings();
    everAll([_db.orders, session.user], (_) => _compute());
    _reconnect = ConnectivityService.maybe?.onReconnect(loadBookings);
  }

  Future<void> loadBookings() async {
    final uid = session.userId;
    if (uid != null) {
      loading.value = true;
      try {
        await _db.fetchUserBookings(userId: uid, throwOnError: true);
        error.value = null;
      } catch (e) {
        error.value = ApiException.messageFor(e);
      } finally {
        _compute();
        loading.value = false;
      }
    } else {
      error.value = null;
      _compute();
    }
  }

  /// Pull to refresh: the list stays, a failure is shown as a toast.
  Future<void> refreshList() async {
    await loadBookings();
    final message = error.value;
    if (message != null) Utils.getSnakBar(message: message, type: TosterTypes.failed);
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

  @override
  void onClose() {
    _reconnect?.dispose();
    super.onClose();
  }
}
