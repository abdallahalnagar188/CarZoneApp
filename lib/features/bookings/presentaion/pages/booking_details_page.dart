import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../booking/presentaion/widgets/summary_section.dart';
import '../controllers/booking_details_controller.dart';
import '../widgets/booking_actions.dart';
import '../widgets/qr_card.dart';
import '../widgets/service_progress_card.dart';
import '../widgets/status_timeline.dart';

class BookingDetailsPage extends StatelessWidget {
  const BookingDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingDetailsController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(
        title: 'book.details'.tr,
        actions: [
          if (kDebugMode)
            AppIconButton(glass: true, icon: const Icon(Iconsax.forward), onTap: controller.simulateAdvance),
        ],
      ),
      body: Obx(() {
        final order = controller.order.value;
        final branch = controller.branch;
        if (order == null || branch == null) {
          if (controller.loading.value) return const AppShimmerList(count: 5);
          if (controller.error.value != null) {
            return AppErrorState(message: controller.error.value, onRetry: controller.load);
          }
          return CustomEmptyState(icon: Iconsax.receipt_search, title: 'notfound'.tr);
        }
        final vehicle = controller.vehicle;
        return ListView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('book.number'.tr, style: theme.bodySmall),
                      Text('#${order.number}', textDirection: TextDirection.ltr, style: theme.headlineMedium),
                    ],
                  ),
                ),
                StatusBadge.order(order.status),
              ],
            ),
            16.height,
            if (order.status == OrderStatus.noShow) ...[
              RoundedContainer(
                color: AppColors.tint(AppColors.statusNoShow),
                child: Text('noShow.banner'.tr, style: theme.bodyMedium),
              ),
              12.height,
            ],
            if (order.status == OrderStatus.inService) ...[
              ServiceProgressCard(order: order),
              12.height,
            ],
            if (order.status.isUpcoming) ...[
              QrCard(order: order, onTap: controller.openQr),
              12.height,
            ],
            Text('book.timeline'.tr, style: theme.titleLarge),
            10.height,
            StatusTimeline(order: order),
            16.height,
            Text('wash.location'.tr, style: theme.titleLarge),
            10.height,
            Text(branch.name.value, style: theme.titleMedium),
            10.height,
            BranchLocationMap(
              lat: branch.lat,
              lng: branch.lng,
              address: branch.address.value,
              pinLabel: FormatHelper.time(order.scheduledAt),
            ),
            10.height,
            AppButton(
              title: 'book.contact'.tr,
              icon: Iconsax.call,
              small: true,
              variant: AppButtonVariant.ghost,
              onTap: controller.contact,
            ),
            16.height,
            if (vehicle != null)
              SummarySection(
                icon: Iconsax.car,
                title: 'book.car'.tr,
                child: Row(
                  children: [
                    Text(vehicle.title, style: theme.titleSmall),
                    10.width,
                    PlateBadge(plate: vehicle.plate),
                  ],
                ),
              ),
            SummarySection(
              icon: Iconsax.calendar_1,
              title: 'book.slot'.tr,
              child: Column(
                children: [
                  PriceLine(label: FormatHelper.date(order.scheduledAt), value: FormatHelper.time(order.scheduledAt)),
                  PriceLine(label: 'book.duration'.tr, value: FormatHelper.minutes(order.durationMin)),
                ],
              ),
            ),
            SummarySection(
              icon: Iconsax.receipt_2,
              title: 'book.total'.tr,
              child: Column(
                children: [
                  ...order.items.map((i) => PriceLine(label: i.name.value, value: FormatHelper.money(i.price))),
                  if (order.discount > 0)
                    PriceLine(
                      label: 'book.discount'.tr,
                      value: '−${FormatHelper.money(order.discount)}',
                      color: AppColors.success,
                    ),
                  Divider(color: AppColors.line, height: 18.h),
                  PriceLine(label: 'book.total'.tr, value: FormatHelper.money(order.total), bold: true),
                  10.height,
                  Row(
                    children: [
                      Expanded(child: Text('book.payStatus'.tr, style: theme.bodySmall)),
                      StatusBadge.payment(order.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),
            if (order.complaintId != null)
              SummarySection(
                icon: Iconsax.message_question,
                title: 'report.status'.tr,
                child: Text('report.ticket'.trParams({'n': order.complaintId!}), style: theme.titleSmall),
              ),
            8.height,
            const BookingActions(),
          ],
        );
      }),
    );
  }
}
