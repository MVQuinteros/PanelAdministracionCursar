import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/theme/tone.dart';
import 'crud_spec.dart';

/// Tabla del CRUD: header fijo arriba, scroll vertical en el cuerpo y barra
/// de scroll horizontal al pie.
///
/// Reemplaza al `<table>` con `thead { position: sticky }` del CSS. El ancho
/// de cada columna viene de [ColumnSpec.width], pero es un ancho *deseado*: si
/// la suma no entra en el viewport, las columnas se achican en proporción a lo
/// que pueden ceder (ver [_columnWidths]) para que la última —Acciones, con
/// "Responder" / "Editar" / "Eliminar"— nunca quede fuera de la pantalla. Si ni
/// achicando las columnas entra (Ofertas: 8 columnas más 4 botones), se recorta
/// el ancho reservado a Acciones y los botones que sobran bajan de línea (ver
/// [_actionsArea]). El scroll horizontal queda solo como último recurso, cuando
/// ni el ancho mínimo por columna entra.
///
/// El header y el cuerpo usan [ScrollController] horizontales separados —un
/// [ScrollController] no puede atender varias posiciones a la vez— y el offset
/// del cuerpo se copia al header para que las columnas nunca se desalineen.
///
/// La barra horizontal comparte el controller del cuerpo ([_bodyHorizontal]),
/// que está adjunto a un único scroll, así que no dispara el assert de
/// "múltiples ScrollPosition". Va fuera del `Expanded` del scroll vertical a
/// propósito: si viviera adentro, se iría con las filas.
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

    // Ancho "natural" de la columna de Acciones: todos los botones de una fila
    // en una sola línea. Más abajo puede recortarse (ver [_actionsArea]).
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
          // Las tablas de este panel tienen más columnas de las que entran en
          // un monitor común: Soporte son 1180 px de columnas + ~310 de la de
          // Acciones contra ~1070 disponibles en un 1366. Eso empujaba la
          // columna de Acciones fuera de la pantalla y "Responder" quedaba
          // inalcanzable. Ahora se achican las columnas para que todo entre; el
          // scroll horizontal queda solo cuando ni el mínimo entra.
          final actionsArea = _actionsArea(
            columns: spec.columns,
            actions: spec.rowActions,
            naturalWidth: actionsWidth,
            maxWidth: constraints.maxWidth,
          );
          final columnWidths =
              _columnWidths(spec.columns, constraints.maxWidth - actionsArea) ??
                  <double>[for (final c in spec.columns) c.width];

          final natural =
              columnWidths.fold<double>(0, (sum, w) => sum + w) + actionsArea;
          final tableWidth = natural < constraints.maxWidth
              ? constraints.maxWidth
              : natural;

          // La barra horizontal solo se dibuja si la tabla realmente es más
          // ancha que el viewport. En Tags o Test vocacional, que entran
          // justos, una barra inmóvil sería ruido. La tolerancia evita que un
          // residuo de coma flotante (1e-13) haga aparecer la barra de más.
          final needsHorizontalScroll = natural > constraints.maxWidth + 0.5;

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
                        for (var i = 0; i < spec.columns.length; i++)
                          SizedBox(
                            width: columnWidths[i],
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                              child: Text(
                                spec.columns[i].label.toUpperCase(),
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
                            // El header no lleva el padding derecho de la fila,
                            // por eso reserva 12 px menos.
                            width: actionsArea - 12,
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
                                columnWidths: columnWidths,
                                row: widget.rows[i],
                                striped: i.isOdd,
                                actionsArea: actionsArea,
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
              // Barra horizontal, fija al pie de la tabla. Comparte
              // `_bodyHorizontal`, así que arrastrarla mueve el cuerpo y, por
              // el listener, también el header.
              //
              // El texto no es decorativo: cuando la tabla no entra, las
              // columnas de la derecha (incluida Acciones, con Responder /
              // Editar / Eliminar) quedan fuera de la pantalla, y la barra
              // sola pasaba desapercibida.
              if (needsHorizontalScroll) ...[
                Divider(height: 1, color: p.borderSubtle),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 15,
                        color: p.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Hay más columnas a la derecha: arrastrá la tabla',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTokens.xs,
                            color: p.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // El ancho explícito no es decorativo: dentro de una
                      // `Row` un `SizedBox` sin width colapsa a 0 px y la barra
                      // deja de recibir los drags del mouse.
                      SizedBox(
                        width: 220,
                        child: Scrollbar(
                          controller: _bodyHorizontal,
                          thumbVisibility: true,
                          // Sin esto la barra no se puede arrastrar con el
                          // mouse, que en web es la mitad de la razón de
                          // existir.
                          interactive: true,
                          child: const SizedBox(height: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  /// Ancho a reservar para la columna de Acciones en un viewport de [maxWidth].
  ///
  /// [naturalWidth] es lo que piden todos los botones de una fila en una sola
  /// línea. Si con eso las columnas todavía llegan a su mínimo, se reserva
  /// entero (es lo que pasa en todos los módulos menos Ofertas). Si no, se
  /// reserva lo justo para que las columnas entren —[maxWidth] menos sus
  /// mínimos— y en el peor caso el ancho de dos botones, para que los que
  /// sobran bajen de línea en vez de quedar fuera de la pantalla.
  static double _actionsArea({
    required List<ColumnSpec> columns,
    required List<RowActionSpec> actions,
    required double naturalWidth,
    required double maxWidth,
  }) {
    if (actions.isEmpty) return 0;

    final natural = naturalWidth + 24;
    final room = maxWidth - _floorsTotal(columns);
    if (room >= natural) return natural;

    return math.max(_wrappedActionsArea(actions), room);
  }

  /// Ancho mínimo para que los botones de Acciones puedan bajar de línea sin
  /// recortarse: los dos más anchos —que son los que definen el ancho de una
  /// línea— más el espaciado del `Wrap` y los paddings de la celda.
  static double _wrappedActionsArea(List<RowActionSpec> actions) {
    final widths = <double>[for (final a in actions) _buttonWidth(a)]..sort();
    final take = math.min(2, widths.length);

    var buttons = 0.0;
    for (var i = 0; i < take; i++) {
      buttons += widths[widths.length - 1 - i];
    }

    return buttons + (take > 1 ? 6 : 0) + 12 + 24;
  }

  /// Ancho mínimo de una columna antes de preferir el scroll horizontal: en
  /// 92 px entran un badge de estado o una fecha sin partirse.
  static const double _minColumnWidth = 92;

  /// Piso de una columna: las más angostas que [_minColumnWidth] no ceden nada
  /// (bajar de ahí parte el badge o la fecha).
  static double _floor(ColumnSpec c) =>
      c.width < _minColumnWidth ? c.width : _minColumnWidth;

  static double _floorsTotal(List<ColumnSpec> columns) =>
      columns.fold<double>(0, (sum, c) => sum + _floor(c));

  /// Reparte [available] entre las columnas cuando no entran.
  ///
  /// Cada una arranca en su mínimo ([_minColumnWidth]) y lo que sobra se
  /// reparte en proporción a lo que esa columna puede ceder, así el ancho
  /// extra va a las anchas (mensaje) y no a las cortas (estado). Devuelve
  /// `null` si los anchos declarados ya entran (se usan tal cual, con el
  /// sobrante como espacio libre) o si ni los mínimos entran, donde conviene
  /// el scroll horizontal de siempre.
  static List<double>? _columnWidths(List<ColumnSpec> columns, double available) {
    final declared = columns.fold<double>(0, (sum, c) => sum + c.width);
    if (declared <= available) return null;

    final floors = <double>[for (final c in columns) _floor(c)];
    final floorsTotal = _floorsTotal(columns);
    if (floorsTotal > available) return null;

    final give = <double>[
      for (var i = 0; i < columns.length; i++)
        columns[i].width > floors[i] ? columns[i].width - floors[i] : 0,
    ];
    final giveTotal = give.fold<double>(0, (sum, w) => sum + w);
    final slack = available - floorsTotal;

    return <double>[
      for (var i = 0; i < columns.length; i++)
        floors[i] + (giveTotal == 0 ? 0 : slack * give[i] / giveTotal),
    ];
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.spec,
    required this.columnWidths,
    required this.row,
    required this.striped,
    required this.actionsArea,
    required this.hasActions,
    required this.onAction,
  });

  final CrudSpec spec;

  /// Ancho ya resuelto de cada columna de [spec], en el mismo orden.
  final List<double> columnWidths;
  final Doc row;
  final bool striped;

  /// Ancho de la celda de Acciones (ya recortado si hacía falta).
  final double actionsArea;
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
            for (var i = 0; i < spec.columns.length; i++)
              SizedBox(
                width: columnWidths[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: spec.columns[i].cell(context, row),
                  ),
                ),
              ),
            if (hasActions)
              SizedBox(
                width: actionsArea,
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
                // `Flexible` + ellipsis: si la celda de Acciones quedó angosta
                // (o el navegador usa un zoom alto), el rótulo se recorta en vez
                // de desbordar la fila.
                Flexible(
                  child: Text(
                    spec.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
