import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/enums/enums.dart';
import '../controllers/results_controller.dart';

class ResultsToolbar extends StatelessWidget {
  const ResultsToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ResultsController>();
    return SizedBox(
      height: 40.h,
      child: Obx(() {
        final f = controller.filters.value;
        final count = f.activeCount;
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          children: [
            AppChip(
              label: count > 0 ? 'filter.count'.trParams({'n': '$count'}) : 'filter'.tr,
              icon: Iconsax.setting_4,
              selected: count > 0,
              onTap: controller.openFilters,
            ),
            for (final s in SortMode.values) ...[
              SizedBox(width: 8.w),
              AppChip(
                label: 'sort.${s.name}'.tr,
                flat: true,
                selected: f.sort == s,
                onTap: () => controller.setSort(s),
              ),
            ],
          ],
        );
      }),
    );
  }
}
