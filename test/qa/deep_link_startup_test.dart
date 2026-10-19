// A link that opens the app from cold start arrives while the splash is on
// screen. The splash then calls Get.offAllNamed(main), which used to wipe the
// wash page the link had opened. The link must survive until the app is ready.
import 'package:carzone/core/routing/app_routes.dart';
import 'package:carzone/core/services/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Widget _page(String name) => Scaffold(body: Text(name));

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(GetMaterialApp(
    initialRoute: Routes.splashRoute,
    getPages: [
      GetPage(name: Routes.splashRoute, page: () => _page('splash')),
      GetPage(name: Routes.mainRoute, page: () => _page('main')),
      GetPage(name: Routes.washDetailsRoute, page: () => _page('wash')),
    ],
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('cold-start link waits for the splash, then opens the wash page', (tester) async {
    await _pumpApp(tester);
    final links = DeepLinkService();

    expect(links.handleUri(Uri.parse('carzone://wash?id=br_nasr')), isTrue);
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.splashRoute, reason: 'must not navigate before the app is ready');
    expect(links.pendingBranchId, 'br_nasr');

    // What SplashController._openNext does.
    Get.offAllNamed(Routes.mainRoute);
    links.markAppReady();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.washDetailsRoute);
    expect(Get.arguments, 'br_nasr');
    expect(links.pendingBranchId, isNull);
  });

  testWidgets('links after start-up open the wash page straight away', (tester) async {
    await _pumpApp(tester);
    final links = DeepLinkService();
    Get.offAllNamed(Routes.mainRoute);
    links.markAppReady();
    await tester.pumpAndSettle();

    links.handleUri(Uri.parse('carzone://wash/br_helio'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.washDetailsRoute);
    expect(Get.arguments, 'br_helio');
  });

  testWidgets('auth callback links are left to Supabase', (tester) async {
    await _pumpApp(tester);
    final links = DeepLinkService()..markAppReady();
    expect(links.handleUri(Uri.parse('carzone://login-callback?code=abc')), isFalse);
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.splashRoute);
    expect(links.pendingBranchId, isNull);
  });
}
