import 'dart:io';

import 'package:carzone/app.dart';
import 'package:carzone/core/local/cache_controller.dart';
import 'package:carzone/core/local/cache_helper.dart';
import 'package:carzone/core/local/theme_controller.dart';
import 'package:carzone/core/services/supabase_service.dart';
import 'package:carzone/features/splash/presentaion/widgets/splash_brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  testWidgets('App boots on the splash screen', (WidgetTester tester) async {
    HttpOverrides.global = _RealHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await CacheController().initSharedPreferences();
    await CacheHelper.init();
    await SupabaseService.init();
    SupabaseService.client.auth.stopAutoRefresh();
    Get.put(ThemeController(), permanent: true);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(MyApp), findsOneWidget);
    // The splash is the Wash Up mark (no text since the rebrand).
    expect(find.byType(SplashBrand), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    // Network calls never answer under fake time: let their timeouts and
    // retries (ApiCall: 15 s each, 2 retries) run out before tearing down.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 10));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    SupabaseService.client.auth.stopAutoRefresh();
    Supabase.instance.dispose();
    Get.reset();
  });
}
