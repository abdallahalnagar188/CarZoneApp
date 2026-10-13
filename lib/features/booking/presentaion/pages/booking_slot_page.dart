import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_footer.dart';
import '../widgets/booking_step_header.dart';
import '../widgets/date_strip.dart';
import '../widgets/slot_grid.dart';

class BookingSlotPage extends StatelessWidget {
  const BookingSlotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final reschedule = controller.isReschedule;
    return Scaffold(
      appBar: AppTopBar(title: reschedule ? 'reschedule.title'.tr : (controller.branch?.name.value ?? '')),
      bottomNavigationBar: Obx(
        () => BookingFooter(
          title: reschedule ? 'reschedule.title'.tr : 'book.continue'.tr,
          showTotal: !reschedule,
          loading: controller.confirming.value,
          enabled: controller.slot.value != null,
          onTap: controller.continueFromSlot,
        ),
      ),
      body: ListView(
        children: [
          if (!reschedule) const BookingStepHeader(step: 3, labelKey: 'book.slot'),
          16.height,
          const DateStrip(),
          20.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text('book.pickTime'.tr, style: Theme.of(context).textTheme.titleLarge),
          ),
          12.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const SlotGrid(),
          ),
        ],
      ),
    );
  }
}
