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
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = controller.grouped;
        if (groups.isEmpty && controller.error.value != null) {
          return AppErrorState(message: controller.error.value, onRetry: controller.refreshNotifications);
        }
        if (groups.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshNotifications,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120.h),
                CustomEmptyState(icon: Iconsax.notification, title: 'empty.notif'.tr),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(20.r),
            children: [
              for (final e in groups.entries) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h, top: 4.h),
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...e.value.map((n) => NotificationTile(item: n, onTap: () => controller.open(n))),
                10.height,
              ],
            ],
          ),
        );
      }),
    );
  }
}
