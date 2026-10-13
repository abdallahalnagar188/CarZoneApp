import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class BookingStepHeader extends StatelessWidget {
  final int step;
  final String labelKey;

  const BookingStepHeader({super.key, required this.step, required this.labelKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final on = i < step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsetsDirectional.only(end: i == 3 ? 0 : 6.w),
                  height: 6.h,
                  decoration: BoxDecoration(
                    gradient: on ? AppColors.primaryGradient : null,
                    color: on ? null : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          8.height,
          Text(
            '${'book.step'.trParams({'n': '$step'})} · ${labelKey.tr}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
