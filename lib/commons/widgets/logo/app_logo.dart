import 'package:flutter/material.dart';

import '../../../core/constance/app_assets.dart';

/// The Wash Up "W" ribbon mark.
class AppLogo extends StatelessWidget {
  /// Width of the mark; the height follows the logo's aspect ratio.
  final double size;

  /// White mark for blue / dark brand surfaces.
  final bool onBrand;

  const AppLogo({super.key, this.size = 56, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onBrand ? AppRes.logoWhite : AppRes.logo,
      width: size,
      height: size / AppRes.markAspect,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
