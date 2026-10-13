import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/wash_search_controller.dart';
import '../widgets/search_result_tile.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashSearchController>();
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(
        title: 'search.ph'.tr,
        bottom: AppTextField(
          controller: controller.textController,
          hint: 'search.ph'.tr,
          autofocus: true,
          dense: true,
          textInputAction: TextInputAction.search,
          prefix: Icon(Iconsax.search_normal_1, color: AppColors.ink500, size: 20.sp),
          onChanged: controller.onChanged,
          onSubmitted: controller.submit,
        ),
      ),
      body: Obx(() {
        if (controller.query.value.isEmpty) {
          return ListView(
            padding: EdgeInsets.all(20.r),
            children: [
              if (controller.recent.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(child: Text('search.recent'.tr, style: theme.titleMedium)),
                    TextButton(
                      onPressed: controller.clearRecent,
                      child: Text('search.clear'.tr, style: theme.labelMedium?.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: controller.recent
                      .map((r) => AppChip(label: r, icon: Iconsax.clock, flat: true, onTap: () => controller.useRecent(r)))
                      .toList(),
                ),
              ] else
                CustomEmptyState(icon: Iconsax.search_normal_1, title: 'search.ph'.tr),
            ],
          );
        }
        if (!controller.hasResults) {
          return CustomEmptyState(icon: Iconsax.search_status, title: 'empty.search'.tr);
        }
        return ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            if (controller.washes.isNotEmpty) ...[
              Text('search.washes'.tr, style: theme.titleMedium),
              10.height,
              ...controller.washes.map((r) => SearchResultTile(
                    icon: Iconsax.shop,
                    title: r.branch.name.value,
                    subtitle:
                        '${FormatHelper.distance(r.km)} · ${(r.open ? 'open' : 'closed').tr} · ${r.nextSlot == null ? '—' : FormatHelper.time(r.nextSlot!)}',
                    onTap: () => controller.openWash(r.branch.id),
                  )),
              16.height,
            ],
            if (controller.categories.isNotEmpty) ...[
              Text('search.services'.tr, style: theme.titleMedium),
              10.height,
              ...controller.categories.map((c) => SearchResultTile(
                    icon: Iconsax.magic_star,
                    title: 'cat.$c'.tr,
                    onTap: () => controller.openCategory(c),
                  )),
              16.height,
            ],
            if (controller.areas.isNotEmpty) ...[
              Text('search.areas'.tr, style: theme.titleMedium),
              10.height,
              ...controller.areas.map((a) => SearchResultTile(
                    icon: Iconsax.location,
                    title: a.name.value,
                    onTap: () => controller.openArea(a.id),
                  )),
            ],
          ],
        );
      }),
    );
  }
}
