// lib/services/push_notification_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/fire_alarm_state.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService().init();
  await PushNotificationService.showFromRemoteMessage(message);
}

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<void> init({VoidCallback? onNotificationTap}) async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('[FCM] permission: ${settings.authorizationStatus}');
    }

    await _registerToken(await _messaging.getToken());

    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen(_registerToken);

    await _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen(showFromRemoteMessage);

    await _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      onNotificationTap?.call();
    });

    final initialMsg = await _messaging.getInitialMessage();
    if (initialMsg != null) {
      scheduleMicrotask(() => onNotificationTap?.call());
    }
  }

  Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) return;

    // TODO: Send this token to your backend when the push API is ready.
    // Suggested endpoint: POST /v1/push/register.
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FCM] token: $token');
    }
  }

  static Future<void> showFromRemoteMessage(RemoteMessage msg) async {
    final localNotifications = NotificationService();
    final data = msg.data;

    final flags = _AlarmFlagsAdapter.fromMessageData(data);
    if (flags.any) {
      await localNotifications.showAlarmNotification(flags);
      return;
    }

    final title = _stringOrNull(data['title']) ?? msg.notification?.title;
    final body = _stringOrNull(data['body']) ?? msg.notification?.body;

    if (title != null || body != null) {
      await localNotifications.showGenericCritical(
        title: title ?? 'Hazard Alert',
        body: body ?? 'A hazard event was received.',
      );
    }
  }

  static String? _stringOrNull(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();
  }
}

class _AlarmFlagsAdapter {
  static AlarmFlags fromMessageData(Map<String, dynamic> data) {
    final alarms = data['alarms'];
    if (alarms is Map) return fromDynamicMap(alarms);

    if (alarms is String && alarms.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(alarms);
        if (decoded is Map) return fromDynamicMap(decoded);
      } catch (_) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[FCM] invalid alarms payload: $alarms');
        }
      }
    }

    return fromDynamicMap(data);
  }

  static AlarmFlags fromDynamicMap(Map alarms) {
    bool b(String k) {
      final value = alarms[k];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
      return false;
    }

    return AlarmFlags(
      flame: b('flame'),
      smoke: b('smoke'),
      temp: b('temp') || b('temperature'),
      vibration: b('vibration') || b('earthquake'),
    );
  }
}
