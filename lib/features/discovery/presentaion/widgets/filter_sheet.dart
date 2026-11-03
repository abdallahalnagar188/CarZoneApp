import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/results_controller.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ResultsController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final f = controller.draft.value;
      final range = controller.priceRange;
      final lo = range == null ? 0.0 : (f.priceMin ?? range.min).clamp(range.min, range.max);
      final hi = range == null ? 0.0 : (f.priceMax ?? range.max).clamp(range.min, range.max);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('f.distance'.tr, style: theme.titleSmall),
          10.height,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              AppChip(
                label: 'f.any'.tr,
                flat: true,
                selected: f.maxKm == null,
                onTap: () => controller.updateDraft(f.copyWith(maxKm: () => null)),
              ),
              for (final km in [1.0, 3.0, 5.0, 10.0, 20.0])
                AppChip(
                  label: FormatHelper.distance(km),
                  flat: true,
                  selected: f.maxKm == km,
                  onTap: () => controller.updateDraft(f.copyWith(maxKm: () => km)),
                ),
            ],
          ),
          20.height,
          Text('f.rating'.tr, style: theme.titleSmall),
          10.height,
          Wrap(
            spacing: 8.w,
            children: [
              AppChip(
                label: 'f.any'.tr,
                flat: true,
                selected: f.minRating == null,
                onTap: () => controller.updateDraft(f.copyWith(minRating: () => null)),
              ),
              for (final r in [4.0, 4.5])
                AppChip(
                  label: '★ $r+',
                  flat: true,
                  selected: f.minRating == r,
                  onTap: () => controller.updateDraft(f.copyWith(minRating: () => r)),
                ),
            ],
          ),
          // The range is the results' own prices, in the browsed country's currency.
          if (range != null) ...[
            20.height,
            Row(
              children: [
                Expanded(child: Text('f.price'.tr, style: theme.titleSmall)),
                Text(
                  '${FormatHelper.money(lo)} – ${FormatHelper.money(hi)}',
                  style: theme.labelMedium?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            RangeSlider(
              values: RangeValues(lo, hi),
              min: range.min,
              max: range.max,
              divisions: ((range.max - range.min) / _step(range)).round().clamp(1, 40),
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primarySoft2,
              // A handle back at the edge means no bound on that side.
              onChanged: (v) => controller.updateDraft(f.copyWith(
                priceMin: () => v.start <= range.min ? null : v.start,
                priceMax: () => v.end >= range.max ? null : v.end,
              )),
            ),
          ],
          8.height,
          _SwitchRow(
            label: 'f.open'.tr,
            value: f.openNow,
            onChanged: (v) => controller.updateDraft(f.copyWith(openNow: v)),
          ),
          _SwitchRow(
            label: 'f.today'.tr,
            value: f.availableToday,
            onChanged: (v) => controller.updateDraft(f.copyWith(availableToday: v)),
          ),
          16.height,
          Text('sort'.tr, style: theme.titleSmall),
          10.height,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: SortMode.values
                .map((s) => AppChip(
                      label: 'sort.${s.name}'.tr,
                      flat: true,
                      selected: f.sort == s,
                      onTap: () => controller.updateDraft(f.copyWith(sort: s)),
                    ))
                .toList(),
          ),
          24.height,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: 'f.reset'.tr,
                  variant: AppButtonVariant.ghost,
                  onTap: controller.resetDraft,
                ),
              ),
              12.width,
              Expanded(
                flex: 2,
                child: AppButton(title: 'f.apply'.tr, onTap: controller.applyDraft),
              ),
            ],
          ),
        ],
      );
    });
  }
}

/// Slider steps: tens for a wide range, ones for a narrow one (dinars).
double _step(({double min, double max}) range) {
  final span = range.max - range.min;
  if (span >= 200) return 10;
  if (span >= 40) return 5;
  return 1;
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
      ],
    );
  }
}
