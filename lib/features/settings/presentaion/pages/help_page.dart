import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'help.title'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          CustomEmptyState(icon: Iconsax.message_question, title: 'help.title'.tr, body: 'help.body'.tr),
          RoundedContainer(
            child: Column(
              children: [
                _Row(icon: Iconsax.call, text: '+20 102 243 7824'),
                Divider(color: AppColors.line, height: 24.h),
                _Row(icon: Iconsax.sms, text: 'bdallhmsd807@gmail.com'),
                Divider(color: AppColors.line, height: 24.h),
                _Row(icon: Iconsax.clock, text: 'help.hours'.tr),
              ],
            ),
          ),
          28.height,
          Center(child: AppLogo(size: 64.r)),
          10.height,
          Center(child: AppWordmark(height: 14.r, onBrand: AppColors.isDark)),
          8.height,
          Text('app.tagline'.tr, textAlign: TextAlign.center, style: theme.bodySmall),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Row({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        12.width,
        Expanded(
          child: Text(text, textDirection: TextDirection.ltr, textAlign: TextAlign.start, style: Theme.of(context).textTheme.titleSmall),
        ),
      ],
    );
  }
}
