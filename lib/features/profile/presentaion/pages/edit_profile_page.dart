import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/profile_controller.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Scaffold(
      appBar: AppTopBar(title: 'profile.edit'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          Center(
            child: Obx(() => InitialsAvatar(name: controller.session.user.value?.name, size: 96.r, sand: true)),
          ),
          24.height,
          Obx(
            () => AppTextField(
              controller: controller.nameController,
              label: 'profile.name'.tr,
              error: controller.nameError.value,
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
