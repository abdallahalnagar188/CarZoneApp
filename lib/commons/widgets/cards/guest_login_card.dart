import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../icons/dir_icon.dart';

class GuestLoginCard extends StatelessWidget {
  final VoidCallback onTap;

  const GuestLoginCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(26.r),
          boxShadow: AppColors.liftShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 58.r,
              height: 58.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Icon(Iconsax.user, color: Colors.white, size: 26.sp),
            ),
            14.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('profile.login'.tr, style: theme.titleLarge?.copyWith(color: Colors.white)),
                  4.height,
                  Text('profile.guest'.tr, style: theme.bodySmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: DirIcon(Iconsax.arrow_right_3, color: Colors.white, size: 18.sp),
            ),
          ],
        ),
      ),
    );
  }
}
