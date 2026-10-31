import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/utils/system_ui.dart';
import '../controllers/onboarding_provider.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(onboardingProvider.notifier);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: notifier.pageController,
                onPageChanged: notifier.onPageChanged,
                itemCount: OnboardingNotifier.count,
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
