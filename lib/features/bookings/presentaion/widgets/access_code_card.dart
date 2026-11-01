import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class AccessCodeCard extends StatelessWidget {
  final OrderModel order;

  const AccessCodeCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    if (!order.showsCode) {
      return RoundedContainer(
        color: AppColors.primarySoft,
        child: Row(
          children: [
            Icon(Iconsax.ticket, color: AppColors.primary, size: 32.sp),
            14.width,
            Expanded(child: Text('book.codeWait'.tr, style: theme.bodyMedium?.copyWith(color: AppColors.primary))),
          ],
        ),
      );
    }
    return RoundedContainer(
      child: Column(
        children: [
          Text('book.code'.tr, style: theme.bodySmall),
          Text(
            order.code.split('').join(' '),
            textDirection: TextDirection.ltr,
            style: theme.headlineLarge?.copyWith(letterSpacing: 4, color: AppColors.primary),
          ),
          4.height,
          Text('book.showCode'.tr, style: theme.bodySmall),
        ],
      ),
    );
  }
}
