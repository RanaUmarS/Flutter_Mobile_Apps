// lib/screens/dashboard_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/fire_alarm_state.dart';
import '../providers/providers.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_badge.dart';
import '../widgets/sensor_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(sensorStateProvider);
    final connAsync = ref.watch(connectionStateProvider);
    final history = ref.watch(sensorHistoryProvider);

    // Eagerly initialize history so listener is active
    ref.watch(historyProvider);

    final connState = connAsync.valueOrNull;
    final isUnavailable = (connState == WsConnectionState.disconnected ||
        connState == WsConnectionState.error) &&
        sensorAsync.valueOrNull == null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('HAZARD MONITOR'),
        actions: [
          const ConnectionBadge(),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          Consumer(builder: (context, ref, _) {
            final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
            return IconButton(
              tooltip: isDark ? 'Light mode' : 'Dark mode',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: isUnavailable
          ? _UnavailableView()
          : sensorAsync.when(
        data: (state) => _Dashboard(state: state, history: history),
        loading: () => const _WaitingView(),
        error: (e, _) => _ErrorView(error: e.toString()),
      ),
    );
  }
}

// ── Waiting / Error / Unavailable ────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.mono,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'CONNECTING TO ESP32...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Waiting for first sensor reading',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  // FIX: Used GoRouter context.push instead of Navigator.pushNamed
  // which is incompatible with go_router.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textDim,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ESP32 UNAVAILABLE',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cannot reach the ESP32 device.\nCheck power, Wi-Fi, and IP address.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                letterSpacing: 1,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mono,
                side: const BorderSide(color: AppColors.mono),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('OPEN SETTINGS',
                  style: TextStyle(letterSpacing: 2, fontSize: 11)),
              // FIX: was Navigator.pushNamed which breaks with go_router
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error,
          style: const TextStyle(color: AppColors.alarm, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Main Dashboard ────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.state, required this.history});
  final FireAlarmState state;
  final List<FireAlarmState> history;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // FIX: Removed StatusHeader (showed "WARMING UP" banner).
        // Replaced with inline _SystemHealthBar + _BaselineRow which show
        // the same info without the misleading warmup state.
        const SizedBox(height: 8),
        _SystemHealthBar(state: state),
        const SizedBox(height: 8),
        // Only show baseline row when data is actually available
        if (state.baselineSet || state.tempBaseline != null)
          _BaselineRow(state: state),
        if (state.baselineSet || state.tempBaseline != null)
          const SizedBox(height: 8),
        _SensorGrid(state: state),
        const SizedBox(height: 16),
        if (history.length >= 3) _Charts(history: history),
      ],
    );
  }
}

// ── System Health Bar ─────────────────────────────────────────────────────────

class _SystemHealthBar extends StatelessWidget {
  const _SystemHealthBar({required this.state});
  final FireAlarmState state;

  @override
  Widget build(BuildContext context) {
    final activeCount = [
      state.alarms.flame,
      state.alarms.smoke,
      state.alarms.temp,
      state.alarms.vibration,
    ].where((b) => b).length;

    final color = activeCount == 0
        ? AppColors.safe
        : activeCount == 1
        ? AppColors.warmup
        : AppColors.alarm;

    final label = activeCount == 0
        ? 'ALL SENSORS NOMINAL'
        : '$activeCount ACTIVE ALARM${activeCount > 1 ? 'S' : ''}';

    // FIX: Show meaningful live sensor data in the health bar subtitle
    // instead of leaving it empty. Shows temp + smoke in a compact line.
    final liveInfo = state.baselineSet
        ? '${state.temp.toStringAsFixed(1)}°C  ·  ${state.humidity.toStringAsFixed(0)}% RH  ·  Smoke ${state.smoke} ADC'
        : 'Calibrating baseline...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SensorDot(
                  active: state.alarms.flame,
                  color: AppColors.flame,
                  label: 'FL'),
              const SizedBox(width: 8),
              _SensorDot(
                  active: state.alarms.smoke,
                  color: AppColors.smoke,
                  label: 'SM'),
              const SizedBox(width: 8),
              _SensorDot(
                  active: state.alarms.temp,
                  color: AppColors.temp,
                  label: 'TM'),
              const SizedBox(width: 8),
              _SensorDot(
                  active: state.alarms.vibration,
                  color: AppColors.vibration,
                  label: 'VB'),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: AppColors.border),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // FIX: Show uptime only if we have real data (>0)
              if (state.uptimeSec > 0)
                Text(
                  'UP ${state.uptimeFormatted}',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            liveInfo,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorDot extends StatelessWidget {
  const _SensorDot({
    required this.active,
    required this.color,
    required this.label,
  });
  final bool active;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? color : AppColors.textDim.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: active
                ? [
              BoxShadow(
                  color: color.withValues(alpha: 0.6), blurRadius: 6)
            ]
                : null,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? color : AppColors.textDim,
            fontSize: 7,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Baseline Row ──────────────────────────────────────────────────────────────
// FIX: Only shown when baseline data exists. Shows actual values instead of ---

class _BaselineRow extends StatelessWidget {
  const _BaselineRow({required this.state});
  final FireAlarmState state;

  @override
  Widget build(BuildContext context) {
    final tempDelta = state.tempBaseline != null
        ? state.temp - state.tempBaseline!
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          _BaselineChip(
            label: 'BASELINE TEMP',
            value: state.tempBaseline != null
                ? '${state.tempBaseline!.toStringAsFixed(1)} °C'
                : '${state.temp.toStringAsFixed(1)} °C',
            sub: tempDelta != null
                ? 'Δ ${tempDelta >= 0 ? '+' : ''}${tempDelta.toStringAsFixed(2)} °C'
                : null,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 36, color: AppColors.border),
          const SizedBox(width: 8),
          _BaselineChip(
            label: 'SMOKE BASELINE',
            value: state.smokeBaseline != null
                ? '${state.smokeBaseline} ADC'
                : '${state.smoke} ADC',
            sub: 'threshold > 1400',
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: state.baselineSet
                  ? AppColors.safe.withValues(alpha: 0.12)
                  : AppColors.warmup.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              state.baselineSet ? 'CALIBRATED' : 'CALIBRATING',
              style: TextStyle(
                color: state.baselineSet ? AppColors.safe : AppColors.warmup,
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BaselineChip extends StatelessWidget {
  const _BaselineChip({
    required this.label,
    required this.value,
    this.sub,
  });
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.mono,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 1),
          Text(
            sub!,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sensor Grid ───────────────────────────────────────────────────────────────

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.state});
  final FireAlarmState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE SENSORS',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: SensorCard(
                  icon: '🌡️',
                  label: 'TEMPERATURE',
                  value: '${state.temp.toStringAsFixed(1)} °C',
                  subLabel: state.tempBaseline != null
                      ? 'Δ ${(state.temp - state.tempBaseline!).toStringAsFixed(2)} °C'
                      : null,
                  color: AppColors.temp,
                  isAlert: state.alarms.temp,
                  threshold: state.tempBaseline != null
                      ? 'alarm > ${(state.tempBaseline! + 0.6).toStringAsFixed(1)} °C'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SensorCard(
                  icon: '💧',
                  label: 'HUMIDITY',
                  value: '${state.humidity.toStringAsFixed(1)} %',
                  color: AppColors.humidity,
                  isAlert: false,
                  gaugeValue: state.humidity / 100.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: SensorCard(
                  icon: '💨',
                  label: 'SMOKE / GAS',
                  value: '${state.smoke} ADC',
                  subLabel: state.smokeBaseline != null
                      ? 'Δ ${state.smoke - (state.smokeBaseline ?? 0)} ADC'
                      : null,
                  color: AppColors.smoke,
                  isAlert: state.alarms.smoke,
                  threshold: 'alarm > 1400 ADC',
                  gaugeValue: (state.smoke / 4095.0).clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SensorCard(
                  icon: '🔥',
                  label: 'FLAME IR',
                  value: '${state.flame} ADC',
                  subLabel: state.flame < 4095
                      ? '${(100 - (state.flame / 40.95)).toStringAsFixed(0)}% intensity'
                      : null,
                  color: AppColors.flame,
                  isAlert: state.alarms.flame,
                  threshold: 'alarm < 4000 ADC',
                  invertGauge: true,
                  gaugeValue: 1.0 - (state.flame / 4095.0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _VibrationCard(state: state),
      ],
    );
  }
}

// ── Vibration Card (SW-420) ───────────────────────────────────────────────────

class _VibrationCard extends StatelessWidget {
  const _VibrationCard({required this.state});
  final FireAlarmState state;

  @override
  Widget build(BuildContext context) {
    final isAlert = state.alarms.vibration;
    final effectiveColor = isAlert ? AppColors.alarm : AppColors.vibration;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0x22FF1744) : AppColors.surface,
        border: Border.all(
          color: isAlert
              ? AppColors.alarm.withValues(alpha: 0.6)
              : AppColors.vibration.withValues(alpha: 0.3),
          width: isAlert ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isAlert
            ? [BoxShadow(color: AppColors.alarmGlow, blurRadius: 14)]
            : null,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📳', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  const Text(
                    'VIBRATION / EARTHQUAKE',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (isAlert) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.alarm.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'ALERT',
                        style: TextStyle(
                          color: AppColors.alarm,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isAlert ? 'SEISMIC ACTIVITY' : 'NO ACTIVITY',
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAlert
                    ? 'SW-420 consecutive hits detected'
                    : 'SW-420 sensor nominal',
                style: TextStyle(
                  color: effectiveColor.withValues(alpha: 0.6),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                isAlert ? Icons.vibration_rounded : Icons.sensors_rounded,
                color: effectiveColor,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Charts ────────────────────────────────────────────────────────────────────

class _Charts extends StatelessWidget {
  const _Charts({required this.history});
  final List<FireAlarmState> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE TREND',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        _SparkCard(
          label: 'TEMPERATURE (°C)',
          color: AppColors.temp,
          spots: history
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.temp))
              .toList(),
        ),
        const SizedBox(height: 8),
        _SparkCard(
          label: 'SMOKE ADC',
          color: AppColors.smoke,
          spots: history
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.smoke.toDouble()))
              .toList(),
        ),
      ],
    );
  }
}

class _SparkCard extends StatelessWidget {
  const _SparkCard({
    required this.label,
    required this.color,
    required this.spots,
  });
  final String label;
  final Color color;
  final List<FlSpot> spots;

  @override
  Widget build(BuildContext context) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) < 1 ? 1.0 : (maxY - minY) * 0.2;

    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY - padding,
                maxY: maxY + padding,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}