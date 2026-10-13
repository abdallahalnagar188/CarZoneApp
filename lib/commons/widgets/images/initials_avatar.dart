import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/helpers/format_helper.dart';

class InitialsAvatar extends StatelessWidget {
  final String? name;
  final double? size;
  final bool sand;

  const InitialsAvatar({super.key, this.name, this.size, this.sand = false});

  @override
  Widget build(BuildContext context) {
    final s = size ?? 44.r;
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: sand ? AppColors.sandGradient : null,
        color: sand ? null : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(s * 0.32),
      ),
      child: Text(
        FormatHelper.initials(name),
        style: TextStyle(
          fontSize: s * 0.36,
          fontWeight: FontWeight.w700,
          color: sand ? AppColors.sandInk : AppColors.primary,
        ),
      ),
    );
  }
}
