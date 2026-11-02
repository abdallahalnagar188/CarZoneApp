import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/phone_helper.dart';

/// Opens the searchable country list; resolves to the chosen country.
Future<PhoneCountry?> pickPhoneCountry(PhoneCountry selected) =>
    AppBottomSheet.show<PhoneCountry>(
      title: 'phone.country'.tr,
      child: CountryPicker(selected: selected),
    );

class CountryPicker extends StatefulWidget {
  final PhoneCountry selected;

  const CountryPicker({super.key, required this.selected});

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  String _query = '';

  List<PhoneCountry> get _matches {
    final q = _query.trim().toLowerCase().replaceFirst('+', '');
    if (q.isEmpty) return PhoneHelper.countries;
    return PhoneHelper.countries
        .where((c) =>
            c.nameAr.contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.dialCode.substring(1).startsWith(q) ||
            c.iso.name.toLowerCase() == q)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lang = Get.locale?.languageCode ?? 'ar';
    final matches = _matches;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          hint: 'phone.search'.tr,
          dense: true,
          onChanged: (v) => setState(() => _query = v),
          prefix: Icon(Iconsax.search_normal_1, size: 18.sp, color: AppColors.ink500),
        ),
        8.height,
        if (matches.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Text(
              'phone.empty'.tr,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.ink500),
            ),
          ),
        for (final c in matches)
          InkWell(
            onTap: () => Get.back(result: c),
            borderRadius: BorderRadius.circular(14.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
              child: Row(
                children: [
                  Text(c.flag, style: TextStyle(fontSize: 24.sp)),
                  12.width,
                  Expanded(child: Text(c.name(lang), style: text.bodyLarge)),
                  Text(
                    c.dialCode,
                    textDirection: TextDirection.ltr,
                    style: text.titleSmall?.copyWith(color: AppColors.ink500),
                  ),
                  if (c == widget.selected) ...[
                    12.width,
                    Icon(Iconsax.tick_circle5, size: 20.sp, color: AppColors.primary),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
