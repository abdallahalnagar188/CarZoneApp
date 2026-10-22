import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constance/supabase_constants.dart';

/// Whether the app can reach the backend right now.
///
/// The OS reports when the device loses its network interface; a connected
/// Wi-Fi without internet only shows up when a request fails, so failures
/// reported by [ApiCall] trigger a probe of the Supabase host, repeated with a
/// growing delay until it answers.
class ConnectivityService extends GetxService with WidgetsBindingObserver {
  static ConnectivityService? get maybe =>
      Get.isRegistered<ConnectivityService>() ? Get.find<ConnectivityService>() : null;

  /// True when the backend is reachable (or not known to be unreachable).
  static bool get online => maybe?.isOnline.value ?? true;

  final isOnline = true.obs;

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  int _retryStep = 0;
  bool _hasNetwork = true;
  Future<bool>? _probing;

  static const _retryDelays = [3, 5, 10, 20, 30];

  /// The device has some network interface (Wi-Fi, cellular, ...).
  bool get hasNetwork => _hasNetwork;

  ConnectivityService init() {
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.onConnectivityChanged.listen(_onInterfaces);
    _refreshInterfaces();
    return this;
  }

  /// Runs [action] every time the connection comes back.
  Worker onReconnect(VoidCallback action) => ever<bool>(isOnline, (on) {
        if (on) action();
      });

  /// A request failed on the way: find out whether we are still online.
  void reportFailure() {
    if (isOnline.value) check();
  }

  /// A request got an answer from the server.
  void reportSuccess() => _setOnline(true);

  /// Probes the backend; any HTTP answer counts as reachable.
  Future<bool> check() => _probing ??= _probe().whenComplete(() => _probing = null);

  Future<void> _refreshInterfaces() async {
    try {
      _onInterfaces(await _connectivity.checkConnectivity());
    } catch (e) {
      dev.log('[ConnectivityService] checkConnectivity error: $e');
    }
  }

  void _onInterfaces(List<ConnectivityResult> results) {
    _hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (_hasNetwork) {
      check();
    } else {
      _setOnline(false);
    }
  }

  Future<bool> _probe() async {
    if (!_hasNetwork) {
      _setOnline(false);
      return false;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .headUrl(Uri.parse('${SupabaseConstants.supabaseUrl}/auth/v1/health'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain<void>();
      _setOnline(true);
      return true;
    } catch (e) {
      dev.log('[ConnectivityService] backend unreachable: $e');
      _setOnline(false);
      return false;
    } finally {
      client.close(force: true);
    }
  }

  void _setOnline(bool value) {
    if (value) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _retryStep = 0;
    } else {
      _scheduleRetry();
    }
    if (isOnline.value != value) {
      dev.log('[ConnectivityService] ${value ? 'online' : 'offline'}');
      isOnline.value = value;
    }
  }

  /// While offline with a network interface, probe again with a growing delay.
  /// Without one, the OS tells us when it is back.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (!_hasNetwork) return;
    final seconds = _retryDelays[_retryStep.clamp(0, _retryDelays.length - 1)];
    _retryStep++;
    _retryTimer = Timer(Duration(seconds: seconds), check);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshInterfaces();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }
}
