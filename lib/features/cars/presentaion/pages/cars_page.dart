import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/cars_controller.dart';
import '../widgets/car_actions_menu.dart';

class CarsPage extends StatelessWidget {
  const CarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CarsController>();
    return Scaffold(
      appBar: AppTopBar(
        title: 'cars.title'.tr,
        actions: [AppIconButton(glass: true, icon: const Icon(Iconsax.add), onTap: controller.openNew)],
      ),
      body: Obx(() {
        final list = controller.vehicles;
        if (list.isEmpty) {
          return CustomEmptyState(
            icon: Iconsax.car,
            title: 'empty.cars'.tr,
            actionText: 'cars.add'.tr,
            onAction: controller.openNew,
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(20.r),
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, i) => CarTile(
            vehicle: list[i],
            onTap: () => controller.openEdit(list[i]),
            trailing: CarActionsMenu(vehicle: list[i]),
          ),
        );
      }),
    );
  }
}
