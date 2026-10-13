import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../controllers/home_controller.dart';

class AreaPickerSheet extends StatelessWidget {
  const AreaPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final areas = Get.find<CarzoneDbService>().areas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          title: 'loc.use'.tr,
          icon: Iconsax.gps,
          variant: AppButtonVariant.sand,
          onTap: controller.useMyLocation,
        ),
        16.height,
        Text('loc.pick'.tr, style: Theme.of(context).textTheme.titleSmall),
        10.height,
        Obx(
          () => Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: areas
                .map((a) => AppChip(
                      label: a.name.value,
                      icon: Iconsax.location,
                      flat: true,
                      selected: controller.session.areaId.value == a.id,
                      onTap: () => controller.selectArea(a.id),
                    ))
                .toList(),
          ),
        ),
        8.height,
        Text(
          controller.session.area.name.value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink500),
        ),
      ],
    );
  }
}
