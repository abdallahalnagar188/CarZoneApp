import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_option.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'profile.legal'.tr),
      body: Obx(
        () => ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            Row(
              children: [
                SegmentOption(
                  label: 'legal.terms'.tr,
                  selected: controller.legalTab.value == 0,
                  onTap: () => controller.setLegalTab(0),
                ),
                10.width,
                SegmentOption(
                  label: 'legal.privacy'.tr,
                  selected: controller.legalTab.value == 1,
                  onTap: () => controller.setLegalTab(1),
                ),
              ],
            ),
            20.height,
            RoundedContainer(
              child: Text(
                (controller.legalTab.value == 0 ? 'legal.termsBody' : 'legal.privacyBody').tr,
                style: theme.bodyMedium?.copyWith(color: AppColors.ink700, height: 1.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
