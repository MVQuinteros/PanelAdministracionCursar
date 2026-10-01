import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/cursar_palette.dart';
import '../theme/tone.dart';

/// Banner informativo de módulo (`.banner--info` / `.banner--warning`).
///
/// Se llama `InfoBanner` para no chocar con el `Banner` de Material.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    this.tone = Tone.info,
    this.icon = Icons.info_outline,
  });

  final String text;
  final Tone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // El CSS usa colores claros legibles sobre el fondo tintado en tema
    // oscuro, y el propio color de marca en tema claro.
    final Color fg = switch (tone) {
      Tone.warning => isLight
          ? const Color(0xFF996F10)
          : CursarPalette.darkWarningBanner,
      _ => isLight ? const Color(0xFF1E7CE8) : CursarPalette.darkInfoBanner,
    };
    final Color border = tone.fg(p).withValues(alpha: 0.35);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tone.bg(p),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontSize: AppTokens.md, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección con la barrita de acento (`.view-head::before`).
class ViewHead extends StatelessWidget {
  const ViewHead(this.subtitle, {super.key});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: AppTokens.md,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
