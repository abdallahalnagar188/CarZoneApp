import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/wash_details_controller.dart';

class ReviewsSummary extends StatelessWidget {
  const ReviewsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final dist = controller.distribution;
      final total = controller.reviews.length;
      final max = dist.fold<int>(1, (m, v) => v > m ? v : m);
      final avg = controller.listing.value?.rating ?? 0;
      return RoundedContainer(
        child: Row(
          children: [
            Column(
              children: [
                Text(avg.toStringAsFixed(1), style: theme.headlineLarge?.copyWith(fontSize: 38.sp)),
                RatingStars(value: avg.round(), size: 14.sp),
                4.height,
                Text('$total', style: theme.bodySmall),
              ],
            ),
            20.width,
            Expanded(
              child: Column(
                children: List.generate(5, (i) {
                  final star = 5 - i;
                  final count = dist[star - 1];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    child: Row(
                      children: [
                        SizedBox(width: 14.w, child: Text('$star', style: theme.labelMedium)),
                        8.width,
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: count / max,
                              minHeight: 7.h,
                              backgroundColor: AppColors.primarySoft,
                              valueColor: AlwaysStoppedAnimation(AppColors.star),
                            ),
                          ),
                        ),
                        8.width,
                        SizedBox(width: 22.w, child: Text('$count', style: theme.labelSmall)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }
}
