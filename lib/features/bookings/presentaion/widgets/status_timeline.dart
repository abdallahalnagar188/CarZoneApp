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
    done.putIfAbsent('pending', () => order.createdAt);

    final terminal = order.status == OrderStatus.cancelled || order.status == OrderStatus.noShow;
    final currentKey = order.status.key;
    final currentIdx = _flow.indexOf(currentKey);

    final List<String> rows;
    if (terminal) {
      final timelineKeys = order.timeline.map((t) => t.key).where((k) => k != 'rescheduled').toList();
      if (!timelineKeys.contains(currentKey)) {
        timelineKeys.add(currentKey);
      }
      rows = timelineKeys.isEmpty ? ['pending', currentKey] : timelineKeys;
    } else {
      rows = _flow;
    }

    return RoundedContainer(
      child: Column(
        children: List.generate(rows.length, (i) {
          final key = rows[i];
          final at = done[key];
          final isCurrent = key == currentKey;
          final isReached = terminal
              ? (at != null || isCurrent)
              : (currentIdx >= 0 ? i <= currentIdx : at != null);
          final isCompleted = terminal
              ? (at != null && !isCurrent)
              : (currentIdx >= 0 ? i < currentIdx : (at != null && !isCurrent));

          final stepStatus = OrderStatus.values.firstWhereOrNull((s) => s.key == key);
          final statusColor = (stepStatus != null) ? StatusBadge.colorFor(stepStatus) : AppColors.primary;
          final color = isCurrent
              ? statusColor
              : (isCompleted ? AppColors.primary : AppColors.ink300);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 20.r : 16.r,
                      height: isCurrent ? 20.r : 16.r,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : (isCurrent ? AppColors.tint(statusColor) : AppColors.surface),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isReached ? color : AppColors.line,
                          width: isCurrent ? 3 : 2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? Icon(Icons.check, size: 10.sp, color: Colors.white)
                          : (isCurrent
                              ? Center(
                                  child: Container(
                                    width: 7.r,
                                    height: 7.r,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null),
                    ),
                    if (i < rows.length - 1)
                      Expanded(
                        child: Container(
                          width: 2.5,
                          margin: EdgeInsets.symmetric(vertical: 2.h),
                          color: isCompleted ? AppColors.primary : AppColors.line,
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
                              color: isReached ? AppColors.ink900 : AppColors.ink500,
                              fontWeight: isCurrent ? FontWeight.w800 : (isCompleted ? FontWeight.w600 : FontWeight.w500),
                            ),
                          ),
                        ),
                        if (at != null)
                          Text(
                            FormatHelper.time(at),
                            style: theme.labelSmall?.copyWith(
                              color: isCurrent ? color : AppColors.ink500,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
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
