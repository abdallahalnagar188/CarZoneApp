import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/booking_details_controller.dart';

class CancelSheet extends StatelessWidget {
  const CancelSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingDetailsController>();
    final theme = Theme.of(context).textTheme;
    final freeMin = controller.branch?.settings.freeCancelMin ?? 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: controller.lateWindow ? AppColors.tint(AppColors.warning) : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                controller.lateWindow ? Iconsax.warning_2 : Iconsax.info_circle,
                color: controller.lateWindow ? AppColors.warning : AppColors.primary,
                size: 20.sp,
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.lateWindow) Text('cancel.late'.tr, style: theme.titleSmall),
                    Text(
                      controller.lateWindow ? 'cancel.lateBody'.tr : 'book.policy'.trParams({'min': '$freeMin'}),
                      style: theme.bodySmall?.copyWith(color: AppColors.ink700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        16.height,
        Text('cancel.reason'.tr, style: theme.titleSmall),
        10.height,
        Obx(
          () => Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: ['cancel.r1', 'cancel.r2', 'cancel.r3', 'cancel.r4']
                .map((k) => AppChip(
                      label: k.tr,
                      flat: true,
                      selected: controller.cancelReason.value == k,
                      onTap: () => controller.setReason(k),
                    ))
                .toList(),
          ),
        ),
        24.height,
        Obx(
          () => AppButton(
            title: 'cancel.confirm'.tr,
            variant: AppButtonVariant.danger,
            loading: controller.cancelling.value,
            onTap: controller.confirmCancel,
          ),
        ),
      ],
    );
  }
}
