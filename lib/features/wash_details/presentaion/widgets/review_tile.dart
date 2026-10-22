import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/review_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return RoundedContainer(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: review.customerName, size: 38.r),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName, style: theme.titleSmall),
                    Text(
                      '${FormatHelper.relativeDay(review.createdAt)} · ${review.serviceName.value}',
                      style: theme.bodySmall,
                    ),
                  ],
                ),
              ),
              RatingStars(value: review.stars, size: 14.sp),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            10.height,
            Text(review.comment, style: theme.bodyMedium),
          ],
          if (review.tags.isNotEmpty) ...[
            8.height,
            Wrap(
              spacing: 6.w,
              children: review.tags.map((t) => AppChip(label: 'tag.$t'.tr)).toList(),
            ),
          ],
          if (review.reply != null) ...[
            10.height,
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('wash.reply'.tr, style: theme.labelMedium?.copyWith(color: AppColors.secondaryInk)),
                  4.height,
                  Text(review.reply!, style: theme.bodySmall?.copyWith(color: AppColors.ink700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
