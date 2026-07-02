// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/fire_alarm_state.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'hazard_alarm_critical';
  static const _channelName = 'Hazard Alarm Alerts';
  static const _channelDesc = 'Critical hazard alarm notifications';

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    // Create high-priority Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showAlarmNotification(AlarmFlags alarms) async {
    final triggers = <String>[];
    if (alarms.flame) triggers.add('🔥 FLAME detected');
    if (alarms.vibration) triggers.add('📳 EARTHQUAKE / VIBRATION detected');
    if (alarms.smoke) triggers.add('💨 SMOKE detected');
    if (alarms.temp) triggers.add('🌡️ TEMPERATURE spike');

    final body = triggers.join('\n');

    // Title adapts to highest-priority alarm
    final title = alarms.flame
        ? '🚨 FIRE ALARM TRIGGERED'
        : alarms.vibration
            ? '📳 EARTHQUAKE DETECTED'
            : alarms.smoke
                ? '💨 SMOKE ALARM TRIGGERED'
                : '🌡️ TEMPERATURE ALARM';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      autoCancel: false,
      ongoing: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.show(
      1,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      ),
    );
  }

  Future<void> cancelAlarmNotification() async {
    await _plugin.cancel(1);
  }

  Future<void> showGenericCritical({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      2,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iOSDetails),
    );
  }
}
