import 'package:flutter/foundation.dart';

enum SystemStatus { warmingUp, safe, alarm }

@immutable
class AlarmFlags {
  final bool flame;
  final bool smoke;
  final bool temp;
  final bool vibration;

  const AlarmFlags({
    required this.flame,
    required this.smoke,
    required this.temp,
    this.vibration = false,
  });

  bool get any => flame || smoke || temp || vibration;

  List<String> get activeAlarms => [
        if (flame) 'flame',
        if (smoke) 'smoke',
        if (temp) 'temp',
        if (vibration) 'vibration',
      ];

  // Handles BOTH formats:
  // Format A (nested):  { "alarms": { "flame": true, "smoke": false ... } }
  // Format B (flat):    { "flameAlarm": true, "smokeAlarm": false ... }
  factory AlarmFlags.fromJson(Map<String, dynamic> json,
      {Map<String, dynamic>? root}) {
    bool b(Object? value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
      return false;
    }

    // Nested format (from "alarms" sub-object)
    if (json.containsKey('flame') ||
        json.containsKey('smoke') ||
        json.containsKey('temp') ||
        json.containsKey('vibration')) {
      return AlarmFlags(
        flame: b(json['flame']),
        smoke: b(json['smoke']),
        temp: b(json['temp']) || b(json['temperature']),
        vibration: b(json['vibration']),
      );
    }

    final r = root ?? json;
    return AlarmFlags(
      flame: b(r['flameAlarm']),
      smoke: b(r['smokeAlarm']),
      temp: b(r['tempAlarm']) || b(r['temperatureAlarm']),
      vibration: b(r['vibrationAlarm']),
    );
  }

  AlarmFlags copyWith({
    bool? flame,
    bool? smoke,
    bool? temp,
    bool? vibration,
  }) =>
      AlarmFlags(
        flame: flame ?? this.flame,
        smoke: smoke ?? this.smoke,
        temp: temp ?? this.temp,
        vibration: vibration ?? this.vibration,
      );
}

enum AlarmSensorType { flame, smoke, temperature, vibration }

enum AlarmSeverity { warning, critical }

enum AlarmRecordStatus { active, acknowledged, resolved }

extension AlarmSensorTypeX on AlarmSensorType {
  String get label => switch (this) {
        AlarmSensorType.flame => 'Flame Sensor',
        AlarmSensorType.smoke => 'Smoke Sensor',
        AlarmSensorType.temperature => 'Temperature Sensor',
        AlarmSensorType.vibration => 'Vibration Sensor',
      };

  String get hazardLabel => switch (this) {
        AlarmSensorType.flame => 'Fire risk',
        AlarmSensorType.smoke => 'Smoke or gas',
        AlarmSensorType.temperature => 'Temperature spike',
        AlarmSensorType.vibration => 'Seismic activity',
      };
}

@immutable
class FireAlarmState {
  final int reading;
  final int uptimeSec;
  final SystemStatus status;
  final bool baselineSet;

  final double temp;
  final double humidity;
  final double? tempBaseline;

  final int smoke;
  final int? smokeBaseline;

  final int flame;

  final bool vibrationDetected;

  final AlarmFlags alarms;
  final DateTime receivedAt;

  const FireAlarmState({
    required this.reading,
    required this.uptimeSec,
    required this.status,
    required this.baselineSet,
    required this.temp,
    required this.humidity,
    this.tempBaseline,
    required this.smoke,
    this.smokeBaseline,
    required this.flame,
    this.vibrationDetected = false,
    required this.alarms,
    required this.receivedAt,
  });

  String get uptimeFormatted {
    final m = uptimeSec ~/ 60;
    final s = uptimeSec % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  factory FireAlarmState.fromJson(Map<String, dynamic> json) {
    // ── Determine alarm flags ───────────────────────────────────────────────
    // Support both nested { "alarms": {...} } and flat { "flameAlarm": bool }
    AlarmFlags alarms;
    final nested = json['alarms'];
    if (nested is Map<String, dynamic> && nested.isNotEmpty) {
      alarms = AlarmFlags.fromJson(nested);
    } else {
      // Flat format from our ESP32 firmware
      alarms = AlarmFlags.fromJson({}, root: json);
    }

    // ── Determine baseline ─────────────────────────────────────────────────
    // ESP32 sends "baseline" as a float (the temp baseline value directly)
    // Some versions send "baseline_set" bool + "temp_baseline" float
    final baselineRaw = json['baseline'];
    double? tempBaseline;
    bool baselineSet = false;

    if (baselineRaw is num && baselineRaw > 0) {
      tempBaseline = baselineRaw.toDouble();
      baselineSet = true;
    } else if (json['temp_baseline'] is num) {
      tempBaseline = (json['temp_baseline'] as num).toDouble();
      baselineSet = true;
    }

    // Also accept explicit baseline_set flag
    if (json['baseline_set'] is bool) {
      baselineSet = json['baseline_set'] as bool;
    }

    // ── Status ─────────────────────────────────────────────────────────────
    SystemStatus status;
    if (!baselineSet) {
      status = SystemStatus.warmingUp;
    } else if (alarms.any) {
      status = SystemStatus.alarm;
    } else {
      status = SystemStatus.safe;
    }

    // ── Vibration ──────────────────────────────────────────────────────────
    final bool vibrationDetected = (json['vibration'] == 1) ||
        (json['vibration_detected'] == true) ||
        alarms.vibration;

    return FireAlarmState(
      reading: json['reading'] as int? ?? 0,
      uptimeSec: json['uptime_sec'] as int? ?? 0,
      status: status,
      baselineSet: baselineSet,
      temp: (json['temp'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      tempBaseline: tempBaseline,
      smoke: json['smoke'] as int? ?? 0,
      smokeBaseline: json['smoke_baseline'] as int?,
      flame: json['flame'] as int? ?? 4095,
      vibrationDetected: vibrationDetected,
      alarms: alarms,
      receivedAt: DateTime.now(),
    );
  }

  FireAlarmState copyWith({
    int? reading,
    int? uptimeSec,
    SystemStatus? status,
    bool? baselineSet,
    double? temp,
    double? humidity,
    double? tempBaseline,
    int? smoke,
    int? smokeBaseline,
    int? flame,
    bool? vibrationDetected,
    AlarmFlags? alarms,
    DateTime? receivedAt,
  }) =>
      FireAlarmState(
        reading: reading ?? this.reading,
        uptimeSec: uptimeSec ?? this.uptimeSec,
        status: status ?? this.status,
        baselineSet: baselineSet ?? this.baselineSet,
        temp: temp ?? this.temp,
        humidity: humidity ?? this.humidity,
        tempBaseline: tempBaseline ?? this.tempBaseline,
        smoke: smoke ?? this.smoke,
        smokeBaseline: smokeBaseline ?? this.smokeBaseline,
        flame: flame ?? this.flame,
        vibrationDetected: vibrationDetected ?? this.vibrationDetected,
        alarms: alarms ?? this.alarms,
        receivedAt: receivedAt ?? this.receivedAt,
      );
}

@immutable
class AlarmEvent {
  final String id;
  final DateTime timestamp;
  final DateTime? resolvedAt;
  final AlarmSensorType sensorType;
  final AlarmSeverity severity;
  final AlarmRecordStatus status;
  final AlarmFlags flags;
  final double temp;
  final int smoke;
  final int flame;
  final bool vibration;

  const AlarmEvent({
    required this.id,
    required this.timestamp,
    this.resolvedAt,
    required this.sensorType,
    required this.severity,
    required this.status,
    required this.flags,
    required this.temp,
    required this.smoke,
    required this.flame,
    this.vibration = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'sensorType': sensorType.name,
        'severity': severity.name,
        'status': status.name,
        'flame': flags.flame,
        'smoke': flags.smoke,
        'temp': flags.temp,
        'vibration': flags.vibration,
        'tempValue': temp,
        'smokeValue': smoke,
        'flameValue': flame,
        'vibrationValue': vibration,
      };

  factory AlarmEvent.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.parse(json['timestamp'] as String);
    return AlarmEvent(
      id: json['id'] as String? ?? timestamp.toIso8601String(),
      timestamp: timestamp,
      resolvedAt: json['resolvedAt'] is String
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
      sensorType: AlarmSensorType.values.firstWhere(
        (e) => e.name == json['sensorType'],
        orElse: () => _legacySensorType(json),
      ),
      severity: AlarmSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlarmSeverity.critical,
      ),
      status: AlarmRecordStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AlarmRecordStatus.resolved,
      ),
      flags: AlarmFlags(
        flame: json['flame'] as bool? ?? false,
        smoke: json['smoke'] as bool? ?? false,
        temp: json['temp'] as bool? ?? false,
        vibration: json['vibration'] as bool? ?? false,
      ),
      temp: (json['tempValue'] as num?)?.toDouble() ?? 0,
      smoke: json['smokeValue'] as int? ?? 0,
      flame: json['flameValue'] as int? ?? 4095,
      vibration: json['vibrationValue'] as bool? ?? false,
    );
  }

  factory AlarmEvent.fromState({
    required FireAlarmState state,
    required AlarmSensorType sensorType,
    required AlarmSeverity severity,
  }) {
    final timestamp = state.receivedAt;
    return AlarmEvent(
      id: '${sensorType.name}-${timestamp.microsecondsSinceEpoch}',
      timestamp: timestamp,
      sensorType: sensorType,
      severity: severity,
      status: AlarmRecordStatus.active,
      flags: state.alarms,
      temp: state.temp,
      smoke: state.smoke,
      flame: state.flame,
      vibration: state.vibrationDetected,
    );
  }

  AlarmEvent copyWith({
    DateTime? resolvedAt,
    AlarmRecordStatus? status,
  }) =>
      AlarmEvent(
        id: id,
        timestamp: timestamp,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        sensorType: sensorType,
        severity: severity,
        status: status ?? this.status,
        flags: flags,
        temp: temp,
        smoke: smoke,
        flame: flame,
        vibration: vibration,
      );

  String get summary => '${sensorType.label} - ${sensorType.hazardLabel}';

  static AlarmSensorType _legacySensorType(Map<String, dynamic> json) {
    if (json['flame'] == true) return AlarmSensorType.flame;
    if (json['smoke'] == true) return AlarmSensorType.smoke;
    if (json['vibration'] == true) return AlarmSensorType.vibration;
    return AlarmSensorType.temperature;
  }
}
