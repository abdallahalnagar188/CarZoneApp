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
              for (final km in [1.0, 3.0, 5.0, 10.0])
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
          20.height,
          Row(
            children: [
              Expanded(child: Text('f.price'.tr, style: theme.titleSmall)),
              Text(
                '${FormatHelper.money(f.priceMin)} – ${FormatHelper.money(f.priceMax)}',
                style: theme.labelMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(f.priceMin, f.priceMax),
            min: 0,
            max: 500,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primarySoft2,
            onChanged: (v) => controller.updateDraft(f.copyWith(priceMin: v.start, priceMax: v.end)),
          ),
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
