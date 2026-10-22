import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../button/app_button.dart';

class CustomEmptyState extends StatelessWidget {
  final String title;
  final String? body;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryText;
  final VoidCallback? onSecondary;

  /// Icon tint; brand blue by default, a state color for errors.
  final Color? color;

  const CustomEmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon = Iconsax.magic_star,
    this.actionText,
    this.onAction,
    this.secondaryText,
    this.onSecondary,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88.r,
              height: 88.r,
              decoration: BoxDecoration(
                color: color == null ? AppColors.primarySoft : AppColors.tint(color!),
                borderRadius: BorderRadius.circular(28.r),
              ),
              child: Icon(icon, size: 38.sp, color: color ?? AppColors.primary),
            ),
            20.height,
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (body != null) ...[
              8.height,
              Text(
                body!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 13.sp),
              ),
            ],
            if (actionText != null) ...[
              20.height,
              AppButton(title: actionText!, onTap: onAction, expanded: false),
            ],
            if (secondaryText != null) ...[
              10.height,
              AppButton(
                title: secondaryText!,
                onTap: onSecondary,
                expanded: false,
                small: true,
                variant: AppButtonVariant.ghost,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
