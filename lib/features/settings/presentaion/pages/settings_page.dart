import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_option.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'settings.title'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          Text('settings.lang'.tr, style: theme.titleMedium),
          10.height,
          GetBuilder<SettingsController>(
            builder: (_) => Row(
              children: [
                SegmentOption(
                  label: 'settings.ar'.tr,
                  selected: controller.isArabic,
                  onTap: () => controller.setLanguage('ar'),
                ),
                10.width,
                SegmentOption(
                  label: 'settings.en'.tr,
                  selected: !controller.isArabic,
                  onTap: () => controller.setLanguage('en'),
                ),
              ],
            ),
          ),
          24.height,
          Text('settings.theme'.tr, style: theme.titleMedium),
          10.height,
          Obx(
            () => Row(
              children: [
                SegmentOption(
                  label: 'settings.light'.tr,
                  selected: !controller.theme.isDarkMode.value,
                  onTap: () => controller.setDark(false),
                ),
                10.width,
                SegmentOption(
                  label: 'settings.dark'.tr,
                  selected: controller.theme.isDarkMode.value,
                  onTap: () => controller.setDark(true),
                ),
              ],
            ),
          ),
          24.height,
          Text('notif.title'.tr, style: theme.titleMedium),
          10.height,
          RoundedContainer(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Obx(
              () => Column(
                children: [
                  SettingsSwitchTile(
                    icon: Iconsax.clock,
                    title: 'settings.reminders'.tr,
                    value: controller.reminders.value,
                    onChanged: controller.setReminders,
                  ),
                  SettingsSwitchTile(
                    icon: Iconsax.ticket_discount,
                    title: 'settings.offers'.tr,
                    value: controller.offers.value,
                    onChanged: controller.setOffers,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
