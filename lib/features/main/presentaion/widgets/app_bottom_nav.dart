import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/main_controller.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const _items = [
    (Iconsax.home_2, 'nav.home'),
    (Iconsax.map, 'nav.map'),
    (Iconsax.calendar_1, 'nav.bookings'),
    (Iconsax.user, 'nav.profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 76.h + bottom + 18.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 76.h + bottom,
            padding: EdgeInsets.only(bottom: bottom),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Obx(
              () => Row(
                children: [
                  for (var i = 0; i < 2; i++) _tab(context, controller, i),
                  SizedBox(width: 76.w),
                  for (var i = 2; i < 4; i++) _tab(context, controller, i),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: controller.openWashNow,
              child: Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 5),
                  boxShadow: AppColors.buttonShadow,
                ),
                child: Icon(Iconsax.magic_star, color: Colors.white, size: 26.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, MainController controller, int i) {
    final on = controller.selectedIndex.value == i;
    final (icon, label) = _items[i];
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.changeTab(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              padding: EdgeInsets.symmetric(horizontal: on ? 16.w : 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: on ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Icon(icon, size: 22.sp, color: on ? AppColors.primary : AppColors.ink500),
            ),
            4.height,
            Text(
              label.tr,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: on ? AppColors.primary : AppColors.ink500,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
