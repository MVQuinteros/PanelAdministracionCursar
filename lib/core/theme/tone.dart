import 'package:flutter/material.dart';

import 'cursar_palette.dart';

/// Tonos semánticos del panel.
///
/// Viven acá (y no en `widgets/badge.dart`) porque los usan tanto los badges
/// como los banners, los botones y los gráficos del dashboard.
enum Tone {
  primary,
  secondary,
  neutral,
  info,
  success,
  warning,
  danger,
  purple,
  outline,
  link,
}

extension ToneX on Tone {
  /// Color del texto.
  Color fg(CursarPalette p) => switch (this) {
    Tone.primary => Colors.white,
    Tone.secondary => p.accent,
    Tone.neutral => p.textSecondary,
    Tone.info => p.accent,
    Tone.success => p.success,
    Tone.warning => p.warning,
    Tone.danger => p.danger,
    Tone.purple => p.purple,
    Tone.outline => p.textSecondary,
    Tone.link => p.accent,
  };

  /// Color de fondo tintado.
  Color bg(CursarPalette p) => switch (this) {
    Tone.primary => p.accent,
    Tone.secondary => p.accentSoft,
    Tone.neutral => p.bgElevated,
    Tone.info => p.accentSoft,
    Tone.success => p.successSoft,
    Tone.warning => p.warningSoft,
    Tone.danger => p.dangerSoft,
    Tone.purple => p.purple.withValues(alpha: 0.16),
    Tone.outline => Colors.transparent,
    Tone.link => Colors.transparent,
  };
}
