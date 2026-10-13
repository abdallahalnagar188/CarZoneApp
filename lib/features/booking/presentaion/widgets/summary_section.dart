import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class SummarySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  const SummarySection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return RoundedContainer(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: AppColors.primary),
              8.width,
              Expanded(child: Text(title, style: theme.labelMedium)),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Text('book.edit'.tr, style: theme.labelMedium?.copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          10.height,
          child,
        ],
      ),
    );
  }
}

class PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const PriceLine({super.key, required this.label, required this.value, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final style = bold
        ? theme.titleLarge?.copyWith(color: color ?? AppColors.primary)
        : theme.bodyMedium?.copyWith(color: color);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? theme.titleMedium : theme.bodyMedium?.copyWith(color: color ?? AppColors.ink700))),
          Text(value, style: style),
        ],
      ),
    );
  }
}
