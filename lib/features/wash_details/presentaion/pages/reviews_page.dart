import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/wash_details_controller.dart';
import '../widgets/review_tile.dart';
import '../widgets/reviews_summary.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    return Scaffold(
      appBar: AppTopBar(title: 'wash.reviews'.tr),
      body: Obx(() {
        final list = controller.filteredReviews;
        return ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            const ReviewsSummary(),
            14.height,
            SizedBox(
              height: 40.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [0, 5, 4, 3, 2, 1].map((s) {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: AppChip(
                      label: s == 0 ? 'f.any'.tr : '★ $s',
                      flat: true,
                      selected: controller.reviewStarFilter.value == s,
                      onTap: () => controller.reviewStarFilter.value = s,
                    ),
                  );
                }).toList(),
              ),
            ),
            14.height,
            if (list.isEmpty)
              CustomEmptyState(icon: Iconsax.star, title: 'wash.reviews'.tr)
            else
              ...list.map((r) => ReviewTile(review: r)),
          ],
        );
      }),
    );
  }
}
