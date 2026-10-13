import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/session_service.dart';

class WashMapController extends GetxController {
  final _discovery = DiscoveryService();
  final mapController = MapController();
  final pageController = PageController(viewportFraction: 0.86);

  final rows = <BranchListingModel>[].obs;
  final selected = 0.obs;

  SessionService get session => Get.find<SessionService>();

  LatLng get me => LatLng(session.lat, session.lng);

  @override
  void onInit() {
    super.onInit();
    _compute();
    ever(session.areaId, (_) {
      _compute();
      recenter();
    });
    ever(Get.find<CarzoneDbService>().orders, (_) => _compute());
  }

  void _compute() {
    rows.assignAll(_discovery.apply(_discovery.listings(), const DiscoveryFilters()));
  }

  void selectMarker(int index) {
    selected.value = index;
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void onPageChanged(int index) {
    selected.value = index;
    final b = rows[index].branch;
    mapController.move(LatLng(b.lat, b.lng), mapController.camera.zoom);
  }

  void recenter() => mapController.move(me, 12.5);

  void openWash(String id) => Get.toNamed(Routes.washDetailsRoute, arguments: id);

  void openList() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby'});

  @override
  void onClose() {
    pageController.dispose();
    mapController.dispose();
    super.onClose();
  }
}
