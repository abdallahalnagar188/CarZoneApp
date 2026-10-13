import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/wash_map_controller.dart';

class MapTopBar extends StatelessWidget {
  const MapTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashMapController>();
    final theme = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: controller.openSearch,
                  child: Container(
                    height: 54.h,
                    padding: EdgeInsetsDirectional.only(start: 8.w, end: 14.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppColors.liftShadow,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: controller.pickArea,
                          child: Container(
                            height: 40.h,
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.location, size: 16.sp, color: Colors.white),
                                6.width,
                                Obx(
                                  () => Text(
                                    controller.session.area.name.value,
                                    style: theme.labelLarge?.copyWith(color: Colors.white),
                                  ),
                                ),
                                4.width,
                                Icon(Iconsax.arrow_down_1, size: 13.sp, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        12.width,
                        Expanded(
                          child: Text(
                            'search.ph'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall?.copyWith(fontSize: 13.sp),
                          ),
                        ),
                        Icon(Iconsax.search_normal_1, size: 20.sp, color: AppColors.ink500),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        12.height,
        SizedBox(
          height: 38.h,
          child: Obx(() {
            final f = controller.filter.value;
            final items = [
              (MapFilter.all, 'f.any'.tr, Iconsax.element_3),
              (MapFilter.open, 'f.open'.tr, Iconsax.clock),
              (MapFilter.rated, '4.5+', Iconsax.star_1),
              (MapFilter.washNow, 'home.washNow'.tr, Iconsax.flash_1),
            ];
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: items.length,
              separatorBuilder: (_, __) => 8.width,
              itemBuilder: (_, i) {
                final (value, label, icon) = items[i];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: f == value ? null : AppColors.softShadow,
                  ),
                  child: AppChip(
                    label: label,
                    icon: icon,
                    flat: true,
                    selected: f == value,
                    onTap: () => controller.setFilter(value),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
