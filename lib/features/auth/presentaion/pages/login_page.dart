import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/auth_brand_card.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/phone_input.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: 'login.title'.tr,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          children: [
            const AuthBrandCard(),
            18.height,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, size: 18.sp, color: AppColors.primary),
                  10.width,
                  Expanded(
                    child: Text(
                      'login.body'.tr,
                      style: theme.bodySmall?.copyWith(
                        color: AppColors.ink500,
                        height: 1.4,
                        fontSize: 12.5.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            24.height,
            const PhoneInput(),
            24.height,
            Center(
              child: Column(
                children: [
                  Text(
                    'login.terms'.tr,
                    textAlign: TextAlign.center,
                    style: theme.bodySmall?.copyWith(
                      color: AppColors.hintGray,
                      fontSize: 12.sp,
                    ),
                  ),
                  6.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.legalRoute, arguments: 'terms'),
                        child: Text(
                          'legal.terms'.tr,
                          style: theme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          '·',
                          style: theme.labelMedium?.copyWith(
                            color: AppColors.hintGray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.legalRoute, arguments: 'privacy'),
                        child: Text(
                          'legal.privacy'.tr,
                          style: theme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            24.height,
            Obx(
              () => AppButton(
                title: (controller.sending.value ? 'otp.sending' : 'login.send').tr,
                loading: controller.sending.value,
                icon: Iconsax.arrow_left_2,
                onTap: controller.sending.value ? null : controller.sendCode,
              ),
            ),
            20.height,
            Row(
              children: [
                Expanded(child: Container(height: 1, color: AppColors.line)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'login.or'.tr,
                    style: theme.bodySmall?.copyWith(
                      color: AppColors.hintGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: AppColors.line)),
              ],
            ),
            20.height,
            if (GetPlatform.isIOS) ...[
              Obx(
                () => AppleSignInButton(
                  loading: controller.appleSigningIn.value,
                  onTap: controller.signInWithApple,
                ),
              ),
              12.height,
            ],
            Obx(
              () => GoogleSignInButton(
                loading: controller.googleSigningIn.value,
                onTap: controller.signInWithGoogle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
