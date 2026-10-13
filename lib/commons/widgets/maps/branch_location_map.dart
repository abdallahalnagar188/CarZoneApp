import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../../../core/helpers/map_marker_helper.dart';
import '../../../core/services/maps_service.dart';
import '../button/app_button.dart';

class BranchLocationMap extends StatefulWidget {
  final double lat;
  final double lng;
  final String address;
  final String pinLabel;

  const BranchLocationMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.address,
    required this.pinLabel,
  });

  @override
  State<BranchLocationMap> createState() => _BranchLocationMapState();
}

class _BranchLocationMapState extends State<BranchLocationMap> {
  BitmapDescriptor? _icon;
  String? _style;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final icon = await MapMarkerHelper.pricePin(widget.pinLabel, PinState.selected);
    final style = await MapsService.style(dark: AppColors.isDark);
    if (!mounted) return;
    setState(() {
      _icon = icon;
      _style = style;
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = LatLng(widget.lat, widget.lng);
    final theme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 150.h,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              style: _style,
              liteModeEnabled: GetPlatform.isAndroid,
              markers: _icon == null
                  ? const {}
                  : {Marker(markerId: const MarkerId('branch'), position: target, icon: _icon!, anchor: const Offset(0.5, 1))},
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onTap: (_) => MapsService.openDirections(widget.lat, widget.lng),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Iconsax.location, size: 18.sp, color: AppColors.primary),
                ),
                10.width,
                Expanded(
                  child: Text(widget.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.bodyMedium),
                ),
                8.width,
                AppButton(
                  title: 'wash.nav'.tr,
                  icon: Iconsax.routing,
                  small: true,
                  expanded: false,
                  onTap: () => MapsService.openDirections(widget.lat, widget.lng),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
