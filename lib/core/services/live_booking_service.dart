import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../commons/models/order_model.dart';
import '../enums/enums.dart';
import '../helpers/format_helper.dart';
import 'carzone_db_service.dart';
import 'notification_service.dart';
import 'session_service.dart';

/// Mirrors the customer's current booking outside the app, like ride-hailing
/// apps do: an iOS Live Activity (lock screen + Dynamic Island) and an Android
/// ongoing "live update" notification. Native code only renders what it is
/// given here, so all wording and localisation stays in Dart.
///
/// While the app is closed the server keeps the widget moving: each device
/// showing a booking is registered in live_booking_devices, and send-push
/// sends it every status change (see supabase/functions/send-push/live.ts,
/// which repeats this payload and its wording).
class LiveBookingService extends GetxService with WidgetsBindingObserver {
  static const _channel = MethodChannel('carzone/live_booking');

  /// Stages shown as the progress track: booked → confirmed → arrived → washing → ready.
  static const _stages = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.waiting,
    OrderStatus.inService,
    OrderStatus.completed,
  ];

  /// Status notifications from the orders trigger, by `customer_notifications.type`.
  static const _statusByType = {
    'created': OrderStatus.pending,
    'confirmed': OrderStatus.confirmed,
    'waiting': OrderStatus.waiting,
    'in_service': OrderStatus.inService,
    'completed': OrderStatus.completed,
    'cancelled': OrderStatus.cancelled,
    'no_show': OrderStatus.noShow,
  };

  /// A final state stays visible this long before the system removes it.
  static const _finalLinger = Duration(minutes: 15);

  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get _session => Get.find<SessionService>();

  String? _trackedId;
  String? _lastSent;
  final _seenNotifications = <String>{};

  /// iOS: ActivityKit push token per order id, from the native side.
  final _activityTokens = <String, String>{};

  /// Order id → the device registration last sent to the server for it.
  final _followed = <String, ({String fcmToken, String? activityToken, String locale})>{};

  LiveBookingService init() {
    _channel.setMethodCallHandler(_onNativeCall);
    _loadActivityTokens();
    _seenNotifications.addAll(_db.notifications.map((n) => n.id));
    ever(_db.orders, (_) => _reconcile());
    ever(_db.notifications, (_) => _applyStatusNotifications());
    ever(_session.user, (_) => _reconcile());
    _reconcile();
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  /// Live order updates do not replay what happened while the app was
  /// suspended, so coming back to the foreground reloads the active bookings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final uid = _session.userId;
    if (uid == null) return;
    for (final o in _db.orders.where((o) => o.customerId == uid && o.status.isUpcoming).toList()) {
      _db.refreshOrder(o.id);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// A new status notification means the wash changed the order on the server:
  /// apply it to the local copy so the booking screens and the widget move on.
  void _applyStatusNotifications() {
    var changed = false;
    for (final n in _db.notifications) {
      if (!_seenNotifications.add(n.id)) continue;
      final status = _statusByType[n.type];
      final order = n.orderId == null ? null : _db.order(n.orderId!);
      if (status == null || order == null || order.status == status) continue;
      order
        ..status = status
        ..timeline.add(TimelineEntry(status.key, n.createdAt.toLocal()));
      changed = true;
    }
    if (changed) _db.orders.refresh();
  }

  void _reconcile() {
    final uid = _session.userId;
    final tracked = _trackedId == null ? null : _db.order(_trackedId!);

    // The tracked booking just finished: show its final state, then let it go.
    if (tracked != null && !tracked.status.isUpcoming) {
      _send('show', _payload(tracked, isFinal: true));
      // The server stops following a finished order by itself.
      _followed.remove(tracked.id);
      _trackedId = null;
      return;
    }

    final next = uid == null ? null : _pickActive(uid);
    if (next == null) {
      if (_trackedId != null) _end(_trackedId!);
      return;
    }
    if (_trackedId != null && _trackedId != next.id) _end(_trackedId!);
    _trackedId = next.id;
    _send('show', _payload(next));
    _follow(next.id);
  }

  /// The booking a customer is waiting on: one in progress first, then the
  /// next appointment within the coming day. Stale ones are ignored.
  OrderModel? _pickActive(String uid) {
    final now = DateTime.now();
    final candidates = _db.orders
        .where((o) =>
            o.customerId == uid &&
            o.status.isUpcoming &&
            o.scheduledAt.isAfter(now.subtract(const Duration(hours: 12))) &&
            o.scheduledAt.isBefore(now.add(const Duration(hours: 24))))
        .toList()
      ..sort((a, b) {
        final byStage = _stages.indexOf(b.status).compareTo(_stages.indexOf(a.status));
        return byStage != 0 ? byStage : a.scheduledAt.compareTo(b.scheduledAt);
      });
    return candidates.firstOrNull;
  }

  Map<String, dynamic> _payload(OrderModel o, {bool isFinal = false}) {
    final branch = _db.branch(o.branchId);
    final stage = _stages.indexOf(o.status);
    final ready = _readyAt(o);
    final title = 'live.title.${o.status.key}'.tr;
    final subtitle = switch (o.status) {
      OrderStatus.pending || OrderStatus.confirmed =>
        'live.sub.appointment'.trParams({'time': FormatHelper.time(o.scheduledAt)}),
      OrderStatus.inService when ready != null =>
        'live.sub.readyAt'.trParams({'time': FormatHelper.time(ready)}),
      _ => 'live.sub.${o.status.key}'.tr,
    };
    return {
      'orderId': o.id,
      'number': o.number,
      'code': o.code,
      'branchName': branch?.name.value ?? 'app.name'.tr,
      'serviceName': o.primary.name.value,
      'status': o.status.key,
      'stage': stage,
      'title': title,
      'shortStatus': 'live.short.${o.status.key}'.tr,
      'subtitle': subtitle,
      'codeLabel': 'live.code'.tr,
      'stageLabels': [for (final s in _stages) 'live.stage.${s.key}'.tr],
      'scheduledAt': o.scheduledAt.millisecondsSinceEpoch,
      'serviceStartedAt': _startedAt(o)?.millisecondsSinceEpoch,
      'readyAt': ready?.millisecondsSinceEpoch,
      'isArabic': FormatHelper.isAr,
      'isFinal': isFinal,
      'dismissAfterSeconds': isFinal ? _finalLinger.inSeconds : null,
    };
  }

  DateTime? _startedAt(OrderModel o) =>
      o.status == OrderStatus.inService
          ? (o.timeline.where((t) => t.key == 'in_service').lastOrNull?.at ?? DateTime.now())
          : null;

  DateTime? _readyAt(OrderModel o) => _startedAt(o)?.add(Duration(minutes: o.durationMin));

  void _end(String orderId) {
    _lastSent = null;
    _invoke('end', {'orderId': orderId});
    _unfollow(orderId);
  }

  /// iOS hands over each Live Activity's push token as soon as ActivityKit has it.
  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method != 'pushToken') return;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    final orderId = args['orderId'] as String?;
    final token = args['token'] as String?;
    if (orderId == null || token == null) return;
    _activityTokens[orderId] = token;
    if (orderId == _trackedId) _follow(orderId);
  }

  /// Tokens of activities started before this launch, which keep receiving pushes.
  Future<void> _loadActivityTokens() async {
    if (!GetPlatform.isIOS) return;
    try {
      _activityTokens.addAll(await _channel.invokeMapMethod<String, String>('pushTokens') ?? {});
      if (_trackedId != null) _follow(_trackedId!);
    } catch (e) {
      dev.log('[LiveBookingService] pushTokens failed: $e');
    }
  }

  /// Registers this device for server pushes of [orderId]'s status.
  Future<void> _follow(String orderId) async {
    if (!(GetPlatform.isIOS || GetPlatform.isAndroid) || !Get.isRegistered<NotificationService>()) return;
    final activityToken = _activityTokens[orderId];
    // iOS needs the activity's own token; _onNativeCall comes back with it.
    if (GetPlatform.isIOS && activityToken == null) return;
    final fcmToken = await NotificationService.to.deviceToken();
    if (fcmToken == null || orderId != _trackedId) return;
    final device = (fcmToken: fcmToken, activityToken: activityToken, locale: FormatHelper.isAr ? 'ar' : 'en');
    if (_followed[orderId] == device) return;
    _followed[orderId] = device;
    final saved = await _db.followLiveBooking(
      orderId: orderId,
      fcmToken: device.fcmToken,
      activityToken: device.activityToken,
      locale: device.locale,
    );
    if (!saved) _followed.remove(orderId);
  }

  void _unfollow(String orderId) {
    final device = _followed.remove(orderId);
    if (device != null) _db.unfollowLiveBooking(orderId, device.fcmToken);
  }

  void _send(String method, Map<String, dynamic> payload) {
    // Order lists refresh often; only real changes reach the platform.
    final key = jsonEncode(payload);
    if (key == _lastSent) return;
    _lastSent = key;
    _invoke(method, payload);
  }

  Future<void> _invoke(String method, Map<String, dynamic> args) async {
    try {
      await _channel.invokeMethod(method, args);
    } on MissingPluginException {
      // Platform without a live widget (web, desktop, tests).
    } catch (e) {
      dev.log('[LiveBookingService] $method failed: $e');
    }
  }
}
