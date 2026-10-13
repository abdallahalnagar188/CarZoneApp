import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/local/cache_controller.dart';
import 'core/local/cache_helper.dart';
import 'core/local/theme_controller.dart';
import 'core/network/dio_helper.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CacheController().initSharedPreferences();
  await CacheHelper.init();
  await SupabaseService.init();
  await DioHelper.init();
  await initializeDateFormatting();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final themeController = Get.put(ThemeController(), permanent: true);
  final dark = themeController.isDarkMode.value;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    ),
  );

  runApp(const MyApp());
}
