import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../../../core/helpers/format_helper.dart';
import '../../models/branch_listing_model.dart';
import '../images/app_network_image.dart';

class WashCard extends StatelessWidget {
  final BranchListingModel row;
  final bool favorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final double? width;

  const WashCard({
    super.key,
    required this.row,
    this.favorite = false,
    this.onTap,
    this.onFavorite,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final b = row.branch;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.line),
          boxShadow: AppColors.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 128.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(photoId: AppNetworkImage.branchPhoto(b.photoSeed), width: 600),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.brandNight.withValues(alpha: 0.35)],
                      ),
                    ),
                  ),
                  if (b.featured)
                    PositionedDirectional(
                      top: 10.h,
                      start: 10.w,
                      child: _Pill(
                        color: AppColors.sand,
                        child: Text(
                          'sponsored'.tr,
                          style: theme.labelSmall?.copyWith(color: AppColors.sandInk, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: 10.h,
                    end: 10.w,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: Icon(
                            favorite ? Iconsax.heart5 : Iconsax.heart,
                            key: ValueKey(favorite),
                            size: 18.sp,
                            color: favorite ? AppColors.danger : AppColors.ink900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 10.h,
                    end: 10.w,
                    child: _Pill(
                      color: Colors.white.withValues(alpha: 0.94),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.star1, size: 13.sp, color: AppColors.star),
                          4.width,
                          Text(
                            row.rating.toStringAsFixed(1),
                            style: theme.labelMedium?.copyWith(color: AppColors.brandNight, fontWeight: FontWeight.w700),
                          ),
                          4.width,
                          Text(
                            '(${row.reviewCount})',
                            style: theme.labelSmall?.copyWith(color: const Color(0xFF5F7686)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  6.height,
                  Row(
                    children: [
                      Icon(Iconsax.location, size: 14.sp, color: AppColors.ink500),
                      4.width,
                      Text(FormatHelper.distance(row.km), style: theme.bodySmall),
                      8.width,
                      _OpenPill(open: row.open),
                    ],
                  ),
                  10.height,
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.clock, size: 13.sp, color: AppColors.primary),
                            4.width,
                            Text(
                              row.nextSlot == null ? '—' : FormatHelper.time(row.nextSlot!),
                              style: theme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (row.fromPrice != null)
                        Text(
                          FormatHelper.money(row.fromPrice!),
                          style: theme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
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

class _Pill extends StatelessWidget {
  final Widget child;
  final Color color;

  const _Pill({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
      child: child,
    );
  }
}

class _OpenPill extends StatelessWidget {
  final bool open;

  const _OpenPill({required this.open});

  @override
  Widget build(BuildContext context) {
    final color = open ? AppColors.success : AppColors.ink500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.tint(color),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6.r, height: 6.r, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          4.width,
          Text(
            (open ? 'open' : 'closed').tr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
