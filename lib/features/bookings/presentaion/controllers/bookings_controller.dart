import 'package:get/get.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/washup_db_service.dart';
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

  /// Older pages of orders (GAP-039): the next one loads near the list end.
  final loadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 0;
  DateTime? _moreFailedAt;

  /// Why the last load failed; null after a successful one.
  final error = RxnString();

  final _workers = <Worker>[];

  WashUpDbService get _db => Get.find<WashUpDbService>();
  SessionService get session => Get.find<SessionService>();

  @override
  void onInit() {
    super.onInit();
    loadBookings();
    _workers.add(everAll([_db.orders, session.user], (_) => _compute()));
    final reconnect = ConnectivityService.maybe?.onReconnect(loadBookings);
    if (reconnect != null) _workers.add(reconnect);
  }

  Future<void> loadBookings() async {
    final uid = session.userId;
    if (uid != null) {
      loading.value = true;
      try {
        final first = await _db.fetchUserBookings(userId: uid, throwOnError: true);
        _page = 0;
        hasMore.value = first.length >= WashUpDbService.bookingsPageSize;
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

  /// The next page of older orders; a failure is shown as a toast and the
  /// next scroll tries again.
  Future<void> loadMore() async {
    final uid = session.userId;
    if (uid == null || !hasMore.value || loading.value || loadingMore.value) return;
    // Scrolling keeps asking; after a failure wait a little before trying again.
    final failedAt = _moreFailedAt;
    if (failedAt != null && DateTime.now().difference(failedAt) < const Duration(seconds: 5)) return;
    loadingMore.value = true;
    try {
      final next = await _db.fetchUserBookings(userId: uid, page: _page + 1, throwOnError: true);
      _page++;
      hasMore.value = next.length >= WashUpDbService.bookingsPageSize;
    } catch (e) {
      _moreFailedAt = DateTime.now();
      Utils.getSnakBar(message: ApiException.messageFor(e), type: TosterTypes.failed);
    } finally {
      loadingMore.value = false;
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
    for (final w in _workers) {
      w.dispose();
    }
    _workers.clear();
    super.onClose();
  }
}
