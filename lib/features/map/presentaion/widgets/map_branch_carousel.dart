import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/wash_map_controller.dart';

class MapBranchCarousel extends StatelessWidget {
  const MapBranchCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashMapController>();
    return Obx(() {
      if (controller.rows.isEmpty) {
        return Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(99),
              boxShadow: AppColors.liftShadow,
            ),
            child: Text('empty.results'.tr, style: Theme.of(context).textTheme.titleSmall),
          ),
        );
      }
      return PageView.builder(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        itemCount: controller.rows.length,
        itemBuilder: (_, i) => Obx(
          () => AnimatedScale(
            scale: controller.selected.value == i ? 1 : 0.94,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
              child: _BranchCard(row: controller.rows[i]),
            ),
          ),
        ),
      );
    });
  }
}

class _BranchCard extends StatelessWidget {
  final BranchListingModel row;

  const _BranchCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashMapController>();
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => controller.openWash(row.branch.id),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: AppColors.liftShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: SizedBox(
                width: 96.w,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(photoId: AppNetworkImage.branchPhoto(row.branch.photoSeed), width: 320),
                    PositionedDirectional(
                      top: 6.h,
                      start: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.star1, size: 11.sp, color: AppColors.star),
                            3.width,
                            Text(
                              row.rating.toStringAsFixed(1),
                              style: theme.labelSmall?.copyWith(color: AppColors.brandNight, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.branch.name.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.titleSmall),
                  Row(
                    children: [
                      Icon(Iconsax.location, size: 13.sp, color: AppColors.ink500),
                      4.width,
                      Text(FormatHelper.distance(row.km), style: theme.labelMedium),
                      10.width,
                      Icon(Iconsax.clock, size: 13.sp, color: AppColors.primary),
                      4.width,
                      Flexible(
                        child: Text(
                          row.nextSlot == null ? '—' : FormatHelper.time(row.nextSlot!),
                          maxLines: 1,
                          style: theme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.fromPrice == null ? '' : FormatHelper.money(row.fromPrice!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.directions(row),
                        child: Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Iconsax.routing, size: 18.sp, color: AppColors.primary),
                        ),
                      ),
                      8.width,
                      AppButton(
                        title: 'wash.book'.tr,
                        small: true,
                        expanded: false,
                        onTap: () => controller.openWash(row.branch.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
