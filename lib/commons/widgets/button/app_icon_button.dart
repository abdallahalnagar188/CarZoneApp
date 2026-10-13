import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';

class AppIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final bool glass;
  final double? size;
  final int badge;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.glass = false,
    this.size,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final s = size ?? 42.r;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: s,
            height: s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: glass ? Colors.white.withValues(alpha: 0.16) : AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: glass
                  ? Border.all(color: Colors.white.withValues(alpha: 0.28))
                  : null,
              boxShadow: glass ? null : AppColors.softShadow,
            ),
            child: IconTheme(
              data: IconThemeData(
                size: 20.sp,
                color: glass ? Colors.white : AppColors.ink900,
              ),
              child: icon,
            ),
          ),
          if (badge > 0)
            PositionedDirectional(
              top: -4.r,
              end: -4.r,
              child: Container(
                constraints: BoxConstraints(minWidth: 18.r),
                height: 18.r,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(9.r),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
