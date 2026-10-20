import 'package:flutter/material.dart';

import '../../../core/constance/app_assets.dart';

class AppLogo extends StatelessWidget {
  final double size;

  /// White mark for blue / dark brand surfaces.
  final bool onBrand;

  const AppLogo({super.key, this.size = 56, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onBrand ? AppRes.logoWhite : AppRes.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
