import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/helpers/map_marker_helper.dart';
import '../../../../core/local/theme_controller.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../home/presentaion/controllers/home_controller.dart';

enum MapFilter { all, open, rated, washNow }

class WashMapController extends GetxController {
  final _discovery = DiscoveryService();
  final pageController = PageController(viewportFraction: 0.88);

  final rows = <BranchListingModel>[].obs;
  final markers = <Marker>{}.obs;
  final selected = 0.obs;
  final filter = MapFilter.all.obs;
  final mapStyle = RxnString();

  GoogleMapController? _map;
  bool _fromMarker = false;

  SessionService get session => Get.find<SessionService>();

  LatLng get me => LatLng(session.lat, session.lng);

  CameraPosition get initialCamera => CameraPosition(target: me, zoom: 12.6);

  @override
  void onInit() {
    super.onInit();
    _loadStyle();
    _loadMapData();
    ever(session.areaId, (_) async {
      await _loadMapData();
      _resetSelection();
      recenter();
    });
    ever(Get.find<CarzoneDbService>().orders, (_) => _compute());
    ever(Get.find<CarzoneDbService>().branches, (_) => _compute());
    ever(Get.find<ThemeController>().isDarkMode, (_) => _loadStyle());
  }

  Future<void> _loadMapData() async {
    await Get.find<CarzoneDbService>().fetchMapBranches(areaId: session.areaId.value);
    _compute();
  }

  Future<void> _loadStyle() async {
    mapStyle.value = await MapsService.style(dark: Get.find<ThemeController>().isDarkMode.value);
  }

  void onMapCreated(GoogleMapController controller) => _map = controller;

  void setFilter(MapFilter value) {
    filter.value = value;
    _compute();
    _resetSelection();
    if (rows.isNotEmpty) _focus(0);
  }

  void _resetSelection() {
    selected.value = 0;
    if (pageController.hasClients) pageController.jumpToPage(0);
    _buildMarkers();
  }

  void _compute() {
    var list = _discovery.apply(_discovery.listings(), const DiscoveryFilters());
    switch (filter.value) {
      case MapFilter.all:
        break;
      case MapFilter.open:
        list = list.where((r) => r.open).toList();
      case MapFilter.rated:
        list = list.where((r) => r.rating >= 4.5).toList();
      case MapFilter.washNow:
        list = _discovery.washNow();
    }
    rows.assignAll(list);
    if (selected.value >= rows.length) selected.value = 0;
    _buildMarkers();
  }

  Future<void> _buildMarkers() async {
    final next = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: me,
        icon: await MapMarkerHelper.userDot(),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 0,
      ),
    };
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final isSelected = i == selected.value;
      final state = isSelected ? PinState.selected : (r.open ? PinState.normal : PinState.closed);
      final label = r.fromPrice == null ? r.rating.toStringAsFixed(1) : FormatHelper.money(r.fromPrice!);
      next.add(Marker(
        markerId: MarkerId(r.branch.id),
        position: LatLng(r.branch.lat, r.branch.lng),
        icon: await MapMarkerHelper.pricePin(label, state),
        anchor: const Offset(0.5, 1),
        zIndexInt: isSelected ? 10 : 1,
        onTap: () => onMarkerTap(i),
      ));
    }
    markers.assignAll(next);
  }

  void onMarkerTap(int index) {
    _fromMarker = true;
    _focus(index, animatePage: true);
  }

  void onPageChanged(int index) {
    if (_fromMarker) {
      if (index == selected.value) _fromMarker = false;
      return;
    }
    _focus(index);
  }

  void _focus(int index, {bool animatePage = false}) {
    if (index >= rows.length) return;
    selected.value = index;
    _buildMarkers();
    final b = rows[index].branch;
    _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(b.lat, b.lng), 14));
    if (animatePage && pageController.hasClients) {
      pageController
          .animateToPage(index, duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic)
          .whenComplete(() => _fromMarker = false);
    }
  }

  void recenter() => _map?.animateCamera(CameraUpdate.newCameraPosition(initialCamera));

  void zoomIn() => _map?.animateCamera(CameraUpdate.zoomIn());

  void zoomOut() => _map?.animateCamera(CameraUpdate.zoomOut());

  void pickArea() => Get.find<HomeController>().pickArea();

  void openSearch() => Get.toNamed(Routes.searchRoute);

  void openWash(String id) => Get.toNamed(Routes.washDetailsRoute, arguments: id);

  void openList() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby'});

  void directions(BranchListingModel row) => MapsService.openDirections(row.branch.lat, row.branch.lng);

  @override
  void onClose() {
    pageController.dispose();
    _map?.dispose();
    super.onClose();
  }
}
