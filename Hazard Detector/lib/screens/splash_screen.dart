
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';

// ── Splash-local palette (extends AppColors with icon-matched accents) ────────
class _SC {
  static const bg         = Color(0xFF080A0F);  // deeper than AppColors.bg
  static const siren      = Color(0xFFFF1744);  // minion siren red
  static const sirenGlow  = Color(0x55FF1744);
  static const amber      = Color(0xFFFFAB00);  // minion body yellow-amber
  static const amberDim   = Color(0x33FFAB00);
  static const steel      = Color(0xFF1C2333);  // overall denim/steel
  static const gridLine   = Color(0xFF0F1520);
  static const scanLine   = Color(0x22FF1744);
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animation controllers ────────────────────────────────────────────────
  late final AnimationController _entryCtrl;   // one-shot: logo + text reveal
  late final AnimationController _sirenCtrl;   // looping: siren ring pulse
  late final AnimationController _scanCtrl;    // looping: radar scan line

  // Entry animations
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _ringScale;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _badgeFade;

  // How long the splash stays visible minimum, and max wait for data load
  static const _minDisplay  = Duration(milliseconds: 4000);
  static const _maxLoadWait = Duration(milliseconds: 5500);

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _sirenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // Logo fades in 0–30% of entry
    _logoFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );

    // Logo scales up from 0.88 → 1.0 in 0–40%
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
      ),
    );

    // Outer ring expands from 0.7 → 1.0 slightly after logo
    _ringScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.08, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // Title slides up + fades 30–70%
    _textFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.30, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle 58–90%
    _subtitleFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.58, 0.90, curve: Curves.easeOut),
    );

    // Status badge 75–100%
    _badgeFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _entryCtrl.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.wait([
      Future.delayed(_minDisplay),
      _waitForLoad(),
    ]);
    if (!mounted) return;
    final alarmState = ref.read(alarmServiceProvider);
    context.go(alarmState.hasActiveAlarm ? '/alarm' : '/dashboard');
  }

  Future<void> _waitForLoad() async {
    final deadline = DateTime.now().add(_maxLoadWait);
    while (mounted) {
      if (ref.read(alarmServiceProvider).loaded) return;
      if (DateTime.now().isAfter(deadline)) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _sirenCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _SC.bg,
      body: Stack(
        children: [
          // ── Background: dark grid texture (industrial feel) ──────────────
          const _GridBackground(),

          // ── Radial background glow (siren-red, pulses with siren) ────────
          AnimatedBuilder(
            animation: _sirenCtrl,
            builder: (_, __) {
              final glow = 0.18 + (_sirenCtrl.value * 0.14);
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.75,
                    colors: [
                      _SC.siren.withValues(alpha: glow),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Scan line sweep (radar / megaphone sweep effect) ─────────────
          AnimatedBuilder(
            animation: _scanCtrl,
            builder: (_, __) {
              final y = _scanCtrl.value * size.height;
              return Positioned(
                top: y - 1,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _SC.siren.withValues(alpha: 0.04),
                        _SC.siren.withValues(alpha: 0.08),
                        _SC.siren.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo with pulsing siren rings ──────────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _logoFade, _logoScale, _ringScale, _sirenCtrl,
                    ]),
                    builder: (_, __) {
                      final sirenAlpha = 0.3 + (_sirenCtrl.value * 0.4);
                      final ringAlpha  = 0.12 + (_sirenCtrl.value * 0.12);

                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outermost diffuse glow ring
                                Transform.scale(
                                  scale: _ringScale.value,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _SC.siren.withValues(alpha: sirenAlpha * 0.5),
                                          blurRadius: 60,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Outer dashed-style ring (segmented arc look)
                                Transform.scale(
                                  scale: _ringScale.value,
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _SC.siren.withValues(alpha: ringAlpha * 1.5),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // Inner ring — tighter, brighter
                                Transform.scale(
                                  scale: _ringScale.value,
                                  child: Container(
                                    width: 148,
                                    height: 148,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _SC.siren.withValues(alpha: ringAlpha * 2.5),
                                        width: 1,
                                      ),
                                      gradient: RadialGradient(
                                        colors: [
                                          _SC.siren.withValues(alpha: ringAlpha * 0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Icon itself — no clip, black bg blends with dark bg
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Image.asset(
                                    'assets/icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // ── Title ─────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge([_textFade, _textSlide]),
                    builder: (_, __) {
                      return Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Column(
                            children: [
                              // "HAZARD" in amber — minion yellow
                              Text(
                                'HAZARD',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                  color: _SC.amber,
                                  fontFamily: 'monospace',
                                  shadows: [
                                    Shadow(
                                      color: _SC.amber.withValues(alpha: 0.6),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              // "DETECTOR" in white — the alarm
                              Text(
                                'DETECTOR',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 10,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── Subtitle ──────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _subtitleFade,
                    builder: (_, __) {
                      return Opacity(
                        opacity: _subtitleFade.value,
                        child: const Text(
                          'Multi Hazard Detection System',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 52),

                  // ── Status badge + loading bar ─────────────────────────
                  AnimatedBuilder(
                    animation: _badgeFade,
                    builder: (_, __) {
                      return Opacity(
                        opacity: _badgeFade.value,
                        child: const _BootSequence(),
                      );
                    },
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

// ── Grid background ───────────────────────────────────────────────────────────
// Looks like industrial steel grating — nods to the minion's overall texture

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _SC.gridLine
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ── Boot sequence widget ──────────────────────────────────────────────────────
// Terminal-style loading lines — like a system initializing.
// Animates line by line, then shows a pulsing "SYSTEM ONLINE" badge.

class _BootSequence extends StatefulWidget {
  const _BootSequence();

  @override
  State<_BootSequence> createState() => _BootSequenceState();
}

class _BootSequenceState extends State<_BootSequence> {
  static const _lines = [
    'INITIALIZING SENSORS...',
    'CALIBRATING THRESHOLDS...',
    'CONNECTING TO MONITOR...',
  ];

  int _visibleLines = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_visibleLines < _lines.length) _visibleLines++;
        else t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Boot lines
        SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_lines.length, (i) {
              final visible = i < _visibleLines;
              return AnimatedOpacity(
                opacity: visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Text(
                        '> ',
                        style: TextStyle(
                          color: _SC.siren,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _lines[i],
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (visible && i == _visibleLines - 1 && _visibleLines < _lines.length)
                        _BlinkingCursor(),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 20),

        // Loading bar
        SizedBox(
          width: 300,
          child: _AnimatedLoadBar(lineCount: _visibleLines, total: _lines.length),
        ),
      ],
    );
  }
}

// ── Animated load bar ─────────────────────────────────────────────────────────

class _AnimatedLoadBar extends StatelessWidget {
  const _AnimatedLoadBar({required this.lineCount, required this.total});
  final int lineCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : lineCount / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SYSTEM BOOT',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 9,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: lineCount == total ? _SC.amber : _SC.siren,
                fontSize: 9,
                letterSpacing: 1,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 2,
            color: _SC.steel,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_SC.siren, _SC.amber],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _SC.siren.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Blinking cursor ───────────────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value,
        child: const Text(
          '█',
          style: TextStyle(
            color: _SC.siren,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}