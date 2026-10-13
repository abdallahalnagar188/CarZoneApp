import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class SearchResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: RoundedContainer(
        onTap: onTap,
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.sp),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.titleSmall),
                  if (subtitle != null) Text(subtitle!, style: theme.bodySmall),
                ],
              ),
            ),
            DirIcon(Iconsax.arrow_right_3, color: AppColors.ink300, size: 18.sp),
          ],
        ),
      ),
    );
  }
}
