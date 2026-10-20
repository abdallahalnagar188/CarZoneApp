import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../commons/models/localized_text.dart';
import '../../commons/models/notification_model.dart';
import '../routing/app_routes.dart';
import 'app_ready_gate.dart';
import 'carzone_db_service.dart';
import 'session_service.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    dev.log('[NotificationService] Background message received: ${message.messageId}');
  } catch (e) {
    dev.log('[NotificationService] Background handler error: $e');
  }
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();

  static const String channelId = 'carzone_orders';
  static const String channelName = 'CarZone Notifications';
  static const String channelDesc = 'Order status updates, reminders and offers';

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<NotificationService> init() async {
    // Local notifications do not depend on Firebase, so a Firebase failure
    // must not take them down with it.
    try {
      await _initLocalNotifications();
      await _handleLaunchFromLocalNotification();
    } catch (e) {
      dev.log('[NotificationService] local notifications init error: $e');
    }
    // init() runs before runApp: awaiting the permission dialog here leaves a
    // blank screen until the user answers, so ask once the first frame is up.
    WidgetsBinding.instance.addPostFrameCallback((_) => requestPermissions());
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _setupFcmListeners();
      _syncTokenOnSignIn();
    } catch (e) {
      dev.log('[NotificationService] init error: $e');
    }
    return this;
  }

  /// The FCM token is stored per signed-in user (push_devices), so it is sent
  /// whenever a session exists: on start-up with a saved session and after login.
  /// Not awaited: on iOS the token waits for APNs and must not delay app start.
  void _syncTokenOnSignIn() {
    // New listeners only get the latest auth event (often tokenRefreshed at
    // start-up, not initialSession), so react to "a user without a synced token".
    void syncIfNeeded(String? uid) {
      if (uid != null && uid != _tokenSyncedFor) unawaited(syncToken());
    }

    // The token is saved through CarzoneDbService, which AppBinding registers
    // with the first frame; init() runs before that.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => syncIfNeeded(SupabaseService.client.auth.currentUser?.id),
    );
    SupabaseService.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        _tokenSyncedFor = null;
      } else {
        syncIfNeeded(state.session?.user.id);
      }
    });
  }

  void _onLocalNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleNotificationClick(data);
    } catch (_) {
      _handleSimplePayloadClick(payload);
    }
  }

  /// A local notification tapped while the app was closed launches it without
  /// calling onDidReceiveNotificationResponse.
  Future<void> _handleLaunchFromLocalNotification() async {
    final launch = await _localNotifs.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _onLocalNotificationPayload(launch!.notificationResponse?.payload);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permission is requested later by requestPermissions(), not on initialize.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifs.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) => _onLocalNotificationPayload(response.payload),
    );

    final androidImplementation = _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
    }
  }

  /// One system permission covers local and push notifications. Asked through
  /// the local notifications plugin so it works even if Firebase is unavailable.
  Future<void> requestPermissions() async {
    try {
      await _localNotifs
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final androidPlugin = _localNotifs
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      dev.log('[NotificationService] requestPermissions error: $e');
    }
  }

  Future<void> _setupFcmListeners() async {
    // 1. Foreground FCM message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dev.log('[NotificationService] Foreground message received: ${message.data}');
      _showRemoteNotification(message);
      _persistRemoteNotification(message);
    });

    // 2. Notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      dev.log('[NotificationService] Notification opened from background: ${message.data}');
      _handleNotificationClick(message.data);
    });

    // 3. Notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        dev.log('[NotificationService] Initial message opened app: ${message.data}');
        _handleNotificationClick(message.data);
      }
    });

    // 4. Token refresh listener
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      dev.log('[NotificationService] FCM token refreshed: $newToken');
      _saveTokenToDb(newToken);
    });
  }

  bool _syncingToken = false;
  String? _tokenSyncedFor;

  Future<void> syncToken() async {
    if (_syncingToken || SupabaseService.client.auth.currentUser == null) return;
    _syncingToken = true;
    try {
      // iOS: getToken() throws until APNs has handed the app its device token.
      if (GetPlatform.isIOS && !await _waitForApnsToken()) {
        dev.log('[NotificationService] No APNs token; push is unavailable on this device/build.');
        return;
      }
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        dev.log('[NotificationService] FCM Token: $token');
        if (await _saveTokenToDb(token)) {
          _tokenSyncedFor = SupabaseService.client.auth.currentUser?.id;
        }
      }
    } catch (e) {
      dev.log('[NotificationService] syncToken error: $e');
    } finally {
      _syncingToken = false;
    }
  }

  Future<bool> _waitForApnsToken() async {
    for (var i = 0; i < 10; i++) {
      if (await FirebaseMessaging.instance.getAPNSToken() != null) return true;
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  /// False when nothing could be saved yet (services not ready / signed out).
  Future<bool> _saveTokenToDb(String token) async {
    if (!Get.isRegistered<CarzoneDbService>()) return false;
    final db = Get.find<CarzoneDbService>();
    final session = Get.isRegistered<SessionService>() ? Get.find<SessionService>() : null;
    // push_devices is keyed by the auth user; the customer id only updates the local cache.
    final userId = session?.userId ?? SupabaseService.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return false;
    await db.updateCustomerToken(userId, token);
    return true;
  }

  void _showRemoteNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title_ar'] ?? data['title_en'] ?? data['title'] ?? 'CarZone';
    final body = notification?.body ?? data['body_ar'] ?? data['body_en'] ?? data['body'] ?? '';

    showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  }

  void _persistRemoteNotification(RemoteMessage message) {
    if (!Get.isRegistered<CarzoneDbService>()) return;
    final db = Get.find<CarzoneDbService>();
    final session = Get.isRegistered<SessionService>() ? Get.find<SessionService>() : null;
    final userId = session?.userId;
    if (userId == null) return;

    final data = message.data;
    final notifId = data['id']?.toString() ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';

    // Avoid duplicates if already exists
    if (db.notifications.any((n) => n.id == notifId)) return;

    final titleAr = data['title_ar']?.toString() ?? message.notification?.title ?? 'إشعار جديد';
    final titleEn = data['title_en']?.toString() ?? message.notification?.title ?? 'New Notification';
    final bodyAr = data['body_ar']?.toString() ?? message.notification?.body ?? '';
    final bodyEn = data['body_en']?.toString() ?? message.notification?.body ?? '';
    final type = data['type']?.toString() ?? 'system';
    final orderId = data['order_id']?.toString();

    final model = NotificationModel(
      id: notifId,
      userId: userId,
      type: type,
      title: LocalizedText(titleAr, titleEn),
      body: LocalizedText(bodyAr, bodyEn),
      orderId: orderId,
      createdAt: DateTime.now(),
      read: false,
    );

    db.notifications.insert(0, model);
  }

  Future<void> showLocalNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final notifId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifs.show(
      notifId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Taps can arrive while the splash is still up (the tap launched the app),
  /// so navigation waits for the main screen.
  void _handleNotificationClick(Map<String, dynamic> data) {
    AppReadyGate.run(() => _openForNotification(data));
  }

  void _openForNotification(Map<String, dynamic> data) {
    final orderId = data['order_id']?.toString() ?? data['orderId']?.toString();
    final type = data['type']?.toString();

    if (orderId != null && orderId.isNotEmpty) {
      if (type == 'review_reminder') {
        Get.toNamed(Routes.reviewRoute, arguments: orderId);
      } else {
        Get.toNamed(Routes.bookingDetailsRoute, arguments: orderId);
      }
    } else if (type == 'offer') {
      Get.toNamed(Routes.offersRoute);
    } else {
      Get.toNamed(Routes.notificationsRoute);
    }
  }

  void _handleSimplePayloadClick(String payload) {
    AppReadyGate.run(() => _openForSimplePayload(payload));
  }

  void _openForSimplePayload(String payload) {
    if (payload.startsWith('order:')) {
      final orderId = payload.replaceFirst('order:', '');
      Get.toNamed(Routes.bookingDetailsRoute, arguments: orderId);
    } else if (payload == 'offers') {
      Get.toNamed(Routes.offersRoute);
    } else {
      Get.toNamed(Routes.notificationsRoute);
    }
  }
}
