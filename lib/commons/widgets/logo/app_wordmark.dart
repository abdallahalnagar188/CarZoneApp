import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constance/app_assets.dart';

/// The "WASHUP" wordmark from the logo lockup. It is a logotype, so it stays
/// in Latin letters in both languages; screen readers get the localized name.
class AppWordmark extends StatelessWidget {
  final double height;

  /// Light lockup for blue / dark brand surfaces.
  final bool onBrand;

  const AppWordmark({super.key, this.height = 20, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'app.name'.tr,
      image: true,
      child: Image.asset(
        onBrand ? AppRes.wordmarkWhite : AppRes.wordmark,
        height: height,
        width: height * AppRes.wordmarkAspect,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
