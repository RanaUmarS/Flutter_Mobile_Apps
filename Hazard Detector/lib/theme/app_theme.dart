// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

// ── Raw color constants (theme-independent) ───────────────────────────────────
// These are the "DNA" values. Screens should use AppColors.of(context)
// for anything that changes between dark/light, and these constants only
// for sensor/status accents which stay the same in both themes.

class AppColorTokens {
  // Status — identical in both themes
  static const safe       = Color(0xFF00C853);
  static const safeGlow   = Color(0x2200C853);
  static const alarm      = Color(0xFFFF1744);
  static const alarmGlow  = Color(0x44FF1744);
  static const warmup     = Color(0xFFFFAB00);
  static const warmupGlow = Color(0x33FFAB00);

  // Sensors — identical in both themes
  static const temp      = Color(0xFFFF6D00);
  static const humidity  = Color(0xFF29B6F6);
  static const smoke     = Color(0xFF90A4AE);
  static const flame     = Color(0xFFFF3D00);
  static const vibration = Color(0xFFAA00FF);
  static const mono      = Color(0xFF00BFA5); // teal accent
}

// ── Legacy static class — kept for backward compatibility ─────────────────────
// All existing screens that use AppColors.alarm, AppColors.safe etc. keep
// working. Only the surface/text/bg colors are now duplicated here as
// the dark-mode values so old code doesn't break.
class AppColors {
  // ── Core surfaces (dark mode values — screens using AppColors directly
  //    will get dark theme colors; use AppColors.of(context) for adaptive) ──
  static const bg              = Color(0xFF0D0F14);
  static const surface         = Color(0xFF161A22);
  static const surfaceElevated = Color(0xFF1E232E);
  static const border          = Color(0xFF2A3142);

  // Status
  static const safe       = AppColorTokens.safe;
  static const safeGlow   = AppColorTokens.safeGlow;
  static const alarm      = AppColorTokens.alarm;
  static const alarmGlow  = AppColorTokens.alarmGlow;
  static const warmup     = AppColorTokens.warmup;
  static const warmupGlow = AppColorTokens.warmupGlow;

  // Sensors
  static const temp      = AppColorTokens.temp;
  static const humidity  = AppColorTokens.humidity;
  static const smoke     = AppColorTokens.smoke;
  static const flame     = AppColorTokens.flame;
  static const vibration = AppColorTokens.vibration;

  // Text (dark mode values)
  static const textPrimary   = Color(0xFFECEFF1);
  static const textSecondary = Color(0xFF78909C);
  static const textDim       = Color(0xFF455A64);

  // Mono accent
  static const mono = AppColorTokens.mono;

  // ── Adaptive accessor — use this for new/updated screens ─────────────────
  static AppAdaptiveColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _dark  = AppAdaptiveColors._dark();
  static const _light = AppAdaptiveColors._light();
}

// ── Adaptive color set ────────────────────────────────────────────────────────
// Think of this like a CSS variable sheet — one set for dark, one for light.
// The actual widget picks the right one via AppColors.of(context).

class AppAdaptiveColors {
  final Color bg;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDim;

  // Sensor/status colors are the same in both themes
  Color get safe       => AppColorTokens.safe;
  Color get alarm      => AppColorTokens.alarm;
  Color get alarmGlow  => AppColorTokens.alarmGlow;
  Color get warmup     => AppColorTokens.warmup;
  Color get temp       => AppColorTokens.temp;
  Color get smoke      => AppColorTokens.smoke;
  Color get flame      => AppColorTokens.flame;
  Color get vibration  => AppColorTokens.vibration;
  Color get mono       => AppColorTokens.mono;

  const AppAdaptiveColors._dark()
      : bg              = const Color(0xFF0D0F14),
        surface         = const Color(0xFF161A22),
        surfaceElevated = const Color(0xFF1E232E),
        border          = const Color(0xFF2A3142),
        textPrimary     = const Color(0xFFECEFF1),
        textSecondary   = const Color(0xFF78909C),
        textDim         = const Color(0xFF455A64);

  const AppAdaptiveColors._light()
      : bg              = const Color(0xFFF4F6FA),
        surface         = const Color(0xFFFFFFFF),
        surfaceElevated = const Color(0xFFEEF1F7),
        border          = const Color(0xFFD0D7E3),
        textPrimary     = const Color(0xFF0D1117),
        textSecondary   = const Color(0xFF4A5568),
        textDim         = const Color(0xFF9AA5B4);
}

// ── Theme data ────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffold: const Color(0xFF0D0F14),
    surface: const Color(0xFF161A22),
    onSurface: const Color(0xFFECEFF1),
    primary: AppColorTokens.mono,
    secondary: AppColorTokens.safe,
    inputFill: const Color(0xFF1E232E),
    border: const Color(0xFF2A3142),
    textPrimary: const Color(0xFFECEFF1),
    textSecondary: const Color(0xFF78909C),
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffold: const Color(0xFFF4F6FA),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF0D1117),
    primary: const Color(0xFF00897B),   // teal — same family as mono
    secondary: AppColorTokens.safe,
    inputFill: const Color(0xFFEEF1F7),
    border: const Color(0xFFD0D7E3),
    textPrimary: const Color(0xFF0D1117),
    textSecondary: const Color(0xFF4A5568),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color primary,
    required Color secondary,
    required Color inputFill,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: secondary,
        onSecondary: Colors.black,
        error: AppColorTokens.alarm,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      fontFamily: 'monospace',
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
        iconTheme: IconThemeData(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        prefixIconColor: textSecondary,
        hintStyle: TextStyle(color: textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? primary : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.35)
              : border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.15),
        inactiveTrackColor: border,
      ),
      textTheme: TextTheme(
        bodyLarge:   TextStyle(color: textPrimary,   fontFamily: 'monospace'),
        bodyMedium:  TextStyle(color: textSecondary, fontFamily: 'monospace'),
        bodySmall:   TextStyle(color: textSecondary, fontFamily: 'monospace'),
        titleLarge:  TextStyle(color: textPrimary,   fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary,   fontWeight: FontWeight.w600),
        titleSmall:  TextStyle(color: textPrimary,   fontWeight: FontWeight.w600),
        labelLarge:  TextStyle(color: textSecondary),
        labelMedium: TextStyle(color: textSecondary),
      ),
    );
  }
}