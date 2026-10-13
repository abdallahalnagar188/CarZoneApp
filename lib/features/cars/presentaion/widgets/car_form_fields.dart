import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/vehicle_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String? error;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.error,
  });

  void _open() {
    if (options.isEmpty) return;
    AppBottomSheet.show(
      title: label,
      child: Column(
        children: options
            .map((o) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o),
                  trailing: o == value ? Icon(Iconsax.tick_circle, color: AppColors.primary) : null,
                  onTap: () {
                    onSelected(o);
                    Get.back();
                  },
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.titleSmall),
        8.height,
        GestureDetector(
          onTap: _open,
          child: Container(
            height: 54.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: error != null ? AppColors.danger : AppColors.line, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? '—',
                    style: theme.bodyLarge?.copyWith(color: value == null ? AppColors.hintGray : AppColors.ink900),
                  ),
                ),
                Icon(Iconsax.arrow_down_1, size: 18.sp, color: AppColors.ink500),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          6.height,
          Text(error!, style: theme.bodySmall?.copyWith(color: AppColors.danger)),
        ],
      ],
    );
  }
}

class ColorSwatches extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ColorSwatches({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: VehicleModel.colors.entries.map((e) {
        final on = e.key == value;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42.r,
            height: 42.r,
            padding: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: on ? AppColors.primary : Colors.transparent, width: 2.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: e.value,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: on
                  ? Icon(
                      Iconsax.tick_circle,
                      size: 18.sp,
                      color: e.value.computeLuminance() > 0.5 ? AppColors.brand : Colors.white,
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
