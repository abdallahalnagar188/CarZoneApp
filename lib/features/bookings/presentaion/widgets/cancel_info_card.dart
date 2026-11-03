import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

/// Who cancelled a booking and why, so a booking the wash cancelled is not a mystery.
class CancelInfoCard extends StatelessWidget {
  final OrderModel order;

  const CancelInfoCard({super.key, required this.order});

  /// Reasons the server writes itself; the title already says what happened.
  static const _systemReasons = {'expired_unconfirmed', 'expired_not_started', 'Cancelled by customer'};

  String get _title => switch (order.cancelledBy) {
        'customer' => 'cancel.byYou'.tr,
        'staff' => 'cancel.byWash'.tr,
        'admin' => 'cancel.byAdmin'.tr,
        'system' when order.cancelReason == 'expired_not_started' => 'cancel.expiredNotStarted'.tr,
        'system' => 'cancel.expiredUnconfirmed'.tr,
        _ => 'status.cancelled'.tr,
      };

  String? get _reason {
    final raw = order.cancelReason?.trim();
    if (raw == null || raw.isEmpty || _systemReasons.contains(raw)) return null;
    // Older app builds sent the translation key instead of the text.
    return raw.startsWith('cancel.r') ? raw.tr : raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final reason = _reason;
    return RoundedContainer(
      color: AppColors.tint(AppColors.statusCancelled),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.close_circle, color: AppColors.statusCancelled, size: 24.sp),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: theme.titleSmall),
                if (reason != null) ...[
                  4.height,
                  Text('cancel.reasonLine'.trParams({'reason': reason}), style: theme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
