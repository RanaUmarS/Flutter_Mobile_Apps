// lib/widgets/connection_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../services/websocket_service.dart';
class ConnectionBadge extends ConsumerWidget {
  const ConnectionBadge({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connAsync = ref.watch(connectionStateProvider);
    final (color, tooltip, label) = connAsync.when(
      data: (s) => switch (s) {
        WsConnectionState.connected => (
            AppColors.safe,
            'Connected to ESP32',
            'LIVE'
          ),
        WsConnectionState.connecting => (
            AppColors.warmup,
            'Connecting to ESP32...',
            'CONN'
          ),
        WsConnectionState.disconnected => (
            AppColors.textDim,
            'ESP32 Disconnected',
            'OFF'
          ),
        WsConnectionState.error => (AppColors.alarm, 'Connection Error', 'ERR'),
      },
      loading: () => (AppColors.warmup, 'Connecting...', 'CONN'),
      error: (_, __) => (AppColors.alarm, 'Error', 'ERR'),
    );
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 5)
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
