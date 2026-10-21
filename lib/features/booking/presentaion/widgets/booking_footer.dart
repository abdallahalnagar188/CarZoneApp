import 'package:carzone/core/constance/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/booking_controller.dart';

class BookingFooter extends StatelessWidget {
  final String title;
  final bool enabled;
  final VoidCallback onTap;
  final bool showTotal;
  final bool loading;

  const BookingFooter({
    super.key,
    required this.title,
    required this.enabled,
    required this.onTap,
    this.showTotal = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final quote = controller.quote;
      return Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: const Offset(0, -6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTotal && quote.items.isNotEmpty) ...[
              Row(
                children: [
                  Text('book.total'.tr, style: theme.bodySmall),
                  8.width,
                  Text(FormatHelper.money(quote.total), style: theme.headlineSmall?.copyWith(color: AppColors.primary)),
                  if (quote.discount > 0) ...[
                    8.width,
                    Text(
                      FormatHelper.money(quote.subtotal),
                      style: theme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough),
                    ),
                  ],
                  const Spacer(),
                  Icon(Iconsax.timer_1, size: 15.sp, color: AppColors.ink500),
                  4.width,
                  Text(FormatHelper.minutes(quote.durationMin), style: theme.labelMedium),
                ],
              ),
              if (quote.offer != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'book.offer'.trParams({'v': quote.offer!.offerLabel}),
                    style: theme.labelMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                  ),
                ),
              10.height,
            ],
            AppButton(title: title, loading: loading, onTap: enabled ? onTap : null),
          ],
        ),
      );
    });
  }
}
