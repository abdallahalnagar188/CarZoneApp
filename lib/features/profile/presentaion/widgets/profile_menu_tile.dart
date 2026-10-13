import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final int badge;
  final Widget? trailing;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.badge = 0,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: AppColors.tint(color),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(icon, size: 20.sp, color: color),
            ),
            12.width,
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: danger ? AppColors.danger : null),
              ),
            ),
            if (badge > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                margin: EdgeInsetsDirectional.only(end: 8.w),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(99)),
                child: Text('$badge', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700)),
              ),
            if (trailing != null) trailing!,
            if (!danger && trailing == null) DirIcon(Iconsax.arrow_right_3, size: 18.sp, color: AppColors.ink300),
          ],
        ),
      ),
    );
  }
}
