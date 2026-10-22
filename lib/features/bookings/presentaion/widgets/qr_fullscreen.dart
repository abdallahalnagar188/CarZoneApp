import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class QrFullscreen extends StatelessWidget {
  final String code;
  final String number;

  const QrFullscreen({super.key, required this.code, required this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppIconButton(icon: const Icon(Iconsax.close_circle), onTap: Get.back),
              ),
              const Spacer(),
              Text('#$number', textDirection: TextDirection.ltr, style: theme.titleLarge?.copyWith(color: AppColors.brandNight)),
              20.height,
              QrImageView(
                data: '$number|$code',
                size: 280.r,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppColors.brandNight),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: AppColors.brand,
                ),
              ),
              24.height,
              Text(
                code.split('').join(' '),
                textDirection: TextDirection.ltr,
                style: theme.headlineLarge?.copyWith(fontSize: 40.sp, letterSpacing: 6, color: AppColors.brand),
              ),
              8.height,
              Text('book.showQr'.tr, style: theme.bodyMedium?.copyWith(color: AppColors.ink500)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
