import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';

class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool flat;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.flat = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : flat
            ? AppColors.ink700
            : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : (flat ? AppColors.surface : AppColors.primarySoft),
          borderRadius: BorderRadius.circular(99),
          border: flat && !selected ? Border.all(color: AppColors.line, width: 1.5) : null,
          boxShadow: selected ? AppColors.buttonShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15.sp, color: selected ? Colors.white : AppColors.primary),
              6.width,
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
