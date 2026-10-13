import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/local/cache_controller.dart';
import '../../../../core/routing/app_routes.dart';

class OnboardingController extends GetxController {
  static const int count = 3;

  final pageController = PageController();
  final index = 0.obs;

  bool get isLast => index.value == count - 1;

  void onPageChanged(int i) => index.value = i;

  void next() {
    if (isLast) {
      finish();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> finish() async {
    await CacheController().setter(key: CacheKeys.onboarded, value: true);
    Get.offAllNamed(Routes.mainRoute);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
