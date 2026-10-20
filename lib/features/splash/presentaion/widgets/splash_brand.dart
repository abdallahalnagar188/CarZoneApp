import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/logo/app_logo.dart';
import '../../../../commons/widgets/logo/app_wordmark.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/splash_controller.dart';

class SplashBrand extends StatelessWidget {
  final SplashController controller;

  const SplashBrand({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: controller.logoFade,
          child: ScaleTransition(
            scale: controller.logoScale,
            child: AppLogo(size: 120.r, onBrand: true),
          ),
        ),
        24.height,
        FadeTransition(
          opacity: controller.textFade,
          child: SlideTransition(
            position: controller.textSlide,
            child: Column(
              children: [
                AppWordmark(
                  onBrand: true,
                  style: theme.headlineLarge?.copyWith(fontSize: 34.sp),
                ),
                6.height,
                Text(
                  'splash.caption'.tr,
                  style: theme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
