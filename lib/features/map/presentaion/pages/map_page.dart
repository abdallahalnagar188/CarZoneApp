import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/system_ui.dart';
import '../controllers/wash_map_controller.dart';
import '../widgets/map_branch_carousel.dart';
import '../widgets/map_side_actions.dart';
import '../widgets/map_top_bar.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashMapController>();
    final top = MediaQuery.paddingOf(context).top;
    final bottomNav = MediaQuery.paddingOf(context).bottom + 4.h;
    final carouselHeight = 150.h;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.adaptive,
      child: Stack(
        children: [
          Obx(
            () => GoogleMap(
              initialCameraPosition: controller.initialCamera,
              onMapCreated: controller.onMapCreated,
              markers: controller.markers.toSet(),
              style: controller.mapStyle.value,
              padding: EdgeInsets.only(top: top + 110.h, bottom: bottomNav + carouselHeight),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              buildingsEnabled: false,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: top + 140.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: top + 10.h, left: 0, right: 0, child: const MapTopBar()),
          Positioned(
            right: 16.w,
            bottom: bottomNav + carouselHeight + 16.h,
            child: const MapSideActions(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomNav,
            height: carouselHeight,
            child: const MapBranchCarousel(),
          ),
        ],
      ),
    );
  }
}
