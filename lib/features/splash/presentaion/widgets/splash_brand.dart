import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/logo/app_logo.dart';
import '../../../../commons/widgets/logo/app_wordmark.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/splash_controller.dart';

class SplashBrand extends StatelessWidget {
  final SplashController controller;

  const SplashBrand({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final dark = AppColors.isDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: controller.logoFade,
          child: ScaleTransition(
            scale: controller.logoScale,
            child: AppLogo(size: 160.r),
          ),
        ),
        24.height,
        FadeTransition(
          opacity: controller.textFade,
          child: SlideTransition(
            position: controller.textSlide,
            child: Column(
              children: [
                AppWordmark(height: 30.r, onBrand: dark),
                12.height,
                Text(
                  'splash.caption'.tr,
                  style: theme.bodyMedium?.copyWith(color: dark ? const Color(0xFFC8D4EA) : AppColors.ink500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
