import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/auth_controller.dart';
import '../widgets/phone_input.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    // Sign in with Apple already gave us the name: only the phone is asked.
    final askName = !controller.signedInWithApple;
    return Scaffold(
      appBar: AppTopBar(title: (askName ? 'profile.setup' : 'profile.setupPhone').tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          Text(
            (askName ? 'profile.setupBody' : 'profile.setupPhoneBody').tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink500),
          ),
          20.height,
          if (askName) ...[
            Obx(
              () => AppTextField(
                controller: controller.nameController,
                label: 'profile.name'.tr,
                error: controller.nameError.value,
                autofocus: true,
                onChanged: (_) => controller.nameError.value = null,
              ),
            ),
            18.height,
          ],
          if (controller.phone.isEmpty) const PhoneInput(),
          28.height,
          Obx(
            () => AppButton(
              title: 'profile.save'.tr,
              loading: controller.saving.value,
              onTap: controller.saveName,
            ),
          ),
          Obx(
            () => controller.phoneInUse.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: AppButton(
                      title: 'auth.usePhone'.tr,
                      variant: AppButtonVariant.ghost,
                      onTap: controller.signInWithTakenPhone,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
