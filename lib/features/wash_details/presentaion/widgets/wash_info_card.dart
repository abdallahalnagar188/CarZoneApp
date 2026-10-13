import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/wash_details_controller.dart';

class WashInfoCard extends StatelessWidget {
  const WashInfoCard({super.key});

  String _hours(String open, String close, bool closed) =>
      closed ? 'closed'.tr : '${_clock(open)} – ${_clock(close)}';

  String _clock(String hhmm) {
    final m = FormatHelper.clockToMinutes(hhmm);
    return FormatHelper.time(DateTime(2020, 1, 1).add(Duration(minutes: m)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final row = controller.listing.value!;
    final b = row.branch;
    final theme = Theme.of(context).textTheme;
    final today = b.hoursFor(DateTime.now());
    return RoundedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Iconsax.location,
            child: Text('${b.address.value} · ${FormatHelper.distance(row.km)}', style: theme.bodyMedium),
          ),
          12.height,
          GestureDetector(
            onTap: controller.toggleHours,
            behavior: HitTestBehavior.opaque,
            child: _InfoRow(
              icon: Iconsax.clock,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.tint(row.open ? AppColors.success : AppColors.ink500),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      (row.open ? 'open' : 'closed').tr,
                      style: theme.labelSmall?.copyWith(
                        color: row.open ? AppColors.success : AppColors.ink500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: Text(
                      'wash.today'.trParams({'hours': _hours(today.open, today.close, today.closed)}),
                      style: theme.bodyMedium,
                    ),
                  ),
                  Obx(
                    () => AnimatedRotation(
                      turns: controller.hoursExpanded.value ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Iconsax.arrow_down_1, size: 16.sp, color: AppColors.ink500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: !controller.hoursExpanded.value
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsetsDirectional.only(start: 32.w, top: 10.h),
                      child: Column(
                        children: List.generate(7, (i) {
                          final day = DateTime.now().add(Duration(days: i));
                          final h = b.hoursFor(day);
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.h),
                            child: Row(
                              children: [
                                Expanded(child: Text(FormatHelper.dayName(day), style: theme.bodySmall)),
                                Text(_hours(h.open, h.close, h.closed), style: theme.labelMedium?.copyWith(color: AppColors.ink900)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
            ),
          ),
          16.height,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: 'wash.call'.tr,
                  icon: Iconsax.call,
                  small: true,
                  variant: AppButtonVariant.ghost,
                  onTap: controller.call,
                ),
              ),
              10.width,
              Expanded(
                child: AppButton(
                  title: 'wash.nav'.tr,
                  icon: Iconsax.routing,
                  small: true,
                  variant: AppButtonVariant.ghost,
                  onTap: controller.navigate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _InfoRow({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.primary),
        ),
        10.width,
        Expanded(child: child),
      ],
    );
  }
}
