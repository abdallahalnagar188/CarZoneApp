import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';
import '../controllers/wash_map_controller.dart';

class MapSideActions extends StatelessWidget {
  const MapSideActions({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashMapController>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Group(children: [
          _Action(icon: Iconsax.add, onTap: controller.zoomIn),
          Container(width: 24.w, height: 1, color: AppColors.line),
          _Action(icon: Iconsax.minus, onTap: controller.zoomOut),
        ]),
        SizedBox(height: 10.h),
        _Group(children: [_Action(icon: Iconsax.gps, onTap: controller.recenter, accent: true)]),
        SizedBox(height: 10.h),
        _Group(children: [_Action(icon: Iconsax.row_vertical, onTap: controller.openList)]),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.liftShadow,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  const _Action({required this.icon, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 46.r,
        height: 46.r,
        child: Icon(icon, size: 20.sp, color: accent ? AppColors.primary : AppColors.ink900),
      ),
    );
  }
}
