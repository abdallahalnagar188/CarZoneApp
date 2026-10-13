import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_brand_card.dart';
import '../widgets/phone_input.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'login.title'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          const AuthBrandCard(),
          20.height,
          Text('login.body'.tr, style: theme.bodyMedium?.copyWith(color: AppColors.ink500)),
          20.height,
          const PhoneInput(),
          16.height,
          Text('login.terms'.tr, style: theme.bodySmall),
          6.height,
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed(Routes.legalRoute, arguments: 'terms'),
                child: Text('legal.terms'.tr, style: theme.labelMedium?.copyWith(color: AppColors.primary)),
              ),
              Text('  ·  ', style: theme.labelMedium),
              GestureDetector(
                onTap: () => Get.toNamed(Routes.legalRoute, arguments: 'privacy'),
                child: Text('legal.privacy'.tr, style: theme.labelMedium?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          28.height,
          Obx(
            () => AppButton(
              title: (controller.sending.value ? 'otp.sending' : 'login.send').tr,
              loading: controller.sending.value,
              onTap: controller.sendCode,
            ),
          ),
        ],
      ),
    );
  }
}
