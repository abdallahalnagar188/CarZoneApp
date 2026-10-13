import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class ServiceProgressCard extends StatelessWidget {
  final OrderModel order;

  const ServiceProgressCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final started = order.timeline.where((t) => t.key == 'in_service').lastOrNull?.at ?? DateTime.now();
    final finish = started.add(Duration(minutes: order.durationMin));
    final total = order.durationMin * 60;
    final elapsed = DateTime.now().difference(started).inSeconds.clamp(0, total);
    final theme = Theme.of(context).textTheme;
    return RoundedContainer(
      gradient: AppColors.heroGradient,
      child: Row(
        children: [
          SizedBox(
            width: 64.r,
            height: 64.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : elapsed / total,
                    strokeWidth: 5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(AppColors.glow),
                  ),
                ),
                Icon(Iconsax.timer_1, color: Colors.white, size: 24.sp),
              ],
            ),
          ),
          16.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('status.in_service'.tr, style: theme.titleMedium?.copyWith(color: Colors.white)),
                4.height,
                Text(
                  'book.finishEta'.trParams({'time': FormatHelper.time(finish)}),
                  style: theme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
