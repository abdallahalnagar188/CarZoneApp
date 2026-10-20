import 'package:flutter/widgets.dart';

/// Holds navigation that is requested while the app is still starting
/// (e.g. tapping a notification that launched the app). The splash and
/// onboarding screens finish with Get.offAllNamed(main), which would wipe a
/// page pushed earlier, so such actions wait until [markReady] is called.
class AppReadyGate {
  AppReadyGate._();

  static bool _ready = false;
  static final List<VoidCallback> _pending = [];

  static bool get isReady => _ready;

  /// Runs [action] now if the main screen is up, otherwise once it is.
  static void run(VoidCallback action) {
    if (_ready) {
      action();
    } else {
      _pending.add(action);
    }
  }

  /// Called once the main screen is on top (after splash or onboarding).
  static void markReady() {
    if (_ready) return;
    _ready = true;
    if (_pending.isEmpty) return;
    final actions = List<VoidCallback>.of(_pending);
    _pending.clear();
    // Let the main route finish pushing before stacking pages on it.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        for (final action in actions) {
          action();
        }
      })
      // A post-frame callback does not request a frame by itself.
      ..ensureVisualUpdate();
  }

  @visibleForTesting
  static void reset() {
    _ready = false;
    _pending.clear();
  }
}
