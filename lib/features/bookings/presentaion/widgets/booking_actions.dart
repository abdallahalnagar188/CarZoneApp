import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/enums/enums.dart';
import '../controllers/booking_details_controller.dart';

class BookingActions extends StatelessWidget {
  const BookingActions({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingDetailsController>();
    final order = controller.order.value!;
    final buttons = <Widget>[
      if (order.status == OrderStatus.completed)
        AppButton(
          title: (controller.hasReview ? 'review.view' : 'review.title').tr,
          icon: Iconsax.star_1,
          variant: controller.hasReview ? AppButtonVariant.ghost : AppButtonVariant.primary,
          onTap: controller.hasReview ? null : controller.review,
        ),
      if (order.status.canCancel) ...[
        AppButton(
          title: 'book.reschedule'.tr,
          icon: Iconsax.calendar_edit,
          variant: AppButtonVariant.sand,
          onTap: controller.reschedule,
        ),
        AppButton(
          title: 'book.cancel'.tr,
          icon: Iconsax.close_circle,
          variant: AppButtonVariant.ghost,
          onTap: controller.openCancel,
        ),
      ],
      if (!order.status.isUpcoming)
        AppButton(
          title: 'book.again'.tr,
          icon: Iconsax.refresh,
          variant: AppButtonVariant.sand,
          onTap: controller.bookAgain,
        ),
      if (controller.canReport && order.complaintId == null)
        AppButton(
          title: 'report.title'.tr,
          icon: Iconsax.message_question,
          variant: AppButtonVariant.ghost,
          onTap: controller.report,
        ),
    ];
    return Column(
      children: buttons
          .map((b) => Padding(padding: EdgeInsets.only(bottom: 10.h), child: b))
          .toList(),
    );
  }
}
