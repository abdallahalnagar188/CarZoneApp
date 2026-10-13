import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/home_controller.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return GestureDetector(
      onTap: controller.openSearch,
      child: Container(
        padding: EdgeInsetsDirectional.only(start: 16.w, end: 8.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: AppColors.liftShadow,
        ),
        child: Row(
          children: [
            Icon(Iconsax.search_normal_1, size: 20.sp, color: AppColors.ink500),
            10.width,
            Expanded(
              child: Text(
                'search.ph'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink500),
              ),
            ),
            GestureDetector(
              onTap: controller.openFilters,
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(Iconsax.setting_4, size: 20.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
