import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/services/availability_service.dart';
import '../controllers/booking_controller.dart';

class SlotGrid extends StatelessWidget {
  const SlotGrid({super.key});

  int _slotHour(SlotModel s) {
    if (s.localTime != null && s.localTime!.contains(':')) {
      return int.tryParse(s.localTime!.split(':')[0]) ?? s.start.hour;
    }
    if (s.start.isUtc) {
      return s.start.add(BranchTimeHelper.cairoOffset(s.start)).hour;
    }
    return s.start.hour;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final theme = Theme.of(context).textTheme;

    return Obx(() {
      final isLoading = controller.loadingSlots.value;
      final slots = controller.slots;

      // Loading state when slots list is empty
      if (isLoading && slots.isEmpty) {
        return _buildShimmerGrid();
      }

      // Empty state when no slots exist for the selected day
      if (slots.isEmpty) {
        return _buildEmptyState(context, controller);
      }

      final morningSlots = slots.where((s) => _slotHour(s) < 12).toList();
      final afternoonSlots = slots.where((s) {
        final h = _slotHour(s);
        return h >= 12 && h < 17;
      }).toList();
      final eveningSlots = slots.where((s) => _slotHour(s) >= 17).toList();

      final sections = <_SlotGroupData>[
        if (morningSlots.isNotEmpty)
          _SlotGroupData(
            titleKey: 'book.morning',
            timeRange: FormatHelper.isAr ? '09:00 ص - 12:00 م' : '09:00 AM - 12:00 PM',
            icon: Iconsax.sun_1,
            iconColor: AppColors.warning,
            iconBg: AppColors.warning.withValues(alpha: 0.12),
            slots: morningSlots,
          ),
        if (afternoonSlots.isNotEmpty)
          _SlotGroupData(
            titleKey: 'book.afternoon',
            timeRange: FormatHelper.isAr ? '12:00 م - 05:00 م' : '12:00 PM - 05:00 PM',
            icon: Iconsax.cloud_sunny,
            iconColor: AppColors.brandSky,
            iconBg: AppColors.brandSky.withValues(alpha: 0.12),
            slots: afternoonSlots,
          ),
        if (eveningSlots.isNotEmpty)
          _SlotGroupData(
            titleKey: 'book.evening',
            timeRange: FormatHelper.isAr ? '05:00 م - 09:00 م' : '05:00 PM - 09:00 PM',
            icon: Iconsax.moon,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft2,
            slots: eveningSlots,
          ),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((sec) => _buildSection(context, controller, theme, sec)).toList(),
      );
    });
  }

  Widget _buildSection(
    BuildContext context,
    BookingController controller,
    TextTheme theme,
    _SlotGroupData sec,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon, title, range, and slot counter badge
          Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: sec.iconBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(sec.icon, size: 18.sp, color: sec.iconColor),
              ),
              10.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sec.titleKey.tr,
                    style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    sec.timeRange,
                    style: theme.labelSmall?.copyWith(color: AppColors.ink500, fontSize: 10.sp),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary500.withValues(alpha: 0.2)),
                ),
                child: Text(
                  FormatHelper.isAr ? '${sec.slots.length} متاح' : '${sec.slots.length} available',
                  style: theme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          12.height,

          // Grid of slot cards
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 2.15,
            children: sec.slots.map((s) {
              return _SlotCard(
                key: ValueKey('slot_${s.start.millisecondsSinceEpoch}_${s.localTime}'),
                slot: s,
                controller: controller,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, BookingController controller) {
    final theme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      margin: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.calendar_remove, size: 36.sp, color: AppColors.primary),
          ),
          16.height,
          Text(
            FormatHelper.isAr ? 'انتهت مواعيد اليوم' : 'No available slots today',
            style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          8.height,
          Text(
            FormatHelper.isAr
                ? 'جميع مواعيد هذا اليوم مكتملة أو انتهت ساعات العمل. يمكنك الحجز ليوم غد بكل سهولة.'
                : 'All slots for this date are booked or outside working hours. You can easily book for tomorrow.',
            style: theme.bodySmall?.copyWith(color: AppColors.ink500),
            textAlign: TextAlign.center,
          ),
          20.height,
          InkWell(
            onTap: controller.seeTomorrow,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: AppColors.buttonShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.calendar_1, size: 18.sp, color: Colors.white),
                  8.width,
                  Text(
                    'book.seeTomorrow'.tr,
                    style: theme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  8.width,
                  Icon(
                    FormatHelper.isAr ? Iconsax.arrow_left_2 : Iconsax.arrow_right_3,
                    size: 16.sp,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 2.15,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final SlotModel slot;
  final BookingController controller;

  const _SlotCard({
    super.key,
    required this.slot,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final timeStr = slot.formattedTime();

    return Obx(() {
      final selected = controller.slot.value;
      final isSelected = selected != null &&
          (selected.isAtSameMomentAs(slot.start) ||
              selected == slot.start ||
              (selected.year == slot.start.year &&
                  selected.month == slot.start.month &&
                  selected.day == slot.start.day &&
                  selected.hour == slot.start.hour &&
                  selected.minute == slot.start.minute));

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.selectSlot(slot.start);
          },
          borderRadius: BorderRadius.circular(16.r),
          splashColor: AppColors.primary.withValues(alpha: 0.2),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: isSelected
                  ? Border.all(color: AppColors.brandSky, width: 1.5)
                  : Border.all(color: AppColors.line, width: 1.4),
              boxShadow: isSelected ? AppColors.buttonShadow : AppColors.softShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isSelected) ...[
                      Icon(Iconsax.tick_circle5, size: 14.sp, color: Colors.white),
                      4.width,
                    ],
                    Text(
                      timeStr,
                      style: theme.titleSmall?.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.ink900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                if (slot.fewLeft) ...[
                  2.height,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'book.few'.tr,
                      style: theme.labelSmall?.copyWith(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SlotGroupData {
  final String titleKey;
  final String timeRange;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<SlotModel> slots;

  const _SlotGroupData({
    required this.titleKey,
    required this.timeRange,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.slots,
  });
}
