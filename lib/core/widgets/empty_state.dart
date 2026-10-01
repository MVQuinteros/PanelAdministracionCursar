import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/cursar_palette.dart';

/// Estado vacío de las tablas (`.empty` del CSS).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.description_outlined,
    this.title = 'Sin datos',
    this.text = 'Todavía no hay registros para mostrar.',
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: p.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, fontSize: AppTokens.md),
          ),
        ],
      ),
    );
  }
}

/// Spinner inline con el texto "Cargando datos…".
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key, this.label = 'Cargando datos…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: p.textSecondary)),
          ],
        ),
      ),
    );
  }
}
