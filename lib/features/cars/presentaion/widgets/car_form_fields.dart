import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/car_catalog.dart';
import '../../../../commons/models/vehicle_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/helpers/phone_helper.dart';
import '../../../../core/helpers/plate_helper.dart';

/// A field that opens a searchable list. With [allowCustom] the customer can
/// type a value that is not in the list (a make or model we do not carry).
class PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String? error;
  final List<String> options;
  final ValueChanged<String> onSelected;

  /// Arabic name per option, shown under it and matched by search.
  final Map<String, String> subtitles;
  final bool allowCustom;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.error,
    this.subtitles = const {},
    this.allowCustom = false,
  });

  void _open() {
    if (options.isEmpty && !allowCustom) return;
    AppBottomSheet.show(
      title: label,
      child: _PickerSheet(
        options: options,
        value: value,
        subtitles: subtitles,
        allowCustom: allowCustom,
        onSelected: (v) {
          onSelected(v);
          Get.back();
        },
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
                    value ?? 'cars.choose'.tr,
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

class _PickerSheet extends StatefulWidget {
  final List<String> options;
  final String? value;
  final Map<String, String> subtitles;
  final bool allowCustom;
  final ValueChanged<String> onSelected;

  const _PickerSheet({
    required this.options,
    required this.value,
    required this.subtitles,
    required this.allowCustom,
    required this.onSelected,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final q = CarCatalog.searchKey(_search.text);
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) =>
            CarCatalog.searchKey(o).contains(q) || CarCatalog.searchKey(widget.subtitles[o] ?? '').contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final typed = FormatHelper.latinDigits(_search.text.trim());
    final matches = _matches;
    // Typing a listed name, in English or Arabic, picks it rather than adding a new one.
    final key = CarCatalog.searchKey(typed);
    final exact = matches.any(
        (o) => CarCatalog.searchKey(o) == key || CarCatalog.searchKey(widget.subtitles[o] ?? '') == key);
    return Padding(
      // The keyboard covers the sheet's bottom otherwise.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _search,
            hint: (widget.options.isEmpty ? 'cars.typeName' : 'cars.search').tr,
            prefix: const Icon(Iconsax.search_normal_1),
            autofocus: widget.options.isEmpty,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (typed.isEmpty) return;
              if (matches.length == 1) return widget.onSelected(matches.first);
              if (widget.allowCustom) widget.onSelected(typed);
            },
          ),
          8.height,
          if (widget.allowCustom && typed.isNotEmpty && !exact)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Iconsax.add_circle, color: AppColors.primary),
              title: Text('cars.useTyped'.trParams({'name': typed}), style: theme.titleSmall),
              onTap: () => widget.onSelected(typed),
            ),
          ...matches.map((o) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(o),
                subtitle: widget.subtitles[o] == null ? null : Text(widget.subtitles[o]!, style: theme.bodySmall),
                trailing: o == widget.value ? Icon(Iconsax.tick_circle, color: AppColors.primary) : null,
                onTap: () => widget.onSelected(o),
              )),
          if (matches.isEmpty && !widget.allowCustom)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text('cars.noMatch'.tr, textAlign: TextAlign.center, style: theme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

/// A plate laid out like the plate itself: a band with the country, the
/// letters (or emirate code) on the right and the number on the left. The
/// country chip switches the rules for the Arab country the car is from.
class PlateInput extends StatelessWidget {
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final TextEditingController code;
  final TextEditingController digits;
  final String? error;
  final VoidCallback onChanged;

  const PlateInput({
    super.key,
    required this.country,
    required this.onCountryChanged,
    required this.code,
    required this.digits,
    required this.onChanged,
    this.error,
  });

  void _pickCountry() {
    AppBottomSheet.show(
      title: 'cars.plateCountry'.tr,
      child: Column(
        children: PhoneHelper.countries
            .map((c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(c.flag, style: TextStyle(fontSize: 22.sp)),
                  title: Text(c.name(Get.locale?.languageCode ?? 'ar')),
                  trailing: c.iso == country.iso ? Icon(Iconsax.tick_circle, color: AppColors.primary) : null,
                  onTap: () {
                    onCountryChanged(c);
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
    final lettered = PlateHelper.lettered(country);
    final maxDigits = PlateHelper.maxDigits(country);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('cars.plate'.tr, style: theme.titleSmall)),
            GestureDetector(
              onTap: _pickCountry,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(country.flag, style: TextStyle(fontSize: 16.sp)),
                    6.width,
                    Text(country.name(Get.locale?.languageCode ?? 'ar'), style: theme.labelMedium),
                    4.width,
                    Icon(Iconsax.arrow_down_1, size: 14.sp, color: AppColors.ink500),
                  ],
                ),
              ),
            ),
          ],
        ),
        10.height,
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: error != null ? AppColors.danger : AppColors.ink900, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 26.h,
                color: const Color(0xFF1E6FD9),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: TextDirection.ltr,
                  children: [
                    Text(country.nameEn.toUpperCase(),
                        style: theme.labelMedium?.copyWith(color: Colors.white, letterSpacing: 2)),
                    Text(country.nameAr, style: theme.labelLarge?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: _PlatePart(
                        // A new controller state per rule set, so the formatter swaps.
                        key: ValueKey(lettered),
                        controller: code,
                        hint: lettered ? 'أ ب ج' : 'A',
                        maxLength: 5,
                        formatters: [PlateCodeFormatter(arabicLetters: lettered)],
                        onChanged: onChanged,
                      ),
                    ),
                    VerticalDivider(width: 2, thickness: 2, color: AppColors.ink900),
                    Expanded(
                      flex: lettered ? 1 : 2,
                      child: _PlatePart(
                        controller: digits,
                        hint: '123456'.substring(0, maxDigits),
                        maxLength: maxDigits,
                        keyboardType: TextInputType.number,
                        formatters: [const LatinDigitsFormatter(), FilteringTextInputFormatter.digitsOnly],
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        6.height,
        Text(
          error ?? (lettered ? 'cars.plateLettersHint' : 'cars.plateCodeHelp').tr,
          style: theme.bodySmall?.copyWith(color: error != null ? AppColors.danger : AppColors.ink500),
        ),
      ],
    );
  }
}

class _PlatePart extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> formatters;
  final VoidCallback onChanged;

  const _PlatePart({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.formatters,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: keyboardType,
      inputFormatters: [...formatters, LengthLimitingTextInputFormatter(maxLength)],
      onChanged: (_) => onChanged(),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 6),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.hintGray, letterSpacing: 6),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h),
      ),
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
      spacing: 10.w,
      runSpacing: 12.h,
      children: VehicleModel.colors.entries.map((e) {
        final on = e.key == value;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: SizedBox(
            width: 58.w,
            child: Column(
              children: [
                AnimatedContainer(
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
                4.height,
                Text(
                  (VehicleModel.colorNames[e.key] ?? e.key).tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: on ? AppColors.primary : AppColors.ink500,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
