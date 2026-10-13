import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class MapBranchCard extends StatelessWidget {
  final BranchListingModel row;
  final VoidCallback onTap;

  const MapBranchCard({super.key, required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: AppColors.liftShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: SizedBox(
                width: 88.r,
                height: 92.r,
                child: AppNetworkImage(photoId: AppNetworkImage.branchPhoto(row.branch.photoSeed), width: 300),
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.branch.name.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.titleSmall),
                  4.height,
                  Row(
                    children: [
                      Icon(Iconsax.star1, size: 13.sp, color: AppColors.star),
                      4.width,
                      Text(row.rating.toStringAsFixed(1), style: theme.labelMedium?.copyWith(color: AppColors.ink900)),
                      8.width,
                      Icon(Iconsax.location, size: 13.sp, color: AppColors.ink500),
                      4.width,
                      Text(FormatHelper.distance(row.km), style: theme.labelMedium),
                    ],
                  ),
                  6.height,
                  Row(
                    children: [
                      Icon(Iconsax.clock, size: 13.sp, color: AppColors.primary),
                      4.width,
                      Expanded(
                        child: Text(
                          row.nextSlot == null ? '—' : 'nextSlot'.trParams({'time': FormatHelper.time(row.nextSlot!)}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelMedium?.copyWith(color: AppColors.primary),
                        ),
                      ),
                      if (row.fromPrice != null)
                        Text(
                          FormatHelper.money(row.fromPrice!),
                          style: theme.titleSmall?.copyWith(color: AppColors.primary),
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
