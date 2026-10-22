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
    // Matches the native launch screen (white, navy in dark mode) so the
    // mark carries straight over from it.
    final dark = AppColors.isDark;
    final background = dark ? AppColors.brandNight : Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.adaptive.copyWith(systemNavigationBarColor: background),
      child: Scaffold(
        backgroundColor: background,
        body: Center(child: SplashBrand(controller: controller)),
      ),
    );
  }
}
