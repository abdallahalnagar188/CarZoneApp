import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class StatusTimeline extends StatelessWidget {
  final OrderModel order;

  const StatusTimeline({super.key, required this.order});

  static const _flow = ['pending', 'confirmed', 'waiting', 'in_service', 'completed'];

  String _label(String key) =>
      key == 'rescheduled' ? 'toast.rescheduled'.tr : 'status.$key'.tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final done = {for (final t in order.timeline) t.key: t.at};
    final terminal = order.status == OrderStatus.cancelled || order.status == OrderStatus.noShow;
    final rows = terminal
        ? order.timeline.map((t) => t.key).where((k) => k != 'rescheduled').toList()
        : _flow;
    return RoundedContainer(
      child: Column(
        children: List.generate(rows.length, (i) {
          final key = rows[i];
          final at = done[key];
          final reached = at != null;
          final current = key == order.status.key;
          final color = reached
              ? (terminal && i == rows.length - 1 ? StatusBadge.colorFor(order.status) : AppColors.primary)
              : AppColors.ink300;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: current ? 18.r : 14.r,
                      height: current ? 18.r : 14.r,
                      decoration: BoxDecoration(
                        color: reached ? color : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2.5),
                        boxShadow: current
                            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 2)]
                            : null,
                      ),
                    ),
                    if (i < rows.length - 1)
                      Expanded(
                        child: Container(
                          width: 2.5,
                          margin: EdgeInsets.symmetric(vertical: 2.h),
                          color: reached && done[rows[i + 1]] != null ? AppColors.primary : AppColors.line,
                        ),
                      ),
                  ],
                ),
                12.width,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 18.h : 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _label(key),
                            style: theme.titleSmall?.copyWith(
                              color: reached ? AppColors.ink900 : AppColors.ink500,
                              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (at != null) Text(FormatHelper.time(at), style: theme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
