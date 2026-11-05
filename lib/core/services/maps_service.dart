import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../commons/widgets/sheets/app_bottom_sheet.dart';
import '../../commons/widgets/sheets/directions_sheet.dart';
import '../enums/enums.dart';
import '../utils/utils.dart';

class MapsService {
  MapsService._();

  static String? _light;
  static String? _dark;

  static Future<String> style({required bool dark}) async {
    if (dark) return _dark ??= await rootBundle.loadString('assets/map/map_style_dark.json');
    return _light ??= await rootBundle.loadString('assets/map/map_style_light.json');
  }

  /// Driving directions to the wash. On iOS the customer picks Apple Maps
  /// (first, App Review guideline 4) or Google Maps; Android opens Google Maps.
  static Future<void> openDirections(double lat, double lng) async {
    final app = GetPlatform.isIOS
        ? await AppBottomSheet.show<MapsApp>(title: 'maps.choose'.tr, child: const DirectionsSheet())
        : MapsApp.google;
    if (app == null) return;
    final uri = app == MapsApp.apple
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) Utils.getSnakBar(message: 'toast.maps'.tr, type: TosterTypes.warning);
  }

  static Future<void> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    final ok = await launchUrl(uri);
    if (!ok) Utils.getSnakBar(message: 'toast.call'.tr, type: TosterTypes.warning);
  }
}
