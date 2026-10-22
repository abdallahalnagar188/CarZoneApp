import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/local/cache_controller.dart';
import 'core/local/cache_helper.dart';
import 'core/local/theme_controller.dart';
import 'core/network/dio_helper.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/utils/system_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CacheController().initSharedPreferences();
  await CacheHelper.init();
  await SupabaseService.init();
  // Before any service fetches, so requests and the offline banner can use it.
  Get.put(ConnectivityService().init(), permanent: true);
  final notificationService = NotificationService();
  await notificationService.init();
  Get.put(notificationService, permanent: true);
  await DioHelper.init();
  await initializeDateFormatting();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  Get.put(ThemeController(), permanent: true);
  SystemUi.apply();

  runApp(const MyApp());
}
