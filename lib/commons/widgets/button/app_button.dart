import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';

enum AppButtonVariant { primary, sand, ghost, danger }

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool loading;
  final bool small;
  final bool expanded;
  final IconData? icon;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.title,
    this.onTap,
    this.loading = false,
    this.small = false,
    this.expanded = true,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  bool get _enabled => onTap != null && !loading;

  Gradient? get _gradient {
    if (!_enabled && !loading) return AppColors.disabledGradient;
    return switch (variant) {
      AppButtonVariant.primary => AppColors.primaryGradient,
      AppButtonVariant.sand => AppColors.sandGradient,
      AppButtonVariant.danger => AppColors.dangerGradient,
      AppButtonVariant.ghost => null,
    };
  }

  Color get _foreground => switch (variant) {
        AppButtonVariant.sand => AppColors.sandInk,
        AppButtonVariant.ghost => AppColors.ink900,
        _ => Colors.white,
      };

  @override
  Widget build(BuildContext context) {
    final height = small ? 40.h : 54.h;
    final content = loading
        ? SizedBox(
            width: 22.r,
            height: 22.r,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: _foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 16.sp : 20.sp, color: variant == AppButtonVariant.ghost ? AppColors.primary : _foreground),
                8.width,
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: small ? 13.sp : 16.sp,
                        fontWeight: FontWeight.w700,
                        color: _foreground,
                      ),
                ),
              ),
            ],
          );

    return _Pressable(
      onTap: _enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: expanded ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: small ? 14.w : 20.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: _gradient,
          color: variant == AppButtonVariant.ghost ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(small ? 14.r : 18.r),
          border: variant == AppButtonVariant.ghost
              ? Border.all(color: AppColors.line, width: 1.5)
              : null,
          boxShadow: _enabled && variant == AppButtonVariant.primary
              ? AppColors.buttonShadow
              : null,
        ),
        child: content,
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        child: widget.child,
      ),
    );
  }
}
