import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/auth_controller.dart';

class PhoneInput extends StatefulWidget {
  const PhoneInput({super.key});

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.mobile, size: 18.sp, color: AppColors.primary),
            8.width,
            Text(
              'login.phone'.tr,
              style: theme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        10.height,
        // RTL container row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
           
            // Phone Number Input Container
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 56.h,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isFocused ? AppColors.primary : AppColors.line,
                    width: _isFocused ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isFocused
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: _isFocused ? 12 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.center,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: controller.phoneController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.sendCode(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    style: theme.titleMedium?.copyWith(
                      color: AppColors.ink900,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      letterSpacing: 1.2,
                    ),
                    cursorColor: AppColors.primary,
                    cursorWidth: 2.2,
                    decoration: InputDecoration(
                      hintText: '010 1234 5678',
                      hintStyle: theme.bodyMedium?.copyWith(
                        color: AppColors.hintGray,
                        letterSpacing: 0.8,
                        fontSize: 15.sp,
                      ),
                      hintTextDirection: TextDirection.ltr,
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
            10.width,

             // Country Code Container (+20)
            Container(
              height: 56.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _isFocused ? AppColors.primary.withValues(alpha: 0.5) : AppColors.line,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🇪🇬',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  6.width,
                  Text(
                    '+20',
                    style: theme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
      
          ],
        ),
      ],
    );
  }
}
