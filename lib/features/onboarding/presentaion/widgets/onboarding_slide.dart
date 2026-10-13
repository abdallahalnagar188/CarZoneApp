import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/images/app_network_image.dart';
import '../../../../commons/widgets/logo/app_logo.dart';
import '../../../../core/constance/app_assets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingSlide extends StatelessWidget {
  final int index;

  const OnboardingSlide({super.key, required this.index});

  static const _icons = [Iconsax.location, Iconsax.calendar_tick, Iconsax.scan_barcode];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final n = index + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36.r)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(photoId: AppRes.onboarding[index], width: 900),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.brandNight.withValues(alpha: 0.55),
                        AppColors.brand.withValues(alpha: 0.35),
                        AppColors.brandNight.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Column(
                      children: [
                        const _TopRow(),
                        const Spacer(),
                        _ArtBadge(icon: _icons[index]),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '0$n / 0${OnboardingController.count}',
                  textDirection: TextDirection.ltr,
                  style: theme.labelMedium?.copyWith(color: AppColors.sandInk, fontWeight: FontWeight.w700),
                ),
              ),
              14.height,
              Text('onb.$n.t'.tr, style: theme.headlineLarge?.copyWith(fontSize: 26.sp)),
              10.height,
              Text('onb.$n.d'.tr, style: theme.bodyMedium?.copyWith(color: AppColors.ink500, fontSize: 15.sp)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return Row(
      children: [
        AppLogo(size: 30.r),
        8.width,
        Text(
          'app.name'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        const Spacer(),
        Obx(
          () => AnimatedOpacity(
            opacity: controller.isLast ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: controller.isLast ? null : controller.finish,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'onb.skip'.tr,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtBadge extends StatelessWidget {
  final IconData icon;

  const _ArtBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132.r,
      height: 132.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 88.r,
        height: 88.r,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: AppColors.liftShadow,
        ),
        child: Icon(icon, size: 40.sp, color: AppColors.brand),
      ),
    );
  }
}
