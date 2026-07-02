// lib/widgets/sensor_card.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subLabel,
    required this.color,
    required this.isAlert,
    this.threshold,
    this.gaugeValue,
    this.invertGauge = false,
  });

  final String icon;
  final String label;
  final String value;
  final String? subLabel;
  final Color color;
  final bool isAlert;
  final String? threshold;
  final double? gaugeValue; // 0.0–1.0
  final bool invertGauge;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isAlert ? AppColors.alarm : color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0x22FF1744) : AppColors.surface,
        border: Border.all(
          color: isAlert
              ? AppColors.alarm.withValues(alpha: 0.6)
              : AppColors.border,
          width: isAlert ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isAlert
            ? [BoxShadow(color: AppColors.alarmGlow, blurRadius: 12)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (isAlert)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
          ),
          const SizedBox(height: 10),

          // Value
          Text(
            value,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),

          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel!,
              style: TextStyle(
                color: effectiveColor.withValues(alpha: 0.6),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],

          // Gauge bar
          if (gaugeValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: gaugeValue!.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(effectiveColor),
              ),
            ),
          ],

          if (threshold != null) ...[
            const SizedBox(height: 6),
            Text(
              threshold!,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}