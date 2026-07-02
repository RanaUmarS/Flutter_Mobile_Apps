// lib/providers/providers.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fire_alarm_state.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/websocket_service.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

@immutable
class AppSettings {
  final String wsUri;

  const AppSettings({this.wsUri = 'ws://192.168.4.1:81'});

  AppSettings copyWith({String? wsUri}) {
    return AppSettings(wsUri: wsUri ?? this.wsUri);
  }

  Map<String, dynamic> toJson() => {'wsUri': wsUri};

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      wsUri: json['wsUri'] as String? ?? 'ws://192.168.4.1:81',
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _key = 'app_settings';

  @override
  Future<AppSettings> build() async {
    final prefs = await ref.watch(sharedPrefsProvider.future);
    final raw = prefs.getString(_key);
    if (raw == null) return const AppSettings();

    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> updateUri(String uri) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    final updated = AppSettings(wsUri: uri);
    await prefs.setString(_key, jsonEncode(updated.toJson()));
    state = AsyncValue.data(updated);

    final ws = ref.read(wsServiceProvider);
    await ws.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    ws.connect();
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final wsServiceProvider = Provider<WebSocketService>((ref) {
  const defaultUri = 'ws://192.168.4.1:81';
  final service = WebSocketService(uri: defaultUri);
  service.connect();
  ref.onDispose(service.dispose);
  return service;
});

final connectionStateProvider = StreamProvider<WsConnectionState>((ref) {
  return ref.watch(wsServiceProvider).connectionStream;
});

final sensorStateProvider = StreamProvider<FireAlarmState>((ref) {
  return ref.watch(wsServiceProvider).sensorStream;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final alarmServiceProvider =
NotifierProvider<AlarmService, AlarmServiceState>(AlarmService.new);

final historyProvider = Provider<List<AlarmEvent>>((ref) {
  return ref.watch(alarmServiceProvider).history;
});

class SensorHistoryNotifier extends Notifier<List<FireAlarmState>> {
  static const _maxPoints = 30;

  @override
  List<FireAlarmState> build() {
    ref.listen<AsyncValue<FireAlarmState>>(sensorStateProvider, (_, next) {
      next.whenData((sensorState) {
        final updated = [...state, sensorState];
        state = updated.length > _maxPoints
            ? updated.sublist(updated.length - _maxPoints)
            : updated;
      });
    });
    return [];
  }
}

final sensorHistoryProvider =
NotifierProvider<SensorHistoryNotifier, List<FireAlarmState>>(
  SensorHistoryNotifier.new,
);

// ── Theme mode ────────────────────────────────────────────────────────────────
// Persisted to SharedPreferences. Screens read this to build the toggle.

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    // Restore from prefs asynchronously after first frame
    _restore();
    return ThemeMode.dark; // safe default before prefs loads
  }

  Future<void> _restore() async {
    try {
      final prefs = await ref.read(sharedPrefsProvider.future);
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final mode = ThemeMode.values.firstWhere(
            (m) => m.name == raw,
        orElse: () => ThemeMode.dark,
      );
      state = mode;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await ref.read(sharedPrefsProvider.future);
      await prefs.setString(_key, state.name);
    } catch (_) {}
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);