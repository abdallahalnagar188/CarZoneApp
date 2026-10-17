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
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: 'otp.title'.tr,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          children: [
            // Shield & Lock Icon Illustration Container
            Center(
              child: Container(
                width: 78.r,
                height: 78.r,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 58.r,
                    height: 58.r,
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.shield_security,
                      size: 28.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            18.height,
            // Destination Text & Phone Number Badge
            Column(
              children: [
                Text(
                  'أرسلنا رمز التحقق المكون من 6 أرقام إلى',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium?.copyWith(
                    color: AppColors.ink500,
                    fontSize: 13.5.sp,
                  ),
                ),
                8.height,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      controller.phone,
                      style: theme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            28.height,
            // OTP Digit Input Boxes
            OtpBoxes(
              controller: controller.otpController,
              onCompleted: controller.verify,
            ),
            24.height,
            // Resend Countdown / Active Resend Button
            Obx(() {
              final lock = controller.lockedFor.value;
              final wait = controller.resendIn.value;

              if (lock > 0) {
                return Container(
                  height: 50.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.lock, size: 16.sp, color: AppColors.danger),
                      8.width,
                      Text(
                        'otp.locked'.tr,
                        style: theme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (wait > 0) {
                return Container(
                  height: 50.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.timer_1, size: 16.sp, color: AppColors.ink500),
                      8.width,
                      Text(
                        'otp.resendIn'.trParams({'s': '$wait'}),
                        style: theme.bodyMedium?.copyWith(
                          color: AppColors.ink500,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return AppButton(
                title: 'otp.resend'.tr,
                variant: AppButtonVariant.ghost,
                icon: Iconsax.refresh,
                onTap: controller.resend,
              );
            }),
            10.height,
            // Change Number Button
            Center(
              child: TextButton.icon(
                onPressed: controller.changeNumber,
                icon: Icon(Iconsax.edit_2, size: 16.sp, color: AppColors.primary),
                label: Text(
                  'otp.change'.tr,
                  style: theme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5.sp,
                  ),
                ),
              ),
            ),
            18.height,
            // Verify CTA Button with reactive loading state
            Obx(
              () => AppButton(
                title: (controller.verifying.value ? 'otp.verifying' : 'otp.verify').tr,
                loading: controller.verifying.value,
                icon: Iconsax.tick_circle,
                onTap: controller.verifying.value ? null : controller.verify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
