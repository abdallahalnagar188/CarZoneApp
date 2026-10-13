import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_assets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/home_controller.dart';

class ServiceCategoriesGrid extends StatelessWidget {
  const ServiceCategoriesGrid({super.key});

  static const icons = {
    'exterior': Iconsax.cloud_drizzle,
    'interior': Iconsax.magic_star,
    'full': Iconsax.car,
    'deep': Iconsax.wind_2,
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final theme = Theme.of(context).textTheme;
    return Obx(
      () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.2,
        children: controller.categories.map((c) {
          return GestureDetector(
            onTap: () => controller.openCategory(c.id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: AppColors.softShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(photoId: AppRes.category[c.id]!, width: 500, height: 360),
                  DecoratedBox(decoration: BoxDecoration(gradient: AppColors.photoShade)),
                  PositionedDirectional(
                    top: 10.h,
                    end: 10.w,
                    child: Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Icon(icons[c.id], size: 18.sp, color: Colors.white),
                    ),
                  ),
                  PositionedDirectional(
                    start: 12.w,
                    end: 12.w,
                    bottom: 10.h,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('cat.${c.id}'.tr, style: theme.titleMedium?.copyWith(color: Colors.white)),
                        if (c.from != null)
                          Text(
                            'home.from'.trParams({'price': FormatHelper.money(c.from!)}),
                            style: theme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
