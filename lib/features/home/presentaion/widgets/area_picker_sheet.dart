import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/country_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/services/washup_db_service.dart';
import '../controllers/home_controller.dart';

/// Location first, then a country and one of its areas. Countries come from
/// the database, so a new country shows up here once it has an area.
class AreaPickerSheet extends StatefulWidget {
  const AreaPickerSheet({super.key});

  @override
  State<AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<AreaPickerSheet> {
  final controller = Get.find<HomeController>();
  final db = Get.find<WashUpDbService>();
  late String country = controller.session.countryCode.value;
  bool allCountries = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final served = db.servedCountries;
      final shown = allCountries ? db.countries.toList() : served;
      final current = db.country(country);
      // The browsed and the picked country stay listed even with no areas yet.
      for (final c in {db.country(controller.session.countryCode.value), current}) {
        if (!shown.any((x) => x.code == c.code)) shown.insert(0, c);
      }
      final areas = db.areasIn(country);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            title: 'loc.use'.tr,
            icon: Iconsax.gps,
            variant: AppButtonVariant.sand,
            onTap: controller.useMyLocation,
          ),
          18.height,
          Text('loc.country'.tr, style: theme.titleSmall),
          10.height,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ...shown.map((c) => _CountryChip(
                    country: c,
                    selected: c.code == country,
                    onTap: () => setState(() => country = c.code),
                  )),
              if (!allCountries && db.countries.length > served.length)
                AppChip(
                  label: 'loc.moreCountries'.tr,
                  icon: Iconsax.global,
                  flat: true,
                  onTap: () => setState(() => allCountries = true),
                ),
            ],
          ),
          18.height,
          Text('loc.pick'.tr, style: theme.titleSmall),
          10.height,
          if (areas.isEmpty)
            RoundedContainer(
              color: AppColors.primarySoft,
              child: Text(
                'loc.noAreas'.trParams({'country': current.name.value}),
                style: theme.bodyMedium?.copyWith(color: AppColors.primary),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: areas
                  .map((a) => AppChip(
                        label: a.name.value,
                        icon: Iconsax.location,
                        flat: true,
                        selected: controller.session.areaId.value == a.id,
                        onTap: () => controller.selectArea(a.id),
                      ))
                  .toList(),
            ),
          if (country != controller.session.countryCode.value || controller.session.areaId.value.isNotEmpty) ...[
            14.height,
            AppButton(
              title: 'loc.wholeCountry'.trParams({'country': current.name.value}),
              icon: Iconsax.map_1,
              variant: AppButtonVariant.ghost,
              small: true,
              onTap: () => controller.selectCountry(country),
            ),
          ],
        ],
      );
    });
  }
}

class _CountryChip extends StatelessWidget {
  final CountryModel country;
  final bool selected;
  final VoidCallback onTap;

  const _CountryChip({required this.country, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: TextStyle(fontSize: 16.sp)),
            6.width,
            Text(
              country.name.value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? Colors.white : AppColors.ink900),
            ),
          ],
        ),
      ),
    );
  }
}
