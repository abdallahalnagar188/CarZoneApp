import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../../models/vehicle_model.dart';

class PlateBadge extends StatelessWidget {
  final String plate;

  const PlateBadge({super.key, required this.plate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.ink900, width: 1.4),
      ),
      child: Text(
        plate,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: AppColors.ink900,
        ),
      ),
    );
  }
}

class CarAvatar extends StatelessWidget {
  final Color color;
  final double? size;

  const CarAvatar({super.key, required this.color, this.size});

  @override
  Widget build(BuildContext context) {
    final s = size ?? 56.r;
    final light = color.computeLuminance() > 0.6;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18.r),
      ),
      alignment: Alignment.center,
      child: Container(
        width: s * 0.66,
        height: s * 0.66,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: light ? AppColors.ink300 : color, width: 1.2),
        ),
        child: Icon(Iconsax.car, size: s * 0.36, color: light ? AppColors.brand : Colors.white),
      ),
    );
  }
}

class CarTile extends StatelessWidget {
  final VehicleModel vehicle;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CarTile({
    super.key,
    required this.vehicle,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            CarAvatar(color: vehicle.swatch),
            14.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(vehicle.title, style: theme.titleMedium, overflow: TextOverflow.ellipsis),
                      ),
                      if (vehicle.isDefault) ...[
                        8.width,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'book.default'.tr,
                            style: theme.labelSmall?.copyWith(color: AppColors.secondaryInk),
                          ),
                        ),
                      ],
                    ],
                  ),
                  6.height,
                  Row(
                    children: [
                      PlateBadge(plate: vehicle.plate),
                      if (vehicle.year != null) ...[
                        8.width,
                        Text('${vehicle.year}', style: theme.bodySmall),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(
                selected ? Iconsax.tick_circle5 : Iconsax.record,
                color: selected ? AppColors.primary : AppColors.ink300,
                size: 22.sp,
              ),
          ],
        ),
      ),
    );
  }
}
