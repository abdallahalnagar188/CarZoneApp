import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/services/availability_service.dart';
import '../controllers/booking_controller.dart';

class SlotGrid extends StatelessWidget {
  const SlotGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final slots = controller.slots;
      if (slots.isEmpty) {
        return CustomEmptyState(
          icon: Iconsax.calendar_remove,
          title: 'book.noSlots'.tr,
          actionText: 'book.seeTomorrow'.tr,
          onAction: controller.seeTomorrow,
        );
      }
      final groups = <String, List<SlotModel>>{
        'book.morning': slots.where((s) => s.start.hour < 12).toList(),
        'book.afternoon': slots.where((s) => s.start.hour >= 12 && s.start.hour < 17).toList(),
        'book.evening': slots.where((s) => s.start.hour >= 17).toList(),
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.where((e) => e.value.isNotEmpty).map((e) {
          return Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key.tr, style: theme.titleSmall),
                10.height,
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 2.1,
                  children: e.value.map((s) {
                    final on = controller.slot.value == s.start;
                    return GestureDetector(
                      onTap: () => controller.selectSlot(s.start),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: on ? AppColors.primaryGradient : null,
                          color: on ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: on ? null : Border.all(color: AppColors.line, width: 1.5),
                          boxShadow: on ? AppColors.buttonShadow : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              FormatHelper.time(s.start),
                              style: theme.titleSmall?.copyWith(color: on ? Colors.white : AppColors.ink900),
                            ),
                            if (s.fewLeft)
                              Text(
                                'book.few'.tr,
                                style: theme.labelSmall?.copyWith(
                                  fontSize: 9.sp,
                                  color: on ? Colors.white70 : AppColors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}
