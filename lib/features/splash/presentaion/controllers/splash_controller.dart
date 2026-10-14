import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../../core/local/cache_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> logoScale;
  late final Animation<double> logoFade;
  late final Animation<double> textFade;
  late final Animation<Offset> textSlide;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)),
    );
    logoFade = CurvedAnimation(parent: animationController, curve: const Interval(0, 0.4, curve: Curves.easeOut));
    textFade = CurvedAnimation(parent: animationController, curve: const Interval(0.45, 1, curve: Curves.easeOut));
    textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: animationController, curve: const Interval(0.45, 1, curve: Curves.easeOutCubic)),
    );
    animationController.forward();
    _startPrewarming();
  }

  Future<void> _startPrewarming() async {
    final minDelay = Future.delayed(const Duration(milliseconds: 1800));
    final fetchFuture = Get.isRegistered<CarzoneDbService>()
        ? Get.find<CarzoneDbService>().fetchFromSupabase()
        : Future.value(true);

    // Concurrently wait for animation delay and remote pre-warm, with safety timeout
    await Future.wait([
      minDelay,
      fetchFuture.timeout(const Duration(seconds: 5), onTimeout: () => false),
    ]);

    _openNext();
  }

  void _openNext() {
    if (isClosed) return;
    Get.offAllNamed(CacheHelper.isOnboarded ? Routes.mainRoute : Routes.onboardingRoute);
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
