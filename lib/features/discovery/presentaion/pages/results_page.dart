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
          SizedBox(height: 18.h),
          const ResultsToolbar(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) return const AppShimmerList(itemHeight: 220);
              if (controller.rows.isEmpty) {
                return CustomEmptyState(
                  icon: Iconsax.search_status,
                  title: 'empty.results'.tr,
                  actionText: 'empty.clear'.tr,
                  onAction: controller.clearFilters,
                  secondaryText: 'empty.area'.tr,
                  onSecondary: controller.changeArea,
                );
              }
              return Column(
                children: [
                  if (controller.isWashNow && controller.isClosedHours.value)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.info_circle, color: Colors.amber[800], size: 18.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'results.closedNotice'.tr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.amber[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView.separated(
                        controller: controller.scrollController,
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
                        itemCount: controller.rows.length + (controller.loadingMore.value ? 1 : 0),
                        separatorBuilder: (_, __) => SizedBox(height: 14.h),
                        itemBuilder: (_, i) {
                          if (i == controller.rows.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
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
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
