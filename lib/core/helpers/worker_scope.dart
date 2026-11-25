import 'package:get/get.dart';

/// GAP-098: GetX `ever`/`everAll`/`debounce` workers live as long as the
/// observable they listen to (often a permanent service), not as long as the
/// page controller that made them. A closed controller kept reacting: extra
/// requests, stray toasts. Pass each worker to [keep]; they are disposed when
/// the controller closes.
mixin DisposesWorkers on GetxController {
  final _workers = <Worker>[];

  /// Disposes [worker] together with this controller.
  void keep(Worker? worker) {
    if (worker != null) _workers.add(worker);
  }

  @override
  void onClose() {
    for (final w in _workers) {
      w.dispose();
    }
    _workers.clear();
    super.onClose();
  }
}
