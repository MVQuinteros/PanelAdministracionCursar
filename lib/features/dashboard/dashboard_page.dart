import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/theme/tone.dart';
import '../../core/utils/formatters.dart';
import 'dashboard_controller.dart';

/// Dashboard: 6 tarjetas de estadísticas + 4 gráficos.
///
/// Réplica de `dashboardView.js` + `dashboardController.js`. Las cards son
/// clickeables y navegan al módulo correspondiente.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Paleta de los gráficos, equivalente a `CHART_COLORS`.
  static const chartColors = <Color>[
    Color(0xFF007BFF),
    Color(0xFF2EA043),
    Color(0xFFD29922),
    Color(0xFF9C27B0),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF00A0B0),
    Color(0xFF8B949E),
  ];

  /// Orden preferente del gráfico "Ofertas por área" (`AREA_ORDER`).
  static const areaOrder = <String>[
    'Tecnología',
    'Ingeniería',
    'Salud',
    'Educación',
    'Creativa',
    'Administración',
    'Economía',
    'Derecho',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);

    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'No se pudo cargar el dashboard: $err',
          style: TextStyle(color: context.palette.danger),
        ),
      ),
      // El shell entrega una caja acotada; acá se scrollea. La `Column` no
      // tiene hijos flexibles, así que la altura la define el contenido; los
      // `Expanded` de cada gráfico viven adentro de los tiles del `GridView`,
      // que sí tienen alto fijo por `childAspectRatio`.
      data: (d) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatsGrid(data: d),
            const SizedBox(height: 18),
            _Charts(data: d),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final cards = <_StatSpec>[
      _StatSpec(
        label: 'Usuarios registrados',
        value: data.usuarios.length,
        tone: Tone.primary,
        route: '/usuarios',
        sub: '${data.admins} administradores',
      ),
      _StatSpec(
        label: 'Ofertas',
        value: data.ofertas.length,
        tone: Tone.neutral,
        route: '/ofertas',
        sub: '${data.ofertasAprobadas} aprobadas · ${data.ofertasPendientes} pendientes',
      ),
      _StatSpec(
        label: 'Instituciones',
        value: data.instituciones.length,
        tone: Tone.success,
        route: '/instituciones',
        sub: data.institucionesSub,
      ),
      _StatSpec(
        label: 'Test vocacional',
        value: data.resultados.length,
        tone: Tone.purple,
        route: '/test',
        sub: 'resultados registrados',
      ),
      _StatSpec(
        label: 'Avisos',
        value: data.avisos.length,
        tone: Tone.info,
        route: '/avisos',
        sub: '${data.tags.length} tags disponibles',
      ),
      _StatSpec(
        label: 'Soporte sin resolver',
        value: data.soportePendiente,
        tone: Tone.warning,
        route: '/soporte',
        sub: '${data.soporte.length} reportes totales',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 2.35,
          children: [
            for (final c in cards)
              _StatCard(
                spec: c,
                onTap: c.route == null ? null : () => GoRouter.of(context).go(c.route!),
              ),
          ],
        );
      },
    );
  }
}

class _StatSpec {
  const _StatSpec({
    required this.label,
    required this.value,
    required this.tone,
    required this.sub,
    this.route,
  });

  final String label;
  final int value;
  final Tone tone;
  final String sub;
  final String? route;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.spec, required this.onTap});

  final _StatSpec spec;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg) = switch (spec.tone) {
      Tone.success => (p.success, p.successSoft),
      Tone.warning => (p.warning, p.warningSoft),
      Tone.purple => (p.purple, p.purple.withValues(alpha: 0.16)),
      Tone.info => (p.accent, p.accentSoft),
      Tone.neutral => (p.textPrimary, p.bgElevated),
      _ => (p.accent, p.accentSoft),
    };

    return Card(
      color: bg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              if (onTap != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Text(
                    '→',
                    style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    spec.label,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: AppTokens.sm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Fmt.number(spec.value),
                    style: TextStyle(
                      color: fg,
                      fontSize: AppTokens.statValue,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textMuted, fontSize: AppTokens.xs),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    // "Ofertas por área": primero el orden fijo, después el resto por cantidad.
    final areaCounts = countBy(data.ofertas, 'area');
    final ordered = <String, int>{
      for (final a in DashboardPage.areaOrder)
        if (areaCounts.containsKey(a)) a: areaCounts[a]!,
    };
    final rest = sortedCounts(areaCounts)
      ..removeWhere((k, _) => ordered.containsKey(k));
    final areas = <String, int>{...ordered, ...rest};

    final testAreas = sortedCounts(countBy(data.resultados, 'areaInteres'));
    final localidades = sortedCounts(
      countBy(
        data.usuarios.where((u) => '${u['localidad'] ?? ''}'.isNotEmpty).toList(),
        'localidad',
      ),
    );
    final top = localidades.entries.take(8).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return GridView.count(
          crossAxisCount: wide ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          // En una columna el tile tiene todo el ancho del contenido, así que un
          // ratio "apaisado" lo deja tan bajo que la leyenda de la dona se pasa
          // de alto. Acá se le da altura: el GridView va con `shrinkWrap` dentro
          // de un scroll, así que crecer el tile no rompe la página.
          childAspectRatio: wide ? 1.75 : 1.15,
          children: [
            _ChartBox(
              title: 'Ofertas por área',
              subtitle: 'Carreras por área de interés',
              chart: _Doughnut(
                counts: areas,
                palette: DashboardPage.chartColors,
              ),
            ),
            _ChartBox(
              title: 'Ofertas aprobadas vs pendientes',
              chart: _Bar(
                labels: const <String>['Aprobadas', 'Pendientes'],
                values: <int>[
                  data.ofertasAprobadas,
                  data.ofertasPendientes,
                ],
                palette: DashboardPage.chartColors,
              ),
            ),
            _ChartBox(
              title: 'Usuarios por localidad',
              subtitle: 'Top localidades',
              chart: _Bar(
                labels: <String>[for (final e in top) e.key],
                values: <int>[for (final e in top) e.value],
                palette: DashboardPage.chartColors,
              ),
            ),
            _ChartBox(
              title: 'Resultados del test vocacional',
              subtitle: 'Área de interés predominante',
              chart: _Doughnut(
                counts: testAreas,
                palette: DashboardPage.chartColors,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartBox extends StatelessWidget {
  const _ChartBox({
    required this.title,
    required this.chart,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: AppTokens.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: p.textSecondary, fontSize: AppTokens.sm),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }
}

class _Doughnut extends StatelessWidget {
  const _Doughnut({required this.counts, required this.palette});

  final Map<String, int> counts;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entries = counts.entries.toList();
    if (entries.isEmpty) return _Empty('Sin datos para graficar');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 46,
              borderData: FlBorderData(show: false),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: palette[i % palette.length],
                    radius: 26,
                    showTitle: entries.length <= 8,
                    title: '${entries[i].key}\n${entries[i].value}',
                    titleStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Leyenda inferior, equivalente a `legend: {position: 'bottom'}`.
        // `Flexible` + scroll: el alto del tile lo fija el `GridView`, así que
        // con muchas categorías la leyenda se scrollea en vez de desbordar.
        Flexible(
          child: SingleChildScrollView(
            child: _LegendBottom(
              labels: <String>[for (final e in entries) e.key],
              colors: <Color>[
                for (var i = 0; i < entries.length; i++)
                  palette[i % palette.length],
              ],
              textColor: p.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.labels,
    required this.values,
    required this.palette,
  });

  final List<String> labels;
  final List<int> values;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (labels.isEmpty) return _Empty('Sin datos para graficar');

    final maxValue = values.fold<int>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue == 0 ? 4 : maxValue * 1.25,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.borderSubtle, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 58,
                    child: Text(
                      labels[i],
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textSecondary, fontSize: 9.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => p.bgElevated,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${labels[group.x]}\n${rod.toY.round()}',
              TextStyle(color: p.textPrimary, fontSize: AppTokens.sm),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: palette[i % palette.length],
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Leyenda horizontal con wrap, como la de Chart.js en `position: 'bottom'`.
class _LegendBottom extends StatelessWidget {
  const _LegendBottom({
    required this.labels,
    required this.colors,
    required this.textColor,
  });

  final List<String> labels;
  final List<Color> colors;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < labels.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    labels[i],
                    style: TextStyle(color: textColor, fontSize: AppTokens.sm),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: context.palette.textMuted, fontSize: AppTokens.md),
      ),
    );
  }
}
