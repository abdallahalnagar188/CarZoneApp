import 'dart:convert';
import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../commons/models/localized_text.dart';
import '../../commons/models/notification_model.dart';
import '../routing/app_routes.dart';
import 'carzone_db_service.dart';
import 'session_service.dart';

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
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocalNotifications();
      await requestPermissions();
      await _setupFcmListeners();
      await syncToken();
    } catch (e) {
      dev.log('[NotificationService] init error: $e');
    }
    return this;
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifs.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            _handleNotificationClick(data);
          } catch (_) {
            _handleSimplePayloadClick(payload);
          }
        }
      },
    );

    final androidImplementation = _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
    }
  }

  Future<void> requestPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

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

  Future<void> syncToken() async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        dev.log('[NotificationService] FCM Token: $token');
        await _saveTokenToDb(token);
      }
    } catch (e) {
      dev.log('[NotificationService] syncToken error: $e');
    }
  }

  Future<void> _saveTokenToDb(String token) async {
    if (!Get.isRegistered<CarzoneDbService>()) return;
    final db = Get.find<CarzoneDbService>();
    final session = Get.isRegistered<SessionService>() ? Get.find<SessionService>() : null;
    final userId = session?.userId;
    if (userId != null && userId.isNotEmpty) {
      await db.updateCustomerToken(userId, token);
    }
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
      id: notifId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
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
