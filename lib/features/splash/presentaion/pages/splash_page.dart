import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/local/cache_helper.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/services_providers.dart';
import '../../../../core/utils/system_ui.dart';
import '../widgets/splash_brand.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> logoScale;
  late final Animation<double> logoFade;
  late final Animation<double> textFade;
  late final Animation<Offset> textSlide;

  @override
  void initState() {
    super.initState();
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
    final db = ref.read(carzoneDbServiceProvider);
    final fetchFuture = db.fetchFromSupabase();

    await Future.wait([
      minDelay,
      fetchFuture.timeout(const Duration(seconds: 5), onTimeout: () => false),
    ]);

    if (!mounted) return;
    if (CacheHelper.isOnboarded) {
      AppNav.offAll(Routes.mainRoute);
      ref.read(deepLinkServiceProvider).markAppReady();
    } else {
      AppNav.offAll(Routes.onboardingRoute);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final background = dark ? AppColors.brandNight : Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.adaptive.copyWith(systemNavigationBarColor: background),
      child: Scaffold(
        backgroundColor: background,
        body: Center(
          child: SplashBrand(
            logoFade: logoFade,
            logoScale: logoScale,
            textFade: textFade,
            textSlide: textSlide,
          ),
        ),
      ),
    );
  }
}
