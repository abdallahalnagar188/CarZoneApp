import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../favorites/presentaion/controllers/favorites_controller.dart';
import '../controllers/results_controller.dart';
import '../widgets/results_toolbar.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ResultsController>();
    final favorites = Get.find<FavoritesController>();
    return Scaffold(
      appBar: AppTopBar(title: controller.title),
      body: Column(
        children: [
          SizedBox(height: 14.h),
          const ResultsToolbar(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) return const AppShimmerList(itemHeight: 220);
              if (controller.rows.isEmpty) {
                return Center(
                  child: CustomEmptyState(
                    icon: Iconsax.search_status,
                    title: 'empty.results'.tr,
                    actionText: 'empty.clear'.tr,
                    onAction: controller.clearFilters,
                    secondaryText: 'empty.area'.tr,
                    onSecondary: controller.changeArea,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 30.h),
                  itemCount: controller.rows.length,
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemBuilder: (_, i) {
                    final row = controller.rows[i];
                    return Obx(
                      () => WashCard(
                        row: row,
                        favorite: favorites.ids.contains(row.branch.id),
                        onTap: () => controller.openWash(row.branch.id),
                        onFavorite: () => favorites.toggle(row.branch.id),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
