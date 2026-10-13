import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_assets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/home_controller.dart';

class WashNowHero extends StatelessWidget {
  const WashNowHero({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: controller.openWashNow,
      child: Container(
        height: 196.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: AppColors.liftShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AppNetworkImage(photoId: AppRes.hero, width: 900),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    AppColors.brandNight.withValues(alpha: 0.9),
                    AppColors.brand.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.flash_1, size: 14.sp, color: AppColors.sand),
                        6.width,
                        Text('home.fast'.tr, style: theme.labelSmall?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('home.washNow'.tr, style: theme.headlineLarge?.copyWith(color: Colors.white, fontSize: 30.sp)),
                  Text(
                    'home.washNowSub'.tr,
                    style: theme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  12.height,
                  Container(
                    padding: EdgeInsetsDirectional.only(start: 16.w, end: 6.w, top: 6.h, bottom: 6.h),
                    decoration: BoxDecoration(
                      gradient: AppColors.sandGradient,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'home.washNowCta'.tr,
                          style: theme.labelLarge?.copyWith(color: AppColors.sandInk),
                        ),
                        10.width,
                        Container(
                          width: 30.r,
                          height: 30.r,
                          decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                          child: DirIcon(Iconsax.arrow_right_3, size: 16.sp, color: Colors.white),
                        ),
                      ],
                    ),
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
