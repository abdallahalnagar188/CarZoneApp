import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_footer.dart';
import '../widgets/booking_step_header.dart';
import '../widgets/date_strip.dart';
import '../widgets/slot_grid.dart';

class BookingSlotPage extends StatefulWidget {
  const BookingSlotPage({super.key});

  @override
  State<BookingSlotPage> createState() => _BookingSlotPageState();
}

class _BookingSlotPageState extends State<BookingSlotPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = Get.find<BookingController>();
      if (c.slots.isEmpty) {
        c.loadSlots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final reschedule = controller.isReschedule;
    final theme = Theme.of(context).textTheme;

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
        padding: EdgeInsets.only(bottom: 24.h),
        children: [
          if (!reschedule) const BookingStepHeader(step: 3, labelKey: 'book.slot'),
          16.height,

          // Horizontal Date Selector
          const DateStrip(),
          16.height,

          // Service duration and branch timezone info pill
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.line),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.timer_1, size: 16.sp, color: AppColors.primary),
                  ),
                  10.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FormatHelper.isAr
                              ? 'مدة الخدمة: ${FormatHelper.minutes(controller.durationMin)}'
                              : 'Duration: ${FormatHelper.minutes(controller.durationMin)}',
                          style: theme.titleSmall?.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          FormatHelper.isAr
                              ? 'المواعيد المعروضة بالتوقيت المحلي للفرع (مصر)'
                              : 'Times displayed in Egypt branch local time',
                          style: theme.labelSmall?.copyWith(fontSize: 10.sp, color: AppColors.ink500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          20.height,

          // Title & slots grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Text(
                  'book.pickTime'.tr,
                  style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Obx(() {
                  if (controller.loadingSlots.value) {
                    return SizedBox(
                      width: 14.r,
                      height: 14.r,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
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
