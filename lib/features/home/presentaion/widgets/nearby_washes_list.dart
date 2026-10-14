import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../favorites/presentaion/controllers/favorites_controller.dart';
import '../controllers/home_controller.dart';

class NearbyWashesList extends StatelessWidget {
  const NearbyWashesList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final favorites = Get.find<FavoritesController>();
    return SizedBox(
      height: 252.h,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
          itemCount: controller.nearby.length,
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemBuilder: (_, i) {
            final row = controller.nearby[i];
            return FadeSlideIn(
              delay: Duration(milliseconds: 90 * i.clamp(0, 4)),
              offsetY: 18,
              child: Obx(
                () => WashCard(
                  width: 250.w,
                  row: row,
                  favorite: favorites.ids.contains(row.branch.id),
                  onTap: () => controller.openWash(row.branch.id),
                  onFavorite: () => favorites.toggle(row.branch.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
