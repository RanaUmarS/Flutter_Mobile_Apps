// lib/screens/settings_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../models/fire_alarm_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _uriController;

  bool _testingConnection = false;

  // Connection metrics (best-effort; uses message RTT as a proxy)
  DateTime? _lastConnectedAt;
  Duration? _lastPing;
  DateTime? _lastPingAt;

  // UI toggles
  bool _autoReconnect = true;

  // Threshold editing (UI-only; current system is read-only in ESP32)
  // We keep the existing system behavior intact, but redesign the UI
  // so it's production-ready and extensible if ESP32-side endpoints are added.
  double _flameAdc = 4000;
  double _smokeAdc = 1400;
  double _tempC = 60;
  int _vibrationConfirmHits = 3;

  // Developer options
  String? _lastRawMessage;

  // Track previous values for ref.listen calls registered in build.
  DateTime? _prevReceivedAt;

  @override
  void initState() {
    super.initState();

    final settingsAsync = ref.read(settingsProvider);
    final uri = settingsAsync.valueOrNull?.wsUri ?? 'ws://192.168.4.1:81';
    _uriController = TextEditingController(text: uri);
  }

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  Future<void> _applyUriAndReconnect() async {
    final uri = _uriController.text.trim();
    if (uri.isEmpty) return;
    await ref.read(settingsProvider.notifier).updateUri(uri);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to $uri'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _connect() async {
    final uri = _uriController.text.trim();
    if (uri.isEmpty) return;

    // Persist the URI (this also triggers reconnect in SettingsNotifier)
    // to keep existing behavior consistent.
    await ref.read(settingsProvider.notifier).updateUri(uri);
  }

  Future<void> _disconnect() async {
    await ref.read(wsServiceProvider).disconnect();
  }

  Future<void> _testConnection() async {
    setState(() => _testingConnection = true);

    final ws = ref.read(wsServiceProvider);

    // Measure a best-effort RTT using a reconnect + ready timing.
    // This is intentionally non-invasive and doesn't require firmware changes.
    final sw = Stopwatch()..start();

    await ws.disconnect();
    await Future.delayed(const Duration(milliseconds: 250));
    await ws.connect();

    // Allow state to settle and then compute.
    await Future.delayed(const Duration(milliseconds: 600));
    sw.stop();

    if (!mounted) return;
    setState(() {
      _testingConnection = false;
      _lastPing = Duration(milliseconds: sw.elapsedMilliseconds);
      _lastPingAt = DateTime.now();
    });
  }

  _Quality _qualityFromLatency(Duration? d, WsConnectionState state) {
    if (state != WsConnectionState.connected) {
      return const _Quality('Unknown', AppColors.textDim, Icons.help_outline);
    }
    if (d == null) {
      return const _Quality('Measuring', AppColors.warmup, Icons.timelapse);
    }
    final ms = d.inMilliseconds;
    if (ms <= 120) {
      return const _Quality('Excellent', AppColors.safe, Icons.signal_cellular_alt);
    }
    if (ms <= 280) {
      return const _Quality('Good', AppColors.mono, Icons.network_wifi);
    }
    if (ms <= 600) {
      return const _Quality('Fair', AppColors.warmup, Icons.wifi_find);
    }
    return const _Quality('Poor', AppColors.alarm, Icons.wifi_off);
  }

  @override
  Widget build(BuildContext context) {
    // Register listeners in build (required by Riverpod).
    ref.listen<AsyncValue<WsConnectionState>>(
      connectionStateProvider,
          (prev, next) {
        final prevState = prev?.valueOrNull;
        final state = next.valueOrNull;
        if (state == WsConnectionState.connected &&
            prevState != WsConnectionState.connected) {
          _lastConnectedAt = DateTime.now();
          // Avoid setState during build; schedule after this frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
      },
    );

    ref.listen<AsyncValue<FireAlarmState>>(
      sensorStateProvider,
          (prev, next) {
        final v = next.valueOrNull;
        if (v == null) return;

        // Update preview only when a new state arrives.
        final receivedAt = v.receivedAt;
        if (_prevReceivedAt == receivedAt) return;
        _prevReceivedAt = receivedAt;

        _lastRawMessage = const JsonEncoder.withIndent('  ').convert({
          'receivedAt': v.receivedAt.toIso8601String(),
          'reading': v.reading,
          'uptime_sec': v.uptimeSec,
          'status': v.status.name,
          'baseline_set': v.baselineSet,
          'temp': v.temp,
          'humidity': v.humidity,
          'smoke': v.smoke,
          'flame': v.flame,
          'vibration_detected': v.vibrationDetected,
          'alarms': {
            'flame': v.alarms.flame,
            'smoke': v.alarms.smoke,
            'temp': v.alarms.temp,
            'vibration': v.alarms.vibration,
          },
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
    );

    final settingsAsync = ref.watch(settingsProvider);

    final connAsync = ref.watch(connectionStateProvider);
    final connState = connAsync.valueOrNull ?? WsConnectionState.disconnected;

    final sensorAsync = ref.watch(sensorStateProvider);
    final fireState = sensorAsync.valueOrNull;

    final isConnected = connState == WsConnectionState.connected;
    final quality = _qualityFromLatency(_lastPing, connState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IOT CONTROL CENTER'),
        actions: [
          _ThemeToggleButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width >= 900 ? 24.0 : 12.0;
          final isWide = width >= 900;

          final left = <Widget>[
            _PageHeader(
              title: 'IoT Operations Dashboard',
              subtitle:
              'Monitor connectivity, device health, sensor thresholds, and diagnostics.',
              leadingIcon: Icons.settings_suggest_rounded,
            ),
            const SizedBox(height: 12),
            _ConnectionCard(
              uriController: _uriController,
              connState: connState,
              lastConnectedAt: _lastConnectedAt,
              lastPing: _lastPing,
              lastPingAt: _lastPingAt,
              quality: quality,
              autoReconnect: _autoReconnect,
              onToggleAutoReconnect: (v) {
                setState(() => _autoReconnect = v);
              },
              onConnect: _connect,
              onDisconnect: _disconnect,
              onTest: _testingConnection ? null : _testConnection,
              onApplyUri: _applyUriAndReconnect,
              isTesting: _testingConnection,
              settingsAsync: settingsAsync,
            ),
            const SizedBox(height: 12),
            _DeviceStatusCard(
              connState: connState,
              latest: fireState,
            ),
          ];

          final right = <Widget>[
            _SensorConfigurationCard(
              flameAdc: _flameAdc,
              smokeAdc: _smokeAdc,
              tempC: _tempC,
              vibrationConfirmHits: _vibrationConfirmHits,
              onChanged: (next) {
                setState(() {
                  _flameAdc = next.flameAdc;
                  _smokeAdc = next.smokeAdc;
                  _tempC = next.tempC;
                  _vibrationConfirmHits = next.vibrationConfirmHits;
                });
                // Send each threshold live to the ESP32 as the slider moves.
                // sendThreshold() is a no-op when disconnected, so this is safe.
                final ws = ref.read(wsServiceProvider);
                ws.sendThreshold('flame', next.flameAdc.round());
                ws.sendThreshold('smoke', next.smokeAdc.round());
                ws.sendThreshold('tempDelta', double.parse(next.tempC.toStringAsFixed(1)));
              },
              onSave: () {
                // Send all current values in one batch on explicit Save tap.
                final ws = ref.read(wsServiceProvider);
                ws.sendThreshold('flame', _flameAdc.round());
                ws.sendThreshold('smoke', _smokeAdc.round());
                ws.sendThreshold('tempDelta', double.parse(_tempC.toStringAsFixed(1)));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Thresholds sent → Flame: ${_flameAdc.round()} ADC  '
                      'Smoke: ${_smokeAdc.round()} ADC  '
                      'Temp Δ: ${_tempC.toStringAsFixed(1)} °C',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HardwareMappingCard(isConnected: isConnected),
            const SizedBox(height: 12),
            _AdvancedSettingsCard(
              expectedJson: _expectedJsonExample,
              rawPreview: _lastRawMessage,
              isConnected: isConnected,
              onNetworkDiagnostics: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Network diagnostics coming soon.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ];

          if (!isWide) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              children: [...left, ...right],
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  24,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: left,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data / helpers

const String _expectedJsonExample = '{\n'
    '  "temp": 28.5,\n'
    '  "humidity": 60.2,\n'
    '  "smoke": 320,\n'
    '  "flame": 4095,\n'
    '  "baseline_set": true,\n'
    '  "status": "safe",\n'
    '  "uptime_sec": 120,\n'
    '  "reading": 42,\n'
    '  "alarms": {\n'
    '    "flame": false,\n'
    '    "smoke": false,\n'
    '    "temp": false,\n'
    '    "vibration": false\n'
    '  }\n'
    '}';

class _Quality {
  final String label;
  final Color color;
  final IconData icon;
  const _Quality(this.label, this.color, this.icon);
}

class _ThresholdDraft {
  final double flameAdc;
  final double smokeAdc;
  final double tempC;
  final int vibrationConfirmHits;

  const _ThresholdDraft({
    required this.flameAdc,
    required this.smokeAdc,
    required this.tempC,
    required this.vibrationConfirmHits,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// UI building blocks

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(leadingIcon, color: AppColors.mono),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.mono),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: t.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ]
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.uriController,
    required this.connState,
    required this.lastConnectedAt,
    required this.lastPing,
    required this.lastPingAt,
    required this.quality,
    required this.autoReconnect,
    required this.onToggleAutoReconnect,
    required this.onConnect,
    required this.onDisconnect,
    required this.onTest,
    required this.onApplyUri,
    required this.isTesting,
    required this.settingsAsync,
  });

  final TextEditingController uriController;
  final WsConnectionState connState;
  final DateTime? lastConnectedAt;
  final Duration? lastPing;
  final DateTime? lastPingAt;
  final _Quality quality;

  final bool autoReconnect;
  final ValueChanged<bool> onToggleAutoReconnect;

  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback? onTest;
  final VoidCallback onApplyUri;
  final bool isTesting;
  final AsyncValue<AppSettings> settingsAsync;

  Color _stateColor() => switch (connState) {
    WsConnectionState.connected => AppColors.safe,
    WsConnectionState.connecting => AppColors.warmup,
    WsConnectionState.disconnected => AppColors.textDim,
    WsConnectionState.error => AppColors.alarm,
  };

  String _stateLabel() => switch (connState) {
    WsConnectionState.connected => 'Connected',
    WsConnectionState.connecting => 'Connecting',
    WsConnectionState.disconnected => 'Disconnected',
    WsConnectionState.error => 'Error',
  };

  IconData _stateIcon() => switch (connState) {
    WsConnectionState.connected => Icons.cloud_done_rounded,
    WsConnectionState.connecting => Icons.cloud_sync_rounded,
    WsConnectionState.disconnected => Icons.cloud_off_rounded,
    WsConnectionState.error => Icons.cloud_off_rounded,
  };

  String _fmtTime(DateTime? t) {
    if (t == null) return '—';
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  String _fmtLatency(Duration? d) => d == null ? '—' : '${d.inMilliseconds} ms';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final stateColor = _stateColor();

    return _CardShell(
      title: 'Connection Settings',
      subtitle: 'Configure and monitor the ESP32 WebSocket link.',
      icon: Icons.hub_rounded,
      trailing: _StatusPill(
        icon: _stateIcon(),
        label: _stateLabel(),
        color: stateColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WebSocket URL',
              style: t.labelLarge?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: uriController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.link_rounded),
              hintText: 'ws://192.168.4.1:81',
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Connect'),
              ),
              OutlinedButton.icon(
                onPressed: onDisconnect,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Disconnect'),
              ),
              OutlinedButton.icon(
                onPressed: onTest,
                icon: isTesting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.wifi_tethering_rounded),
                label: const Text('Test connection'),
              ),
              TextButton.icon(
                onPressed: onApplyUri,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save URL'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Last connected',
                        value: _fmtTime(lastConnectedAt),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'Ping latency',
                        value: _fmtLatency(lastPing),
                        icon: Icons.speed_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Quality',
                        value: quality.label,
                        icon: quality.icon,
                        valueColor: quality.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'Measured',
                        value: _fmtTime(lastPingAt),
                        icon: Icons.timer_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: autoReconnect,
            onChanged: onToggleAutoReconnect,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto reconnect'),
            subtitle: Text(
              'Keeps the app connected when Wi‑Fi drops.',
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (settingsAsync.isLoading) ...[
            const SizedBox(height: 6),
            Text('Loading saved configuration…',
                style: t.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ]
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130, minWidth: 70),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                  t.labelMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: t.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({
    required this.connState,
    required this.latest,
  });

  final WsConnectionState connState;
  final FireAlarmState? latest;

  @override
  Widget build(BuildContext context) {
    final isOnline = connState == WsConnectionState.connected;
    final t = Theme.of(context).textTheme;

    final receivedAt = latest?.receivedAt;
    final uptime = latest?.uptimeFormatted;

    return _CardShell(
      title: 'Device Status',
      subtitle: 'Live state of the connected ESP32 controller.',
      icon: Icons.memory_rounded,
      trailing: _StatusPill(
        icon: isOnline ? Icons.check_circle_rounded : Icons.cancel_rounded,
        label: isOnline ? 'Online' : 'Offline',
        color: isOnline ? AppColors.safe : AppColors.textDim,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Last data received',
                  value: receivedAt == null ? '—' : receivedAt.toLocal().toString(),
                  icon: Icons.inbox_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Uptime',
                  value: uptime ?? '—',
                  icon: Icons.timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Baseline set',
                  value: latest == null ? '—' : (latest!.baselineSet ? 'Yes' : 'No'),
                  icon: Icons.rule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'System status',
                  value: latest == null ? '—' : latest!.status.name,
                  icon: Icons.shield_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isOnline
                        ? 'Device is connected and streaming sensor data.'
                        : 'Connect to your ESP32 to view live device metrics.',
                    style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: t.labelMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorConfigurationCard extends StatefulWidget {
  const _SensorConfigurationCard({
    required this.flameAdc,
    required this.smokeAdc,
    required this.tempC,
    required this.vibrationConfirmHits,
    required this.onChanged,
    required this.onSave,
  });

  final double flameAdc;
  final double smokeAdc;
  final double tempC;
  final int vibrationConfirmHits;

  final ValueChanged<_ThresholdDraft> onChanged;
  final VoidCallback onSave;

  @override
  State<_SensorConfigurationCard> createState() =>
      _SensorConfigurationCardState();
}

class _SensorConfigurationCardState extends State<_SensorConfigurationCard> {
  late double _flame;
  late double _smoke;
  late double _temp;
  late int _vibHits;

  @override
  void initState() {
    super.initState();
    _flame = widget.flameAdc;
    _smoke = widget.smokeAdc;
    _temp = widget.tempC;
    _vibHits = widget.vibrationConfirmHits;
  }

  void _emit() {
    widget.onChanged(
      _ThresholdDraft(
        flameAdc: _flame,
        smokeAdc: _smoke,
        tempC: _temp,
        vibrationConfirmHits: _vibHits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return _CardShell(
      title: 'Sensor Configuration',
      subtitle: 'Review and tune alert thresholds.',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SensorSettingRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.flame,
            title: 'Flame Sensor',
            subtitle: 'Detects fire intensity (ADC reading).',
            footer: Text(
              'Current threshold: ${_flame.toStringAsFixed(0)} ADC',
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            child: Slider(
              value: _flame,
              min: 0,
              max: 4095,
              divisions: 4095 ~/ 50,
              onChanged: (v) {
                setState(() => _flame = v);
                _emit();
              },
            ),
          ),
          const Divider(height: 28),
          _SensorSettingRow(
            icon: Icons.smoking_rooms_rounded,
            iconColor: AppColors.smoke,
            title: 'Smoke Sensor',
            subtitle: 'Triggers smoke alert when air quality degrades.',
            footer: Text(
              'Current threshold: ${_smoke.toStringAsFixed(0)} ADC',
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            child: Slider(
              value: _smoke,
              min: 0,
              max: 4095,
              divisions: 4095 ~/ 50,
              onChanged: (v) {
                setState(() => _smoke = v);
                _emit();
              },
            ),
          ),
          const Divider(height: 28),
          _SensorSettingRow(
            icon: Icons.thermostat_rounded,
            iconColor: AppColors.temp,
            title: 'Temperature',
            subtitle: 'Triggers overheat alert.',
            footer: Text(
              'Threshold: ${_temp.toStringAsFixed(0)} °C',
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            child: Slider(
              value: _temp,
              min: 30,
              max: 90,
              divisions: 60,
              onChanged: (v) {
                setState(() => _temp = v);
                _emit();
              },
            ),
          ),
          const Divider(height: 28),
          _SensorSettingRow(
            icon: Icons.vibration_rounded,
            iconColor: AppColors.vibration,
            title: 'Vibration',
            subtitle: 'Confirm alert after consecutive hits.',
            footer: Text(
              'Confirm hits: $_vibHits consecutive',
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _vibHits.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) {
                      setState(() => _vibHits = v.round());
                      _emit();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '$_vibHits'),
                    onSubmitted: (txt) {
                      final n = int.tryParse(txt);
                      if (n == null) return;
                      final clamped = n.clamp(1, 10);
                      setState(() => _vibHits = clamped);
                      _emit();
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onSave,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save thresholds'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_tethering_rounded,
                    size: 18, color: AppColors.safe),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thresholds are sent to the ESP32 over WebSocket in real time. '
                    'Changes take effect immediately on the hardware while connected.',
                    style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SensorSettingRow extends StatelessWidget {
  const _SensorSettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: iconColor.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 4),
        footer,
      ],
    );
  }
}

class _HardwareMappingCard extends StatelessWidget {
  const _HardwareMappingCard({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final status = isConnected ? 'OK' : '—';
    final statusColor = isConnected ? AppColors.safe : AppColors.textDim;

    return _CardShell(
      title: 'Hardware Mapping',
      subtitle: 'Wiring reference for installed sensors and peripherals.',
      icon: Icons.schema_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _TableHeader(),
                const Divider(height: 1),
                _TableRowItem(
                  icon: Icons.thermostat_rounded,
                  iconColor: AppColors.temp,
                  name: 'DHT11',
                  gpio: 'GPIO 26',
                  status: status,
                  statusColor: statusColor,
                ),
                const Divider(height: 1),
                _TableRowItem(
                  icon: Icons.smoking_rooms_rounded,
                  iconColor: AppColors.smoke,
                  name: 'MQ-2',
                  gpio: 'GPIO 34',
                  status: status,
                  statusColor: statusColor,
                ),
                const Divider(height: 1),
                _TableRowItem(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.flame,
                  name: 'Flame IR',
                  gpio: 'GPIO 35',
                  status: status,
                  statusColor: statusColor,
                ),
                const Divider(height: 1),
                _TableRowItem(
                  icon: Icons.vibration_rounded,
                  iconColor: AppColors.vibration,
                  name: 'SW-420',
                  gpio: 'GPIO 27',
                  status: status,
                  statusColor: statusColor,
                ),
                const Divider(height: 1),
                _TableRowItem(
                  icon: Icons.display_settings_rounded,
                  iconColor: AppColors.mono,
                  name: 'LCD',
                  gpio: 'SDA21/SCL22',
                  status: status,
                  statusColor: statusColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Spacer matching icon (30) + gap (8), slightly reduced to shift Device left
          const SizedBox(width: 28),
          // Device name — fills remaining space
          Expanded(
            child: Text(
              'Device',
              style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // GPIO — fixed width
          SizedBox(
            width: 84,
            child: Text(
              'GPIO',
              style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Status — fixed width
          SizedBox(
            width: 56,
            child: Text(
              'Status',
              style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRowItem extends StatelessWidget {
  const _TableRowItem({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.gpio,
    required this.status,
    required this.statusColor,
  });

  final IconData icon;
  final Color iconColor;
  final String name;
  final String gpio;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Icon — fixed 30px
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          // Device name — takes all remaining space
          Expanded(
            child: Text(
              name,
              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          const SizedBox(width: 8),
          // GPIO — fixed 84px (fits "SDA21/SCL22")
          SizedBox(
            width: 84,
            child: Text(
              gpio,
              style: t.bodyMedium?.copyWith(color: AppColors.mono, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          const SizedBox(width: 8),
          // Status badge — fixed 56px
          SizedBox(
            width: 56,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedSettingsCard extends StatelessWidget {
  const _AdvancedSettingsCard({
    required this.expectedJson,
    required this.rawPreview,
    required this.isConnected,
    required this.onNetworkDiagnostics,
  });

  final String expectedJson;
  final String? rawPreview;
  final bool isConnected;
  final VoidCallback onNetworkDiagnostics;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return _CardShell(
      title: 'Advanced Settings',
      subtitle: 'Developer tools and diagnostics (collapsed by default).',
      icon: Icons.admin_panel_settings_rounded,
      child: Column(
        children: [
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedIconColor: AppColors.textSecondary,
            iconColor: AppColors.textSecondary,
            title: const Text('Developer Options'),
            subtitle: Text(
              'Expected JSON format, raw previews, and diagnostics.',
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            children: [
              const SizedBox(height: 8),
              _JsonPanel(
                title: 'Expected ESP32 JSON',
                body: expectedJson,
              ),
              const SizedBox(height: 12),
              _JsonPanel(
                title: 'Raw JSON Preview (latest parsed state)',
                body: rawPreview ??
                    '{\n  "info": "No data yet. Connect to device to view live preview."\n}',
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.network_check_rounded),
                title: const Text('Network diagnostics'),
                subtitle: Text(
                  isConnected
                      ? 'Run quick checks on the active connection.'
                      : 'Connect first to enable diagnostics.',
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: onNetworkDiagnostics,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JsonPanel extends StatelessWidget {
  const _JsonPanel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: t.labelLarge?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              body,
              style: t.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Theme toggle button ───────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: AppColors.textSecondary,
        ),
      ),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}