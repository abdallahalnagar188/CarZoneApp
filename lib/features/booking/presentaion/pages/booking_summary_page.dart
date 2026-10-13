import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_footer.dart';
import '../widgets/booking_step_header.dart';
import '../widgets/summary_section.dart';

class BookingSummaryPage extends StatelessWidget {
  const BookingSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final theme = Theme.of(context).textTheme;
    final branch = controller.branch!;
    return Scaffold(
      appBar: AppTopBar(title: 'book.summary'.tr),
      bottomNavigationBar: Obx(
        () => BookingFooter(
          title: 'book.confirm'.tr,
          showTotal: false,
          enabled: true,
          loading: controller.confirming.value,
          onTap: controller.confirm,
        ),
      ),
      body: Obx(() {
        final quote = controller.quote;
        final vehicle = controller.vehicle;
        final slot = controller.slot.value;
        return ListView(
          children: [
            const BookingStepHeader(step: 4, labelKey: 'book.summary'),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  SummarySection(
                    icon: Iconsax.building,
                    title: 'book.wash'.tr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(branch.name.value, style: theme.titleMedium),
                        Text(branch.address.value, style: theme.bodySmall),
                      ],
                    ),
                  ),
                  if (vehicle != null)
                    SummarySection(
                      icon: Iconsax.car,
                      title: 'book.car'.tr,
                      onEdit: () => controller.editStep(Routes.bookCarRoute),
                      child: Row(
                        children: [
                          Text(vehicle.title, style: theme.titleSmall),
                          10.width,
                          PlateBadge(plate: vehicle.plate),
                        ],
                      ),
                    ),
                  SummarySection(
                    icon: Iconsax.magic_star,
                    title: 'book.service'.tr,
                    onEdit: () => controller.editStep(Routes.bookServiceRoute),
                    child: Column(
                      children: quote.items
                          .map((i) => PriceLine(label: i.name.value, value: FormatHelper.money(i.price)))
                          .toList(),
                    ),
                  ),
                  if (slot != null)
                    SummarySection(
                      icon: Iconsax.calendar_1,
                      title: 'book.slot'.tr,
                      onEdit: () => controller.editStep(Routes.bookSlotRoute),
                      child: Column(
                        children: [
                          PriceLine(label: FormatHelper.date(slot), value: FormatHelper.time(slot)),
                          PriceLine(label: 'book.duration'.tr, value: FormatHelper.minutes(quote.durationMin)),
                        ],
                      ),
                    ),
                  SummarySection(
                    icon: Iconsax.receipt_2,
                    title: 'book.total'.tr,
                    child: Column(
                      children: [
                        PriceLine(label: 'book.subtotal'.tr, value: FormatHelper.money(quote.subtotal)),
                        if (quote.discount > 0)
                          PriceLine(
                            label: 'book.discount'.tr,
                            value: '−${FormatHelper.money(quote.discount)}',
                            color: AppColors.success,
                          ),
                        Divider(color: AppColors.line, height: 18.h),
                        PriceLine(label: 'book.total'.tr, value: FormatHelper.money(quote.total), bold: true),
                        8.height,
                        Row(
                          children: [
                            Icon(Iconsax.wallet_money, size: 16.sp, color: AppColors.ink500),
                            8.width,
                            Expanded(child: Text('book.payLine'.tr, style: theme.bodySmall)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.info_circle, size: 18.sp, color: AppColors.sandInk),
                        10.width,
                        Expanded(
                          child: Text(
                            'book.policy'.trParams({'min': '${branch.settings.freeCancelMin}'}),
                            style: theme.bodySmall?.copyWith(color: AppColors.sandInk),
                          ),
                        ),
                      ],
                    ),
                  ),
                  16.height,
                  AppTextField(
                    controller: controller.noteController,
                    label: 'book.note'.tr,
                    maxLines: 3,
                    maxLength: 200,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
