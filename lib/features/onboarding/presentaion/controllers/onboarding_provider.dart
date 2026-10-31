import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/local/cache_controller.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/services_providers.dart';

class OnboardingNotifier extends StateNotifier<int> {
  OnboardingNotifier() : super(0);

  static const int count = 3;
  final pageController = PageController();

  bool get isLast => state == count - 1;

  void onPageChanged(int i) => state = i;

  void next(WidgetRef ref) {
    if (isLast) {
      finish(ref);
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> finish(WidgetRef ref) async {
    await CacheController().setter(key: CacheKeys.onboarded, value: true);
    AppNav.offAll(Routes.mainRoute);
    ref.read(deepLinkServiceProvider).markAppReady();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

final onboardingProvider = StateNotifierProvider.autoDispose<OnboardingNotifier, int>((ref) {
  return OnboardingNotifier();
});

