import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/booking_controller.dart';

class DateStrip extends StatelessWidget {
  const DateStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final theme = Theme.of(context).textTheme;
    final days = controller.days;
    return SizedBox(
      height: 86.h,
      child: Obx(() {
        final selected = controller.day.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: days.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (_, i) {
            final d = days[i];
            final closed = controller.isClosedDay(d);
            final on = FormatHelper.sameDay(d, selected);
            final label = i == 0
                ? 'book.today'.tr
                : i == 1
                    ? 'book.tomorrow'.tr
                    : FormatHelper.dayName(d);
            return GestureDetector(
              onTap: closed ? null : () => controller.selectDay(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72.w,
                decoration: BoxDecoration(
                  gradient: on ? AppColors.primaryGradient : null,
                  color: on ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: on ? null : Border.all(color: AppColors.line, width: 1.5),
                  boxShadow: on ? AppColors.buttonShadow : null,
                ),
                child: Opacity(
                  opacity: closed ? 0.4 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelSmall?.copyWith(color: on ? Colors.white : AppColors.ink500),
                      ),
                      Text(
                        '${d.day}',
                        style: theme.headlineMedium?.copyWith(color: on ? Colors.white : AppColors.ink900),
                      ),
                      Text(
                        closed ? 'book.closedDay'.tr : FormatHelper.shortDate(d).split(' ').last,
                        style: theme.labelSmall?.copyWith(color: on ? Colors.white70 : AppColors.ink500),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
