import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class QrCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const QrCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    if (!order.showsQr) {
      return RoundedContainer(
        color: AppColors.primarySoft,
        child: Row(
          children: [
            Icon(Iconsax.scan_barcode, color: AppColors.primary, size: 32.sp),
            14.width,
            Expanded(child: Text('book.qrWait'.tr, style: theme.bodyMedium?.copyWith(color: AppColors.primary))),
          ],
        ),
      );
    }
    return RoundedContainer(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppColors.line),
            ),
            child: QrImageView(
              data: '${order.number}|${order.code}',
              size: 170.r,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppColors.brandNight),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: AppColors.brand,
              ),
            ),
          ),
          14.height,
          Text('book.code'.tr, style: theme.bodySmall),
          Text(
            order.code.split('').join(' '),
            textDirection: TextDirection.ltr,
            style: theme.headlineLarge?.copyWith(letterSpacing: 4, color: AppColors.primary),
          ),
          4.height,
          Text('book.showQr'.tr, style: theme.bodySmall),
        ],
      ),
    );
  }
}
