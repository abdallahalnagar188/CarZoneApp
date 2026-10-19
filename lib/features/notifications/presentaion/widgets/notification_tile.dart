import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/notification_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.item, required this.onTap});

  IconData get _icon => switch (item.type) {
        'created' => Iconsax.document_text,
        'confirmed' || 'booking_confirmed' => Iconsax.verify,
        'waiting' => Iconsax.clock,
        'in_service' => Iconsax.timer_1,
        'completed' || 'order_ready' => Iconsax.tick_circle,
        'cancelled' || 'booking_cancelled' => Iconsax.close_circle,
        'booking_reminder' || 'reminder' => Iconsax.notification_bing,
        'review_reminder' => Iconsax.star_1,
        'offer' => Iconsax.discount_shape,
        'complaint_update' => Iconsax.message_question,
        'system' => Iconsax.info_circle,
        _ => Iconsax.notification,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return RoundedContainer(
      onTap: onTap,
      margin: EdgeInsets.only(bottom: 10.h),
      color: item.read ? null : AppColors.primarySoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              gradient: item.read ? null : AppColors.primaryGradient,
              color: item.read ? AppColors.primarySoft : null,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(_icon, size: 20.sp, color: item.read ? AppColors.primary : Colors.white),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title.value, style: theme.titleSmall),
                2.height,
                Text(item.body.value, style: theme.bodySmall),
                4.height,
                Text(FormatHelper.time(item.createdAt), style: theme.labelSmall),
              ],
            ),
          ),
          if (!item.read)
            Container(
              width: 9.r,
              height: 9.r,
              margin: EdgeInsets.only(top: 6.h),
              decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
