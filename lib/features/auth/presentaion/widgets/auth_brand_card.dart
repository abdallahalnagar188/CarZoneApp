import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/logo/app_logo.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class AuthBrandCard extends StatelessWidget {
  const AuthBrandCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: AppColors.sandGradient,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.secondaryStrong.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          AppLogo(size: 52.r),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('app.name'.tr, style: theme.headlineSmall?.copyWith(color: AppColors.brandNight)),
                Text('app.tagline'.tr, style: theme.bodySmall?.copyWith(color: AppColors.sandInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
