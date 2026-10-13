import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/auth_controller.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      appBar: AppTopBar(title: 'profile.setup'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          Text(
            'profile.setupBody'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink500),
          ),
          20.height,
          Obx(
            () => AppTextField(
              controller: controller.nameController,
              label: 'profile.name'.tr,
              error: controller.nameError.value,
              autofocus: true,
              onChanged: (_) => controller.nameError.value = null,
            ),
          ),
          28.height,
          Obx(
            () => AppButton(
              title: 'profile.save'.tr,
              loading: controller.saving.value,
              onTap: controller.saveName,
            ),
          ),
        ],
      ),
    );
  }
}
