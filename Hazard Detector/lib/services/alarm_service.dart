import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fire_alarm_state.dart';
import 'notification_service.dart';

class AlarmServiceState {
  final List<AlarmEvent> history;
  final Set<AlarmSensorType> activeSensors;
  final bool acknowledged;
  final bool loaded; // true once _loadHistory() has completed

  const AlarmServiceState({
    this.history = const [],
    this.activeSensors = const {},
    this.acknowledged = false,
    this.loaded = false,
  });

  List<AlarmEvent> get unresolvedEvents =>
      history.where((e) => e.status != AlarmRecordStatus.resolved).toList();

  List<AlarmEvent> get activeEvents =>
      history.where((e) => e.status == AlarmRecordStatus.active).toList();

  bool get hasActiveAlarm => activeEvents.isNotEmpty;

  AlarmEvent? get primaryAlarm =>
      activeEvents.isEmpty ? null : activeEvents.first;

  AlarmServiceState copyWith({
    List<AlarmEvent>? history,
    Set<AlarmSensorType>? activeSensors,
    bool? acknowledged,
    bool? loaded,
  }) =>
      AlarmServiceState(
        history: history ?? this.history,
        activeSensors: activeSensors ?? this.activeSensors,
        acknowledged: acknowledged ?? this.acknowledged,
        loaded: loaded ?? this.loaded,
      );
}

class AlarmService extends Notifier<AlarmServiceState> {
  static const _historyKey = 'alarm_history_v2';
  static const _maxEntries = 200;

  Timer? _vibrationTimer;
  Future<void>? _loadTask;

  @override
  AlarmServiceState build() {
    _loadTask = _loadHistory();
    ref.onDispose(_stopVibration);
    return const AlarmServiceState(loaded: false);
  }

  Future<void> handleSensorState(FireAlarmState sensorState) async {
    // Always wait for history to finish loading before processing sensor data
    await _loadTask;

    final current = _sensorTypesFor(sensorState.alarms);
    final previous = state.activeSensors;
    final raised = current.difference(previous);
    final resolved = previous.difference(current);

    if (raised.isNotEmpty) {
      final newEvents = raised
          .map((sensor) => AlarmEvent.fromState(
        state: sensorState,
        sensorType: sensor,
        severity: _severityFor(sensor),
      ))
          .toList();

      state = state.copyWith(
        history: [...newEvents, ...state.history].take(_maxEntries).toList(),
        activeSensors: current,
        acknowledged: false,
      );
      await _persistHistory();
      await NotificationService().showAlarmNotification(sensorState.alarms);
      _startVibration(newEvents.any((e) => e.severity == AlarmSeverity.critical));
      return;
    }

    if (resolved.isNotEmpty) {
      final now = sensorState.receivedAt;
      state = state.copyWith(
        history: state.history
            .map((event) => resolved.contains(event.sensorType) &&
            event.status != AlarmRecordStatus.resolved
            ? event.copyWith(
          status: AlarmRecordStatus.resolved,
          resolvedAt: now,
        )
            : event)
            .toList(),
        activeSensors: current,
      );

      if (current.isEmpty) {
        await NotificationService().cancelAlarmNotification();
        _stopVibration();
      }
      await _persistHistory();
    } else if (current.isNotEmpty && current != previous) {
      state = state.copyWith(activeSensors: current);
    }
  }

  Future<void> acknowledgeActiveAlarm() async {
    await _loadTask;
    if (!state.hasActiveAlarm) return;

    state = state.copyWith(
      acknowledged: true,
      history: state.history
          .map((event) => event.status == AlarmRecordStatus.active
          ? event.copyWith(status: AlarmRecordStatus.acknowledged)
          : event)
          .toList(),
    );
    _stopVibration();
    await _persistHistory();
  }

  Future<void> clearHistory() async {
    await _loadTask;
    state = state.copyWith(
      history: [],
      activeSensors: {},
      acknowledged: false,
    );
    _stopVibration();
    await NotificationService().cancelAlarmNotification();
    final prefs = await ref.read(_alarmPrefsProvider.future);
    await prefs.remove(_historyKey);
  }

  Future<void> _loadHistory() async {
    final prefs = await ref.read(_alarmPrefsProvider.future);
    final raw = prefs.getStringList(_historyKey) ?? [];
    final events = raw
        .map((item) {
      try {
        return AlarmEvent.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    })
        .whereType<AlarmEvent>()
        .toList();

    final activeSensors = events
        .where((event) => event.status != AlarmRecordStatus.resolved)
        .map((event) => event.sensorType)
        .toSet();

    // Mark as loaded AFTER all state is set
    state = state.copyWith(
      history: events,
      activeSensors: activeSensors,
      acknowledged: events.any(
            (event) => event.status == AlarmRecordStatus.acknowledged,
      ),
      loaded: true, // <-- router now knows state is real
    );
  }

  Future<void> _persistHistory() async {
    final prefs = await ref.read(_alarmPrefsProvider.future);
    await prefs.setStringList(
      _historyKey,
      state.history.map((event) => jsonEncode(event.toJson())).toList(),
    );
  }

  Set<AlarmSensorType> _sensorTypesFor(AlarmFlags flags) => {
    if (flags.flame) AlarmSensorType.flame,
    if (flags.smoke) AlarmSensorType.smoke,
    if (flags.temp) AlarmSensorType.temperature,
    if (flags.vibration) AlarmSensorType.vibration,
  };

  AlarmSeverity _severityFor(AlarmSensorType sensor) => switch (sensor) {
    AlarmSensorType.flame => AlarmSeverity.critical,
    AlarmSensorType.smoke => AlarmSeverity.critical,
    AlarmSensorType.temperature => AlarmSeverity.warning,
    AlarmSensorType.vibration => AlarmSeverity.critical,
  };

  void _startVibration(bool repeat) {
    HapticFeedback.heavyImpact();
    _vibrationTimer?.cancel();
    if (!repeat) return;

    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }
}

final _alarmPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});