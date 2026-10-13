import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/vehicle_model.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/cars_controller.dart';

class CarActionsMenu extends StatelessWidget {
  final VehicleModel vehicle;

  const CarActionsMenu({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CarsController>();
    final theme = Theme.of(context).textTheme;
    return PopupMenuButton<String>(
      icon: Icon(Iconsax.more, color: AppColors.ink500),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      onSelected: (v) {
        if (v == 'edit') controller.openEdit(vehicle);
        if (v == 'default') controller.setDefault(vehicle);
        if (v == 'delete') controller.delete(vehicle);
      },
      itemBuilder: (_) => [
        _item('edit', Iconsax.edit_2, 'cars.edit'.tr, theme),
        if (!vehicle.isDefault) _item('default', Iconsax.tick_circle, 'cars.setDefault'.tr, theme),
        _item('delete', Iconsax.trash, 'cars.delete'.tr, theme, danger: true),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label, TextTheme theme, {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.ink900;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          10.width,
          Text(label, style: theme.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
