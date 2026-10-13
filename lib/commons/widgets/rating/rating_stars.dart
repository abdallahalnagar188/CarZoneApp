import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';

class RatingStars extends StatelessWidget {
  final int value;
  final double? size;
  final ValueChanged<int>? onChanged;

  const RatingStars({super.key, required this.value, this.size, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final on = i < value;
        final icon = Icon(
          on ? Iconsax.star_1 : Iconsax.star,
          size: size ?? 16.sp,
          color: on ? AppColors.star : AppColors.ink300,
        );
        if (onChanged == null) return icon;
        return GestureDetector(
          onTap: () => onChanged!(i + 1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: AnimatedScale(
              scale: on ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              child: icon,
            ),
          ),
        );
      }),
    );
  }
}
