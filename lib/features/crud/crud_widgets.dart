import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/utils/open_url.dart';

/// Celdas de tabla reutilizables.
///
/// Reemplazan a los `render(row)` del panel original, que devolvían HTML.
/// Ahora devuelven widgets, lo que además permite componer (por ejemplo, un
/// `Badge` al lado de un texto atenuado).

/// Texto en negrita (`.cell-strong`).
class StrongText extends StatelessWidget {
  const StrongText(this.text, {super.key, this.maxLines = 1});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: AppTokens.md,
        fontWeight: FontWeight.w600,
        color: context.palette.textPrimary,
      ),
    );
  }
}

/// Texto atenuado (`.cell-muted`).
class MutedText extends StatelessWidget {
  const MutedText(this.text, {super.key, this.maxLines = 1, this.fontSize});

  final String text;
  final int maxLines;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize ?? AppTokens.md,
        color: context.palette.textSecondary,
      ),
    );
  }
}

/// Texto con `title` para el tooltip al hacer hover (truncado con ellipsis).
class TruncatedText extends StatelessWidget {
  const TruncatedText(this.text, {super.key, this.maxWidth});

  final String text;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: SizedBox(
        width: maxWidth,
        child: MutedText(text),
      ),
    );
  }
}

/// Link externo truncado, como la columna "Link" de los avisos.
class ExternalLinkText extends StatelessWidget {
  const ExternalLinkText(this.url, {super.key});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const MutedText('—');
    }
    return Tooltip(
      message: url!,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          url!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppTokens.md,
            color: context.palette.accent,
          ),
        ),
      ),
    );
  }
}

/// Celda del identificador oficial (CUE / SPU / dependencia).
///
/// Si hay [url], el texto es un link que abre el registro oficial en otra
/// pestaña (`SITRARED` para el CUE, el listado del SPU para universidades). Si
/// no, se muestra como texto atenuado: la dependencia de una sede no verifica
/// nada, solo informa.
class VerifyLinkCell extends StatelessWidget {
  const VerifyLinkCell({
    super.key,
    required this.label,
    this.url,
    this.esCodigo = false,
  });

  final String label;
  final String? url;

  /// `true` cuando [label] es un código (CUE): se muestra monoespaciado para
  /// distinguirlo del nombre de una institución madre.
  final bool esCodigo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (url == null || url!.isEmpty) {
      return MutedText(label);
    }

    return Tooltip(
      message: 'Ver en el registro oficial',
      child: InkWell(
        onTap: () => openUrl(url!),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTokens.md,
                  fontWeight: esCodigo ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: esCodigo ? 'monospace' : null,
                  letterSpacing: esCodigo ? 0.5 : 0,
                  color: p.accent,
                  decoration: TextDecoration.underline,
                  decorationColor: p.accent.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(Icons.open_in_new, size: 13, color: p.accent),
          ],
        ),
      ),
    );
  }
}
