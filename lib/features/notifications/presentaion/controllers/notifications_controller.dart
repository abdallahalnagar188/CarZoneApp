import 'package:get/get.dart';

import '../../../../commons/models/notification_model.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/session_service.dart';

class NotificationsController extends GetxController {
  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get _session => Get.find<SessionService>();

  final isLoading = false.obs;

  /// Why the last refresh failed; null after a successful one.
  final error = RxnString();

  Worker? _reconnect;

  @override
  void onInit() {
    super.onInit();
    refreshNotifications();
    _reconnect = ConnectivityService.maybe?.onReconnect(refreshNotifications);
  }

  @override
  void onClose() {
    _reconnect?.dispose();
    super.onClose();
  }

  Future<void> refreshNotifications() async {
    final custId = _session.user.value?.id ?? _session.userId;
    if (custId != null && custId.isNotEmpty) {
      isLoading.value = true;
      try {
        await _db.fetchNotifications(custId, throwOnError: true);
        error.value = null;
      } catch (e) {
        error.value = ApiException.messageFor(e);
      } finally {
        isLoading.value = false;
      }
    }
  }

  List<NotificationModel> get items {
    final currentCustId = _session.user.value?.id;
    final currentAuthId = _session.userId;
    return _db.notifications
        .where((n) =>
            (currentCustId != null && n.userId == currentCustId) ||
            (currentAuthId != null && n.userId == currentAuthId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get unreadCount => items.where((n) => !n.read).length;

  Map<String, List<NotificationModel>> get grouped {
    final map = <String, List<NotificationModel>>{};
    for (final n in items) {
      map.putIfAbsent(FormatHelper.relativeDay(n.createdAt), () => []).add(n);
    }
    return map;
  }

  void markAllRead() {
    for (final n in items) {
      n.read = true;
    }
    _db.notifications.refresh();
    final uid = _session.user.value?.id ?? _session.userId;
    if (uid != null) {
      _db.markAllNotificationsRead(uid);
    }
  }

  void open(NotificationModel n) {
    n.read = true;
    _db.notifications.refresh();
    _db.markNotificationRead(n.id);
    if (n.orderId != null) {
      final order = _db.order(n.orderId!);
      if (n.type == 'review_reminder' && order != null && !_db.reviews.any((r) => r.orderId == order.id)) {
        Get.toNamed(Routes.reviewRoute, arguments: order.id);
      } else {
        Get.toNamed(Routes.bookingDetailsRoute, arguments: n.orderId);
      }
    } else if (n.type == 'offer') {
      Get.toNamed(Routes.offersRoute);
    }
  }
}

