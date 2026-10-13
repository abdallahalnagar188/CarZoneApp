import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class BookingCard extends StatelessWidget {
  final OrderModel order;
  final String branchName;
  final VoidCallback onTap;

  const BookingCard({super.key, required this.order, required this.branchName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final color = StatusBadge.colorFor(order.status);
    return RoundedContainer(
      onTap: onTap,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadiusDirectional.horizontal(start: Radius.circular(20.r)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(branchName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.titleMedium),
                        ),
                        StatusBadge.order(order.status),
                      ],
                    ),
                    6.height,
                    Text(order.primary.name.value, style: theme.bodySmall),
                    10.height,
                    Row(
                      children: [
                        Icon(Iconsax.calendar_1, size: 14.sp, color: AppColors.ink500),
                        6.width,
                        Expanded(child: Text(FormatHelper.dateTime(order.scheduledAt), style: theme.labelMedium)),
                        Text(
                          FormatHelper.money(order.total),
                          style: theme.titleSmall?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    6.height,
                    Text('#${order.number}', textDirection: TextDirection.ltr, style: theme.labelSmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
