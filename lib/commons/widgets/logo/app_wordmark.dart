import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constance/app_colors.dart';

/// Two-tone "Car" + "Zone" brand name, matching the logo lockup.
class AppWordmark extends StatelessWidget {
  final TextStyle? style;

  /// Light lockup for blue / dark brand surfaces.
  final bool onBrand;

  const AppWordmark({super.key, this.style, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    final base = (style ?? Theme.of(context).textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.w800);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'app.name_lead'.tr,
            style: base?.copyWith(color: onBrand ? Colors.white : AppColors.brandNight),
          ),
          TextSpan(
            text: 'app.name_tail'.tr,
            style: base?.copyWith(color: onBrand ? AppColors.glow : AppColors.brandSky),
          ),
        ],
      ),
      semanticsLabel: 'app.name'.tr,
    );
  }
}
