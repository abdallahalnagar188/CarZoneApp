import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/enums/enums.dart';
import '../../../core/extensions/sized_box_extension.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.order(OrderStatus status) => StatusBadge(
        label: 'status.${status.key}'.tr,
        color: colorFor(status),
      );

  factory StatusBadge.payment(PaymentStatus status) => StatusBadge(
        label: 'pay.${status.name}'.tr,
        color: switch (status) {
          PaymentStatus.pending => AppColors.statusPending,
          PaymentStatus.paid => AppColors.statusCompleted,
          PaymentStatus.refunded => AppColors.statusNoShow,
        },
      );

  static Color colorFor(OrderStatus status) => switch (status) {
        OrderStatus.pending => AppColors.statusPending,
        OrderStatus.confirmed => AppColors.statusConfirmed,
        OrderStatus.waiting => AppColors.statusWaiting,
        OrderStatus.inService => AppColors.statusInService,
        OrderStatus.completed => AppColors.statusCompleted,
        OrderStatus.cancelled => AppColors.statusCancelled,
        OrderStatus.noShow => AppColors.statusNoShow,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.tint(color),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          6.width,
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
