import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../button/app_button.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String? body;
  final String okText;
  final String cancelText;
  final bool danger;

  const AppConfirmDialog({
    super.key,
    required this.title,
    this.body,
    required this.okText,
    required this.cancelText,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.danger : AppColors.primary;
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      child: Padding(
        padding: EdgeInsets.all(22.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                color: AppColors.tint(accent),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(danger ? Iconsax.warning_2 : Iconsax.info_circle, color: accent, size: 28.sp),
            ),
            16.height,
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            if (body != null) ...[
              8.height,
              Text(body!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13.sp)),
            ],
            22.height,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: cancelText,
                    variant: AppButtonVariant.ghost,
                    onTap: () => Get.back(result: false),
                  ),
                ),
                12.width,
                Expanded(
                  child: AppButton(
                    title: okText,
                    variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
                    onTap: () => Get.back(result: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
