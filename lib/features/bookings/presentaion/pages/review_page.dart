import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/review_controller.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReviewController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'review.title'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          RoundedContainer(
            child: Column(
              children: [
                Text(controller.branchName, style: theme.titleLarge, textAlign: TextAlign.center),
                if (controller.order != null)
                  Text(controller.order!.primary.name.value, style: theme.bodySmall),
                18.height,
                Obx(() => RatingStars(value: controller.stars.value, size: 38.sp, onChanged: controller.setStars)),
                Obx(
                  () => controller.error.value == null
                      ? 6.height
                      : Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(controller.error.value!, style: theme.bodySmall?.copyWith(color: AppColors.danger)),
                        ),
                ),
              ],
            ),
          ),
          20.height,
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: ReviewController.tagKeys
                  .map((t) => AppChip(
                        label: 'tag.$t'.tr,
                        flat: true,
                        selected: controller.tags.contains(t),
                        onTap: () => controller.toggleTag(t),
                      ))
                  .toList(),
            ),
          ),
          20.height,
          AppTextField(
            controller: controller.commentController,
            label: 'review.comment'.tr,
            maxLines: 4,
            maxLength: 500,
          ),
          28.height,
          Obx(
            () => AppButton(
              title: 'review.send'.tr,
              loading: controller.sending.value,
              onTap: controller.submit,
            ),
          ),
        ],
      ),
    );
  }
}
