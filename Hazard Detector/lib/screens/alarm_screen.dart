// lib/screens/alarm_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/fire_alarm_state.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmState = ref.watch(alarmServiceProvider);
    final active = alarmState.activeEvents;
    final primary = alarmState.primaryAlarm;

    return Scaffold(
      backgroundColor: const Color(0xFF120407),
      appBar: AppBar(
        title: const Text('ACTIVE ALARM'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: primary == null
            ? const _NoActiveAlarm()
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AlarmBanner(event: primary, count: active.length),
            const SizedBox(height: 12),
            for (final event in active) ...[
              _AlarmDetailCard(event: event),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: alarmState.acknowledged
                  ? null
                  : () {
                      // 1. Mark acknowledged in app state (existing behaviour)
                      ref
                          .read(alarmServiceProvider.notifier)
                          .acknowledgeActiveAlarm();
                      // 2. Send silence command to ESP32 — stops buzzer + LEDs NOW
                      ref.read(wsServiceProvider).sendSilence();
                    },
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                alarmState.acknowledged
                    ? 'Alarm acknowledged'
                    : 'Acknowledge alarm',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The alarm remains active until the ESP32 reports all triggered sensors back in the safe range.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({required this.event, required this.count});

  final AlarmEvent event;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color =
    event.severity == AlarmSeverity.critical ? AppColors.alarm : AppColors.warmup;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.65), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.sensorType.hazardLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count == 1 ? event.sensorType.label : '$count simultaneous hazards',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, yyyy  HH:mm:ss').format(event.timestamp),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AlarmDetailCard extends StatelessWidget {
  const _AlarmDetailCard({required this.event});

  final AlarmEvent event;

  @override
  Widget build(BuildContext context) {
    final color =
    event.severity == AlarmSeverity.critical ? AppColors.alarm : AppColors.warmup;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(event.sensorType), color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.sensorType.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(event: event),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Metric(label: 'Hazard', value: event.sensorType.hazardLabel),
                _Metric(label: 'Severity', value: event.severity.name),
                _Metric(label: 'Temperature', value: '${event.temp.toStringAsFixed(1)} C'),
                _Metric(label: 'Smoke', value: '${event.smoke} ADC'),
                _Metric(label: 'Flame', value: '${event.flame} ADC'),
                _Metric(
                  label: 'Vibration',
                  value: event.vibration ? 'Detected' : 'None',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AlarmSensorType type) => switch (type) {
    AlarmSensorType.flame => Icons.local_fire_department_rounded,
    AlarmSensorType.smoke => Icons.smoking_rooms_rounded,
    AlarmSensorType.temperature => Icons.thermostat_rounded,
    AlarmSensorType.vibration => Icons.vibration_rounded,
  };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.event});

  final AlarmEvent event;

  @override
  Widget build(BuildContext context) {
    final color = event.status == AlarmRecordStatus.acknowledged
        ? AppColors.mono
        : AppColors.alarm;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        event.status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActiveAlarm extends StatelessWidget {
  const _NoActiveAlarm();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No active alarm',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}