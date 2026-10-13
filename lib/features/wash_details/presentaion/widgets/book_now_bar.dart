import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/wash_details_controller.dart';

class BookNowBar extends StatelessWidget {
  const BookNowBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final row = controller.listing.value;
      if (row == null) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: const Offset(0, -6))],
        ),
        child: !row.branch.bookable
            ? Row(
                children: [
                  Icon(Iconsax.info_circle, color: AppColors.danger),
                  10.width,
                  Text('wash.unavailable'.tr, style: theme.titleMedium?.copyWith(color: AppColors.danger)),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('wash.from'.trParams({'price': ''}).trim(), style: theme.bodySmall),
                        Text(
                          row.fromPrice == null ? '' : FormatHelper.money(row.fromPrice!),
                          style: theme.headlineSmall?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    title: (row.open ? 'wash.book' : 'wash.bookLater').tr,
                    expanded: false,
                    icon: Iconsax.calendar_add,
                    onTap: () => controller.book(),
                  ),
                ],
              ),
      );
    });
  }
}
