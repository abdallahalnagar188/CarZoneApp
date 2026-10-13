import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/offer_model.dart';
import '../../../../commons/models/wash_service_model.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class ServiceOptionTile extends StatelessWidget {
  final WashServiceModel service;
  final bool selected;
  final OfferModel? offer;
  final VoidCallback onTap;

  const ServiceOptionTile({
    super.key,
    required this.service,
    required this.selected,
    required this.onTap,
    this.offer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 1.8 : 1),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Iconsax.tick_circle5 : Iconsax.record,
              color: selected ? AppColors.primary : AppColors.ink300,
              size: 22.sp,
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name.value, style: theme.titleMedium),
                  Text(service.description.value, style: theme.bodySmall),
                  if (offer != null)
                    Text(
                      'book.offer'.trParams({'v': offer!.offerLabel}),
                      style: theme.labelMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatHelper.money(service.price),
                  style: theme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
                4.height,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.surface : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    FormatHelper.minutes(service.durationMin),
                    style: theme.labelSmall?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddonTile extends StatelessWidget {
  final WashServiceModel service;
  final bool selected;
  final VoidCallback onTap;

  const AddonTile({super.key, required this.service, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(8.r),
                border: selected ? null : Border.all(color: AppColors.ink300, width: 1.5),
              ),
              child: selected ? Icon(Iconsax.check, size: 15.sp, color: Colors.white) : null,
            ),
            12.width,
            Expanded(child: Text(service.name.value, style: theme.bodyLarge)),
            Text('+${FormatHelper.money(service.price)}', style: theme.titleSmall),
          ],
        ),
      ),
    );
  }
}
