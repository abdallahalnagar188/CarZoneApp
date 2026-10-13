import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_boxes.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'otp.title'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          Center(
            child: Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(Iconsax.sms, size: 32.sp, color: AppColors.primary),
            ),
          ),
          16.height,
          Text(
            'otp.sent'.trParams({'phone': controller.phone}),
            textAlign: TextAlign.center,
            style: theme.bodyMedium?.copyWith(color: AppColors.ink500),
          ),
          24.height,
          Obx(
            () => OtpBoxes(
              controller: controller.otpController,
              hasError: controller.otpError.value != null,
            ),
          ),
          Obx(
            () => controller.otpError.value == null
                ? 12.height
                : Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      controller.otpError.value!,
                      textAlign: TextAlign.center,
                      style: theme.bodySmall?.copyWith(color: AppColors.danger),
                    ),
                  ),
          ),
          16.height,
          Obx(() {
            final lock = controller.lockedFor.value;
            final wait = controller.resendIn.value;
            final label = lock > 0
                ? 'otp.locked'.tr
                : wait > 0
                    ? 'otp.resendIn'.trParams({'s': '$wait'})
                    : 'otp.resend'.tr;
            return AppButton(
              title: label,
              variant: AppButtonVariant.ghost,
              icon: Iconsax.refresh,
              onTap: lock > 0 || wait > 0 ? null : controller.resend,
            );
          }),
          8.height,
          Center(
            child: TextButton(
              onPressed: controller.changeNumber,
              child: Text('otp.change'.tr, style: theme.labelLarge?.copyWith(color: AppColors.primary)),
            ),
          ),
          16.height,
          Obx(
            () => AppButton(
              title: (controller.verifying.value ? 'otp.verifying' : 'otp.verify').tr,
              loading: controller.verifying.value,
              onTap: controller.verify,
            ),
          ),
        ],
      ),
    );
  }
}
