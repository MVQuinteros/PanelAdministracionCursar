import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/theme/tone.dart';
import 'crud_spec.dart';

/// Tabla del CRUD: header fijo arriba y scroll vertical en el cuerpo.
///
/// Reemplaza al `<table>` con `thead { position: sticky }` del CSS. El ancho
/// de cada columna viene de [ColumnSpec.width]; si la suma no entra, la tabla
/// scrollea horizontalmente. El header y el cuerpo usan [ScrollController]
/// horizontales separados —un [ScrollController] no puede atender varias
/// posiciones a la vez— y el offset del cuerpo se copia al header para que las
/// columnas nunca se desalineen.
class CrudTable extends StatefulWidget {
  const CrudTable({
    super.key,
    required this.spec,
    required this.rows,
    required this.onAction,
  });

  final CrudSpec spec;
  final List<Doc> rows;
  final void Function(String action, Doc row) onAction;

  @override
  State<CrudTable> createState() => _CrudTableState();
}

class _CrudTableState extends State<CrudTable> {
  final _headerHorizontal = ScrollController();
  final _bodyHorizontal = ScrollController();
  final _vertical = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyHorizontal.addListener(_syncHeaderHorizontal);
  }

  void _syncHeaderHorizontal() {
    if (_headerHorizontal.hasClients && _bodyHorizontal.hasClients) {
      final offset = _bodyHorizontal.offset;
      if ((_headerHorizontal.offset - offset).abs() > 0.01) {
        _headerHorizontal.jumpTo(offset);
      }
    }
  }

  @override
  void dispose() {
    _bodyHorizontal.removeListener(_syncHeaderHorizontal);
    _headerHorizontal.dispose();
    _bodyHorizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spec = widget.spec;
    final hasActions = spec.rowActions.isNotEmpty;

    final actionsWidth = hasActions
        ? spec.rowActions
                .map((a) => _buttonWidth(a))
                .fold<double>(0, (sum, w) => sum + w) +
            12.0
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: p.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // La tabla nunca es más angosta que el viewport: así el fondo y los
          // bordes de fila cubren todo el ancho disponible.
          final natural =
              spec.columns.fold<double>(0, (sum, c) => sum + c.width) +
                  actionsWidth +
                  (hasActions ? 24 : 0);
          final tableWidth = natural < constraints.maxWidth
              ? constraints.maxWidth
              : natural;

          return Column(
            children: [
              // Header fijo, con scroll horizontal compartido.
              Container(
                color: p.bgElevated,
                child: SingleChildScrollView(
                  controller: _headerHorizontal,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: tableWidth,
                    child: Row(
                      children: [
                        for (final c in spec.columns)
                          SizedBox(
                            width: c.width,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                              child: Text(
                                c.label.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTokens.xs,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w600,
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                          ),
                        if (hasActions)
                          SizedBox(
                            width: actionsWidth + 12,
                            child: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: p.borderSubtle),
              // Cuerpo: scroll vertical propio y horizontal propio, este
              // último sincronizado con el del header.
              Expanded(
                child: Scrollbar(
                  controller: _vertical,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _vertical,
                    child: SingleChildScrollView(
                      controller: _bodyHorizontal,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            for (var i = 0; i < widget.rows.length; i++)
                              _Row(
                                spec: spec,
                                row: widget.rows[i],
                                striped: i.isOdd,
                                actionsWidth: actionsWidth,
                                hasActions: hasActions,
                                onAction: widget.onAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static double _buttonWidth(RowActionSpec a) {
    // Aproximación: texto + padding + icono.
    return 20 + a.label.length * 6.6 + (a.icon != null ? 20 : 0);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.spec,
    required this.row,
    required this.striped,
    required this.actionsWidth,
    required this.hasActions,
    required this.onAction,
  });

  final CrudSpec spec;
  final Doc row;
  final bool striped;
  final double actionsWidth;
  final bool hasActions;
  final void Function(String action, Doc row) onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final actions = spec.rowActions
        .where((a) => a.visible == null || a.visible!(row))
        .toList();

    final showActions = hasActions && actions.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: striped ? p.bgElevated.withValues(alpha: 0.25) : null,
        border: Border(
          bottom: BorderSide(
            color: p.borderSubtle.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final c in spec.columns)
              SizedBox(
                width: c.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: c.cell(context, row),
                  ),
                ),
              ),
            if (hasActions)
              SizedBox(
                width: actionsWidth + 24,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: showActions
                        ? Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            alignment: WrapAlignment.end,
                            children: [
                              for (final a in actions)
                                _ActionButton(
                                  spec: a,
                                  onTap: () => onAction(a.action, row),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.spec, required this.onTap});

  final RowActionSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg) = switch (spec.tone) {
      Tone.primary => (Colors.white, p.accent),
      Tone.danger => (p.danger, p.dangerSoft),
      Tone.success => (p.success, p.successSoft),
      Tone.warning => (p.warning, p.warningSoft),
      _ => (p.textPrimary, p.bgElevated),
    };

    return Tooltip(
      message: spec.title ?? spec.label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (spec.icon != null) ...[
                  Icon(spec.icon, size: 13, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  spec.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
