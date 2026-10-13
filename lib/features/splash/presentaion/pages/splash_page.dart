import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/utils/system_ui.dart';
import '../../../../core/constance/app_colors.dart';
import '../controllers/splash_controller.dart';
import '../widgets/splash_brand.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand.copyWith(
        systemNavigationBarColor: AppColors.brandNight,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.heroGradient),
          child: Center(child: SplashBrand(controller: controller)),
        ),
      ),
    );
  }
}
