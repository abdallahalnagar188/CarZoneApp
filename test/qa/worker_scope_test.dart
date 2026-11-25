// GAP-098: a closed page controller stops reacting to shared observables.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup/core/helpers/worker_scope.dart';

class _Page extends GetxController with DisposesWorkers {
  final RxInt shared;
  var calls = 0;

  _Page(this.shared);

  @override
  void onInit() {
    super.onInit();
    keep(ever(shared, (_) => calls++));
    keep(null); // e.g. ConnectivityService.maybe?.onReconnect(...) without the service
  }
}

void main() {
  test('workers kept by a controller are disposed when it closes', () async {
    final shared = 0.obs;
    final page = Get.put(_Page(shared));
    shared.value = 1;
    await Future<void>.delayed(Duration.zero);
    expect(page.calls, 1);

    await Get.delete<_Page>();
    shared.value = 2;
    await Future<void>.delayed(Duration.zero);
    expect(page.calls, 1, reason: 'a closed controller must not react any more');
  });
}
