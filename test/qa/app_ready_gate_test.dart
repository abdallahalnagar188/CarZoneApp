// A notification tap that launches the app arrives during the splash; the
// splash then calls Get.offAllNamed(main). The tap must open its page after that.
import 'package:carzone/core/services/app_ready_gate.dart';
import 'package:carzone/core/services/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AppReadyGate.reset);

  testWidgets('actions wait until the app is ready, then run once', (tester) async {
    final ran = <String>[];
    AppReadyGate.run(() => ran.add('tap'));
    await tester.pump();
    expect(ran, isEmpty);

    AppReadyGate.markReady();
    await tester.pump();
    expect(ran, ['tap']);

    AppReadyGate.markReady();
    await tester.pump();
    expect(ran, ['tap'], reason: 'pending actions run only once');
  });

  testWidgets('after start-up actions run immediately', (tester) async {
    AppReadyGate.markReady();
    var ran = false;
    AppReadyGate.run(() => ran = true);
    expect(ran, isTrue);
  });

  testWidgets('splash/onboarding ready signal (DeepLinkService) opens the gate', (tester) async {
    var ran = false;
    AppReadyGate.run(() => ran = true);
    DeepLinkService().markAppReady();
    await tester.pump();
    expect(ran, isTrue);
  });
}
