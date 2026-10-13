import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_assets.dart';
import '../../../core/constance/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  final String photoId;
  final int width;
  final int? height;
  final BoxFit fit;

  const AppNetworkImage({
    super.key,
    required this.photoId,
    this.width = 800,
    this.height,
    this.fit = BoxFit.cover,
  });

  static String branchPhoto(int seed, [int variant = 0]) =>
      AppRes.branchPool[(seed + variant * 5) % AppRes.branchPool.length];

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: AppRes.photo(photoId, width: width, height: height),
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => const _Fallback(),
      errorWidget: (_, __, ___) => const _Fallback(icon: true),
    );
  }
}

class _Fallback extends StatelessWidget {
  final bool icon;

  const _Fallback({this.icon = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
      child: icon
          ? Center(
              child: Icon(
                Iconsax.car,
                color: Colors.white.withValues(alpha: 0.6),
                size: 32,
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
