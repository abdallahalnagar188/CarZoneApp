import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/text_field/app_text_field.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/auth_controller.dart';

class PhoneInput extends StatelessWidget {
  const PhoneInput({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('login.phone'.tr, style: theme.titleSmall),
        8.height,
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.line, width: 1.5),
                  ),
                  child: Text(
                    '+20',
                    style: theme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                10.width,
                Expanded(
                  child: AppTextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 13,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
                    error: controller.phoneError.value,
                    onChanged: (_) => controller.phoneError.value = null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
