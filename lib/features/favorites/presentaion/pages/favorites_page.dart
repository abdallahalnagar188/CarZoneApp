import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavoritesController>();
    return Scaffold(
      appBar: AppTopBar(title: 'profile.fav'.tr),
      body: Obx(() {
        final rows = controller.rows;
        if (rows.isEmpty) {
          return Center(
            child: CustomEmptyState(
              icon: Iconsax.heart,
              title: 'empty.fav'.tr,
              actionText: 'empty.favCta'.tr,
              onAction: controller.explore,
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(20.r),
          itemCount: rows.length,
          separatorBuilder: (_, __) => SizedBox(height: 14.h),
          itemBuilder: (_, i) => WashCard(
            row: rows[i],
            favorite: true,
            onTap: () => controller.openWash(rows[i].branch.id),
            onFavorite: () => controller.toggle(rows[i].branch.id),
          ),
        );
      }),
    );
  }
}
