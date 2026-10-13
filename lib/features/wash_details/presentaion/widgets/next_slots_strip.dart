import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/wash_details_controller.dart';

class NextSlotsStrip extends StatelessWidget {
  const NextSlotsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final slots = controller.nextSlots;
      if (slots.isEmpty) return const SizedBox.shrink();
      final today = FormatHelper.sameDay(slots.first.start, DateTime.now());
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!today)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Text(
                  'wash.fullToday'.trParams({
                    'when': '${FormatHelper.relativeDay(slots.first.start)} ${FormatHelper.time(slots.first.start)}',
                  }),
                  style: theme.bodySmall,
                ),
              ),
            Row(
              children: slots.map((s) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.book(slot: s.start),
                    child: Container(
                      margin: EdgeInsetsDirectional.only(end: 10.w),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.line, width: 1.5),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Text(
                        FormatHelper.time(s.start),
                        style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}
