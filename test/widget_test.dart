import 'package:carzone/app.dart';
import 'package:carzone/core/local/cache_controller.dart';
import 'package:carzone/core/local/cache_helper.dart';
import 'package:carzone/core/local/theme_controller.dart';
import 'package:carzone/features/splash/presentaion/controllers/splash_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots on the splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await CacheController().initSharedPreferences();
    await CacheHelper.init();
    Get.put(ThemeController(), permanent: true);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.text('كارزن'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    Get.delete<SplashController>(force: true);
    Get.reset();
  });
}
