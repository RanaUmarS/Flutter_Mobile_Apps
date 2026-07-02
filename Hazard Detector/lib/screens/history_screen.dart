// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/fire_alarm_state.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text(
          'ALARM HISTORY',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: c.textSecondary),
              tooltip: 'Clear history',
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: history.isEmpty
          ? const _EmptyState()
          : Column(
        children: [
          _HistorySummaryBar(history: history),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: history.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryTile(event: history[i], index: i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final c = AppColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.report_rounded, color: AppColors.alarm, size: 24),
            const SizedBox(width: 12),
            Text('Clear History',
                style: TextStyle(
                    color: c.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Delete all alarm records? This action cannot be undone.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: c.textSecondary),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alarm,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(alarmServiceProvider.notifier).clearHistory();
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _HistorySummaryBar extends StatelessWidget {
  const _HistorySummaryBar({required this.history});
  final List<AlarmEvent> history;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final counts = {
      'flame':     history.where((e) => e.flags.flame).length,
      'smoke':     history.where((e) => e.flags.smoke).length,
      'temp':      history.where((e) => e.flags.temp).length,
      'vibration': history.where((e) => e.flags.vibration).length,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(color: c.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Total counter — simplified
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL',
                  style: TextStyle(
                    color: c.textDim,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              Text('${history.length}',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 36, color: c.border),
          const SizedBox(width: 12),
          // Event type chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (counts['flame']! > 0)
                    _SummaryChip(
                        label: 'FLAME',
                        count: counts['flame']!,
                        color: c.flame,
                        icon: Icons.whatshot_rounded),
                  if (counts['smoke']! > 0)
                    _SummaryChip(
                        label: 'SMOKE',
                        count: counts['smoke']!,
                        color: c.smoke,
                        icon: Icons.cloud_rounded),
                  if (counts['temp']! > 0)
                    _SummaryChip(
                        label: 'TEMP',
                        count: counts['temp']!,
                        color: c.temp,
                        icon: Icons.device_thermostat),
                  if (counts['vibration']! > 0)
                    _SummaryChip(
                        label: 'VIB',
                        count: counts['vibration']!,
                        color: c.vibration,
                        icon: Icons.sensors_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, double value, child) =>
            Opacity(opacity: value, child: Transform.scale(scale: value, child: child)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 80, color: c.safe),
            const SizedBox(height: 16),
            Text('ALL CLEAR',
                style: TextStyle(
                  color: c.safe,
                  fontSize: 16,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            Text('No alarm events recorded',
                style: TextStyle(color: c.textDim, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── History tile ──────────────────────────────────────────────────────────────

class _HistoryTile extends StatefulWidget {
  const _HistoryTile({required this.event, required this.index});
  final AlarmEvent event;
  final int index;

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _isExpanded = false;

  Color _accentColor(AppAdaptiveColors c) => widget.event.flags.flame
      ? c.flame
      : widget.event.flags.vibration
      ? c.vibration
      : widget.event.flags.smoke
      ? c.smoke
      : c.temp;

  IconData get _sensorIcon => switch (widget.event.sensorType) {
    AlarmSensorType.flame       => Icons.whatshot_rounded,
    AlarmSensorType.smoke       => Icons.cloud_rounded,
    AlarmSensorType.temperature => Icons.device_thermostat,
    AlarmSensorType.vibration   => Icons.sensors_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final df = DateFormat('MMM dd, yyyy • HH:mm:ss');
    final accent = _accentColor(c);
    final isCritical = widget.event.severity == AlarmSeverity.critical;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      // ── KEY FIX: use adaptive surfaceElevated, not bg ──
                      color: c.surfaceElevated,
                      border: Border.all(
                        color: accent.withValues(alpha: _isExpanded ? 0.4 : 0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: _isExpanded ? 0.14 : 0.07),
                                accent.withValues(alpha: 0.01),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              // Sensor icon
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 1, end: 1.05),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                                builder: (context, double value, child) =>
                                    Transform.scale(
                                      scale: widget.event.status == AlarmRecordStatus.active
                                          ? value
                                          : 1,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                            accent.withValues(alpha: 0.2),
                                            accent.withValues(alpha: 0.1),
                                          ]),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: accent.withValues(alpha: 0.4),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(_sensorIcon, color: accent, size: 20),
                                      ),
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.event.sensorType.hazardLabel.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: accent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 3,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: c.textDim,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            widget.event.sensorType.label,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: c.textSecondary, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_filled_rounded,
                                            color: c.textDim, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          df.format(widget.event.timestamp),
                                          style: TextStyle(
                                            color: c.textSecondary,
                                            fontSize: 10,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _StatusBadge(status: widget.event.status, isAnimated: true),
                                  const SizedBox(height: 6),
                                  _SeverityBadge(
                                      severity: widget.event.severity,
                                      isCritical: isCritical),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Expandable section
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: _isExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Column(
                            children: [
                              Divider(height: 1, color: c.border),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _DataCell(
                                        icon: Icons.device_thermostat,
                                        label: 'TEMP',
                                        value: '${widget.event.temp.toStringAsFixed(1)}°C',
                                        color: widget.event.flags.temp
                                            ? c.temp
                                            : c.textSecondary,
                                        highlighted: widget.event.flags.temp,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _DataCell(
                                        icon: Icons.cloud_rounded,
                                        label: 'SMOKE',
                                        value: '${widget.event.smoke}',
                                        unit: 'ADC',
                                        color: widget.event.flags.smoke
                                            ? c.smoke
                                            : c.textSecondary,
                                        highlighted: widget.event.flags.smoke,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _DataCell(
                                        icon: Icons.whatshot_rounded,
                                        label: 'FLAME',
                                        value: '${widget.event.flame}',
                                        unit: 'ADC',
                                        color: widget.event.flags.flame
                                            ? c.flame
                                            : c.textSecondary,
                                        highlighted: widget.event.flags.flame,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _DataCell(
                                        icon: Icons.sensors_rounded,
                                        label: 'VIB',
                                        value: widget.event.flags.vibration ? 'YES' : 'NO',
                                        color: widget.event.flags.vibration
                                            ? c.vibration
                                            : c.textSecondary,
                                        highlighted: widget.event.flags.vibration,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.numbers_rounded,
                                            size: 12, color: c.textDim),
                                        const SizedBox(width: 4),
                                        Text('Event #${widget.index + 1}',
                                            style: TextStyle(
                                                color: c.textDim, fontSize: 10)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${widget.event.sensorType.label.toUpperCase()} ALERT',
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  // Left accent bar
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accent, accent.withValues(alpha: 0.4)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data cell ─────────────────────────────────────────────────────────────────

class _DataCell extends StatelessWidget {
  const _DataCell({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    required this.color,
    required this.highlighted,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: highlighted
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.06),
          ],
        )
            : null,
        // ── KEY FIX: use c.surface instead of hardcoded AppColors.bg ──
        color: highlighted ? null : c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? color.withValues(alpha: 0.4) : c.border,
          width: highlighted ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 11),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  )),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(unit!,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.5), fontSize: 8)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.isAnimated = false});
  final AlarmRecordStatus status;
  final bool isAnimated;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AlarmRecordStatus.active      => ('ACTIVE',   AppColors.alarm),
      AlarmRecordStatus.acknowledged => ("ACK'D",   AppColors.warmup),
      AlarmRecordStatus.resolved    => ('RESOLVED', AppColors.safe),
    };

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == AlarmRecordStatus.active && isAnimated) ...[
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              )),
        ],
      ),
    );

    if (status == AlarmRecordStatus.active && isAnimated) {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: 1, end: 1.1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, double value, child) =>
            Transform.scale(scale: value, child: child),
        child: badge,
      );
    }
    return badge;
  }
}

// ── Severity badge ────────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity, required this.isCritical});
  final AlarmSeverity severity;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.alarm : AppColors.warmup;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCritical ? Icons.error_rounded : Icons.report_rounded,
          color: color.withValues(alpha: 0.75),
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(severity.name.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
      ],
    );
  }
}