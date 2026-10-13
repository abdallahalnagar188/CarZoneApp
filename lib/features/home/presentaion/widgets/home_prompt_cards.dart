import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/home_controller.dart';

class HomePromptCards extends StatelessWidget {
  const HomePromptCards({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final active = controller.activeOrder.value;
      final review = controller.unreviewed.value;
      return Column(
        children: [
          if (active != null)
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: RoundedContainer(
                onTap: () => controller.openOrder(active),
                child: Row(
                  children: [
                    _Lead(icon: Iconsax.car),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('home.active'.tr, style: theme.bodySmall),
                          Text(active.number, style: theme.titleMedium),
                          6.height,
                          StatusBadge.order(active.status),
                        ],
                      ),
                    ),
                    DirIcon(Iconsax.arrow_right_3, color: AppColors.ink500, size: 18.sp),
                  ],
                ),
              ),
            ),
          if (review != null)
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: RoundedContainer(
                onTap: () => controller.openReview(review),
                child: Row(
                  children: [
                    _Lead(icon: Iconsax.star_1, sand: true),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('home.reviewPrompt'.tr, style: theme.titleMedium),
                          Text(controller.branchName(review.branchId), style: theme.bodySmall),
                        ],
                      ),
                    ),
                    AppButton(
                      title: 'home.reviewCta'.tr,
                      small: true,
                      expanded: false,
                      onTap: () => controller.openReview(review),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _Lead extends StatelessWidget {
  final IconData icon;
  final bool sand;

  const _Lead({required this.icon, this.sand = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.r,
      height: 46.r,
      decoration: BoxDecoration(
        gradient: sand ? AppColors.sandGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Icon(icon, color: sand ? AppColors.sandInk : Colors.white, size: 22.sp),
    );
  }
}
