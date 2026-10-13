import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../controllers/wash_map_controller.dart';
import '../widgets/map_branch_card.dart';
import '../widgets/map_pin.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashMapController>();
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Obx(
            () => FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(initialCenter: controller.me, initialZoom: 12.5),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.carzone.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(point: controller.me, width: 44, height: 44, child: const UserDot()),
                    for (var i = 0; i < controller.rows.length; i++)
                      Marker(
                        point: LatLng(controller.rows[i].branch.lat, controller.rows[i].branch.lng),
                        width: 48,
                        height: 56,
                        alignment: Alignment.topCenter,
                        child: MapPin(
                          open: controller.rows[i].open,
                          selected: controller.selected.value == i,
                          onTap: () => controller.selectMarker(i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: top + 12.h,
            start: 16.w,
            end: 16.w,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: AppColors.liftShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.location, color: AppColors.primary, size: 18.sp),
                        SizedBox(width: 8.w),
                        Obx(
                          () => Text(
                            controller.session.area.name.value,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                AppIconButton(icon: const Icon(Iconsax.row_vertical), onTap: controller.openList, size: 46.r),
                SizedBox(width: 10.w),
                AppIconButton(icon: const Icon(Iconsax.gps), onTap: controller.recenter, size: 46.r),
              ],
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 110.h + MediaQuery.paddingOf(context).bottom,
            child: SizedBox(
              height: 112.h,
              child: Obx(
                () => PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  itemCount: controller.rows.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: MapBranchCard(
                      row: controller.rows[i],
                      onTap: () => controller.openWash(controller.rows[i].branch.id),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
