import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/utils/system_ui.dart';
import '../../../../core/constance/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: OnboardingController.count,
                itemBuilder: (_, i) => OnboardingSlide(index: i),
              ),
            ),
            const OnboardingFooter(),
          ],
        ),
      ),
    );
  }
}
