import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    return Scaffold(
      appBar: AppTopBar(
        title: 'notif.title'.tr,
        actions: [AppIconButton(glass: true, icon: const Icon(Iconsax.tick_square), onTap: controller.markAllRead)],
      ),
      body: Obx(() {
        final groups = controller.grouped;
        if (groups.isEmpty) {
          return CustomEmptyState(icon: Iconsax.notification, title: 'empty.notif'.tr);
        }
        return ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            for (final e in groups.entries) ...[
              Text(e.key, style: Theme.of(context).textTheme.titleSmall),
              10.height,
              ...e.value.map((n) => NotificationTile(item: n, onTap: () => controller.open(n))),
              10.height,
            ],
          ],
        );
      }),
    );
  }
}
