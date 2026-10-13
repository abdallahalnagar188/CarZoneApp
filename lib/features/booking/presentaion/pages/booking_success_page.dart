import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/booking_controller.dart';

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final order = controller.createdOrder.value!;
    final theme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.backHome();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: Icon(Iconsax.tick_circle, color: Colors.white, size: 56.sp),
                  ),
                ),
                28.height,
                Text('book.success'.tr, style: theme.headlineLarge, textAlign: TextAlign.center),
                20.height,
                RoundedContainer(
                  child: Column(
                    children: [
                      Text('book.number'.tr, style: theme.bodySmall),
                      4.height,
                      Text(order.number, style: theme.headlineMedium?.copyWith(color: AppColors.primary)),
                      10.height,
                      StatusBadge.order(order.status),
                      12.height,
                      Text(FormatHelper.dateTime(order.scheduledAt), style: theme.bodyMedium),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(title: 'book.view'.tr, icon: Iconsax.receipt_2, onTap: controller.viewCreated),
                12.height,
                AppButton(title: 'book.home'.tr, variant: AppButtonVariant.ghost, onTap: controller.backHome),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
