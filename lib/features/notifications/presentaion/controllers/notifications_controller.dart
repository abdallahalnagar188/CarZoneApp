import 'package:get/get.dart';

import '../../../../commons/models/notification_model.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/session_service.dart';

class NotificationsController extends GetxController {
  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get _session => Get.find<SessionService>();

  List<NotificationModel> get items => _db.notifications
      .where((n) => n.userId == _session.userId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
  }

  void open(NotificationModel n) {
    n.read = true;
    _db.notifications.refresh();
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
