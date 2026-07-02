// lib/widgets/status_header.dart

import 'package:flutter/material.dart';
import '../models/fire_alarm_state.dart';
import '../theme/app_theme.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key, required this.state});
  final FireAlarmState state;

  @override
  Widget build(BuildContext context) {
    // If vibration alarm is active, override status display
    final isVibrationOnly = state.alarms.vibration &&
        !state.alarms.flame &&
        !state.alarms.smoke &&
        !state.alarms.temp;

    final (color, glow, icon, label) = state.alarms.vibration && isVibrationOnly
        ? (
            AppColors.vibration,
            AppColors.vibration.withValues(alpha: 0.2),
            '📳',
            'EARTHQUAKE'
          )
        : switch (state.status) {
            SystemStatus.safe => (
                AppColors.safe,
                AppColors.safeGlow,
                '✅',
                'ALL CLEAR'
              ),
            SystemStatus.alarm => (
                AppColors.alarm,
                AppColors.alarmGlow,
                '🚨',
                'HAZARD ALARM'
              ),
            SystemStatus.warmingUp => (
                AppColors.warmup,
                AppColors.warmupGlow,
                '⏳',
                'WARMING UP'
              ),
          };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: glow,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                if (state.status == SystemStatus.warmingUp)
                  Text(
                    'DHT11 baseline calibrating • ${state.uptimeFormatted}',
                    style: const TextStyle(
                      color: AppColors.warmup,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                if (state.status == SystemStatus.safe && !state.alarms.any)
                  Text(
                    'All ${4} sensors monitoring normally',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                if (state.alarms.any)
                  Text(
                    '${state.alarms.activeAlarms.length} alarm${state.alarms.activeAlarms.length > 1 ? 's' : ''} active — check sensors',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '#${state.reading}',
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
