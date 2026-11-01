import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';

class AppChip extends StatefulWidget {
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
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  bool _down = false;

  void _setDown(bool value) {
    if (widget.onTap != null) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final flat = widget.flat;
    final icon = widget.icon;
    final fg = selected
        ? Colors.white
        : flat
            ? AppColors.ink700
            : AppColors.primary;
    return GestureDetector(
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : (flat ? AppColors.surface : AppColors.primarySoft),
            borderRadius: BorderRadius.circular(99),
            border: flat && !selected ? Border.all(color: AppColors.line, width: 1.5) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15.sp, color: selected ? Colors.white : AppColors.primary),
                6.width,
              ],
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
