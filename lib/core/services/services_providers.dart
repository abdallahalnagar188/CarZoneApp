import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'carzone_db_service.dart';
import 'connectivity_service.dart';
import 'deep_link_service.dart';
import 'live_booking_service.dart';
import 'notification_service.dart';
import 'session_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  if (Get.isRegistered<ConnectivityService>()) {
    return Get.find<ConnectivityService>();
  }
  final service = ConnectivityService().init();
  Get.put(service, permanent: true);
  return service;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  if (Get.isRegistered<NotificationService>()) {
    return Get.find<NotificationService>();
  }
  final service = NotificationService();
  Get.put(service, permanent: true);
  return service;
});

final carzoneDbServiceProvider = Provider<CarzoneDbService>((ref) {
  if (Get.isRegistered<CarzoneDbService>()) {
    return Get.find<CarzoneDbService>();
  }
  final service = CarzoneDbService().init();
  Get.put(service, permanent: true);
  return service;
});

final sessionServiceProvider = Provider<SessionService>((ref) {
  if (Get.isRegistered<SessionService>()) {
    return Get.find<SessionService>();
  }
  final service = SessionService().init();
  Get.put(service, permanent: true);
  return service;
});

final liveBookingServiceProvider = Provider<LiveBookingService>((ref) {
  if (Get.isRegistered<LiveBookingService>()) {
    return Get.find<LiveBookingService>();
  }
  final service = LiveBookingService().init();
  Get.put(service, permanent: true);
  return service;
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  if (Get.isRegistered<DeepLinkService>()) {
    return Get.find<DeepLinkService>();
  }
  final service = DeepLinkService();
  service.init();
  Get.put(service, permanent: true);
  return service;
});
