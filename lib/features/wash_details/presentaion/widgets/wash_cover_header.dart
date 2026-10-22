import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../favorites/presentaion/controllers/favorites_controller.dart';
import '../controllers/wash_details_controller.dart';

class WashCoverHeader extends StatelessWidget {
  const WashCoverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final favorites = Get.find<FavoritesController>();
    final row = controller.listing.value!;
    final theme = Theme.of(context).textTheme;
    return SliverAppBar(
      expandedHeight: 280.h,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.brand,
      automaticallyImplyLeading: false,
      titleSpacing: 16.w,
      title: Row(
        children: [
          AppIconButton(glass: true, icon: const DirIcon(Iconsax.arrow_left_2), onTap: Get.back),
          const Spacer(),
          Builder(
            builder: (buttonContext) => AppIconButton(
              glass: true,
              icon: const Icon(Iconsax.share),
              onTap: () {
                final box = buttonContext.findRenderObject() as RenderBox?;
                controller.share(box == null ? null : box.localToGlobal(Offset.zero) & box.size);
              },
            ),
          ),
          10.width,
          Obx(
            () => AppIconButton(
              glass: true,
              icon: Icon(
                favorites.ids.contains(controller.branchId) ? Iconsax.heart5 : Iconsax.heart,
                color: favorites.ids.contains(controller.branchId) ? Colors.red : Colors.white,
              ),
              onTap: controller.toggleFavorite,
            ),
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(photoId: AppNetworkImage.branchPhoto(row.branch.photoSeed), width: 900),
            DecoratedBox(decoration: BoxDecoration(gradient: AppColors.photoShade)),
            PositionedDirectional(
              start: 20.w,
              end: 20.w,
              bottom: 22.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 56.r,
                    height: 56.r,
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: AppLogo(size: 40.r),
                  ),
                  12.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.branch.name.value,
                          maxLines: 2,
                          style: theme.headlineMedium?.copyWith(color: Colors.white),
                        ),
                        4.height,
                        Row(
                          children: [
                            Icon(Iconsax.star1, size: 15.sp, color: AppColors.star),
                            4.width,
                            Text(
                              'ratingCount'.trParams({
                                'rating': row.rating.toStringAsFixed(1),
                                'count': '${row.reviewCount}',
                              }),
                              style: theme.labelMedium?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
