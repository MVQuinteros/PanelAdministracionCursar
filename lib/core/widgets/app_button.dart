import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/cursar_palette.dart';
import '../theme/tone.dart';

/// Botón del panel, equivalente a la clase `.btn` del CSS con sus variantes.
///
/// Tonos: primary (relleno), secondary (elevado), danger, success, warning,
/// outline, link. Tamaños: normal y `btn--sm`.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tone = Tone.primary,
    this.icon,
    this.small = false,
    this.block = false,
    this.tooltip,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.small = false,
    this.block = false,
    this.tooltip,
  }) : tone = Tone.primary;

  final String label;
  final VoidCallback? onPressed;
  final Tone tone;
  final IconData? icon;
  final bool small;
  final bool block;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(AppTokens.radiusSm);

    final Color fg;
    final Color bg;
    BoxBorder? border;

    switch (tone) {
      case Tone.primary:
        fg = Colors.white;
        bg = p.accent;
      case Tone.secondary:
        fg = p.textPrimary;
        bg = p.bgElevated;
        border = Border.all(color: p.borderSubtle);
      case Tone.danger:
        fg = p.danger;
        bg = p.dangerSoft;
      case Tone.success:
        fg = p.success;
        bg = p.successSoft;
      case Tone.warning:
        fg = p.warning;
        bg = p.warningSoft;
      case Tone.purple:
        fg = p.purple;
        bg = p.purple.withValues(alpha: 0.16);
      case Tone.info:
        fg = p.accent;
        bg = p.accentSoft;
      case Tone.neutral:
        fg = p.textSecondary;
        bg = p.bgElevated;
      case Tone.outline:
        fg = p.textPrimary;
        bg = Colors.transparent;
        border = Border.all(color: p.borderStrong);
      case Tone.link:
        fg = p.accent;
        bg = Colors.transparent;
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: small ? 13 : 14, color: fg),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: small ? 12 : AppTokens.md2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    Widget button = Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: border,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 10 : 14,
              vertical: small ? 5 : 8,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (!enabled) {
      button = Opacity(opacity: 0.55, child: IgnorePointer(child: button));
    }
    if (block) {
      button = SizedBox(width: double.infinity, child: button);
    }
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
