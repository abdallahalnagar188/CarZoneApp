import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/report_controller.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'report.title'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          Text('report.cat'.tr, style: theme.titleSmall),
          10.height,
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: ReportController.categories
                  .map((c) => AppChip(
                        label: 'cat.$c'.tr,
                        flat: true,
                        selected: controller.category.value == c,
                        onTap: () => controller.setCategory(c),
                      ))
                  .toList(),
            ),
          ),
          20.height,
          Obx(
            () => AppTextField(
              controller: controller.descriptionController,
              label: 'report.desc'.tr,
              maxLines: 5,
              maxLength: 600,
              error: controller.error.value,
              onChanged: (_) => controller.error.value = null,
            ),
          ),
          28.height,
          Obx(
            () => AppButton(
              title: 'report.send'.tr,
              loading: controller.sending.value,
              onTap: controller.submit,
            ),
          ),
        ],
      ),
    );
  }
}
