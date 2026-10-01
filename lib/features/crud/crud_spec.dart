import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tone.dart';
import '../../core/utils/export_csv.dart';
import '../../core/utils/formatters.dart';

typedef Doc = Map<String, Object?>;

/// Definición declarativa de un módulo CRUD.
///
/// Es el equivalente Dart de la configuración que se pasaba a
/// `createCrudController(...)` en `js/controllers/crudController.js`.
class CrudSpec {
  const CrudSpec({
    required this.title,
    required this.subtitle,
    required this.loader,
    required this.columns,
    this.fields = const <FieldSpec>[],
    this.filters = const <FilterSpec>[],
    this.rowActions = const <RowActionSpec>[],
    this.allowAdd = true,
    this.bannerText,
    this.bannerTone = Tone.info,
    this.bannerIcon = Icons.info_outline,
    this.autoTimestamp = true,
    this.addValues = const <String, Object?>{},
    this.searchText,
  });

  /// Título del módulo; también se usa para el nombre del archivo CSV.
  final String title;
  final String subtitle;

  /// Carga los datos (con su join si hace falta).
  final Future<List<Doc>> Function(Ref ref) loader;

  final List<ColumnSpec> columns;
  final List<FieldSpec> fields;
  final List<FilterSpec> filters;
  final List<RowActionSpec> rowActions;
  final bool allowAdd;
  final String? bannerText;
  final Tone bannerTone;
  final IconData bannerIcon;

  /// Agrega `createdAt: serverTimestamp()` al crear.
  final bool autoTimestamp;

  /// Valores iniciales del formulario de alta.
  final Map<String, Object?> addValues;

  /// Texto usado por la búsqueda. Por defecto, el JSON de la fila.
  final String Function(Doc row)? searchText;

  String get csvFilename =>
      title.toLowerCase().replaceAll(RegExp(r'\s+'), '-');

  /// Nombre singular para los títulos de los formularios.
  String get singular {
    final t = title.toLowerCase();
    return t.endsWith('s') ? t.substring(0, t.length - 1) : t;
  }
}

/// Columna de la tabla.
class ColumnSpec {
  const ColumnSpec({
    required this.label,
    required this.width,
    required this.cell,
    this.key,
    this.csv,
  });

  /// Nombre del campo en la fila. Se usa como valor por defecto cuando la
  /// celda no necesita un `render` propio y para el fallback de búsqueda.
  final String? key;
  final String label;
  final double width;

  /// Cómo se dibuja la celda.
  final Widget Function(BuildContext context, Doc row) cell;

  /// Valor para el CSV; si es null no se exporta.
  final String Function(Doc row)? csv;
}

/// Campo del formulario (`.field` del CSS).
class FieldSpec {
  const FieldSpec({
    required this.name,
    required this.label,
    this.type = FieldType.text,
    this.options = const <FieldOption>[],
    this.required = false,
    this.hint,
    this.placeholder,
    this.rows = 3,
    this.full = false,
    this.defaultValue,
  });

  final String name;
  final String label;
  final FieldType type;
  final List<FieldOption> options;
  final bool required;
  final String? hint;
  final String? placeholder;
  final int rows;

  /// Ocupa todo el ancho del formulario (`field--full`).
  final bool full;
  final Object? defaultValue;
}

enum FieldType { text, email, number, date, textarea, select, datalist, toggle }

class FieldOption {
  const FieldOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Filtro de la toolbar.
class FilterSpec {
  const FilterSpec({
    required this.key,
    required this.label,
    this.type = FilterType.select,
    this.options = const <FieldOption>[],
    this.match,
  });

  final String key;
  final String label;
  final FilterType type;

  /// Opciones fijas. Si se omite en un filtro tipo select, se derivan de los
  /// datos (mismo comportamiento que `resolveFilters()` del original).
  final List<FieldOption> options;

  /// Predicado custom para el filtro select.
  final bool Function(Doc row, String value)? match;
}

enum FilterType { select, dateRange }

/// Rango de fechas de un filtro.
///
/// `DateTimeRange` de Flutter exige ambos extremos, pero el panel original
/// dejaba los `<input type="date">` del filtro independientes: "solo desde",
/// "solo hasta" o ninguno. Esta clase reproduce ese comportamiento.
class DateFilter {
  const DateFilter({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool get isEmpty => start == null && end == null;
  bool get isNotEmpty => !isEmpty;

  DateFilter copyWith({DateTime? start, DateTime? end, bool clearStart = false, bool clearEnd = false}) {
    return DateFilter(
      start: clearStart ? null : (start ?? this.start),
      end: clearEnd ? null : (end ?? this.end),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DateFilter && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Acción disponible por fila.
class RowActionSpec {
  const RowActionSpec({
    required this.action,
    required this.label,
    this.tone = Tone.secondary,
    this.icon,
    this.title,
    this.visible,
    this.patch,
    this.doneMessage,
  });

  final String action;
  final String label;
  final Tone tone;
  final IconData? icon;
  final String? title;
  final bool Function(Doc row)? visible;

  /// Campos a escribir sobre la fila al ejecutar la acción.
  ///
  /// Cubre el `onRowAction` del panel original sin necesidad de callbacks:
  /// "aprobar" es `{aprobada: true}` y "resolver" es `{estado: 'resuelto'}`.
  final Map<String, Object?>? patch;

  /// Toast de confirmación. Si es null, la acción no avisa.
  final String? doneMessage;
}

/// Estado interno de un módulo: carga, filtros activos y datos.
class CrudState {
  const CrudState({
    this.loading = true,
    this.allRows = const <Doc>[],
    this.filtered = const <Doc>[],
    this.search = '',
    this.selects = const <String, String>{},
    this.dateRanges = const <String, DateFilter>{},
    this.error,
  });

  final bool loading;

  /// Todas las filas del módulo, sin filtrar.
  final List<Doc> allRows;

  /// Subconjunto visible: `allRows` con búsqueda y filtros aplicados.
  final List<Doc> filtered;
  final String search;
  final Map<String, String> selects;
  final Map<String, DateFilter> dateRanges;
  final String? error;

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      selects.values.any((v) => v.isNotEmpty) ||
      dateRanges.values.any((r) => r.isNotEmpty);

  CrudState copyWith({
    bool? loading,
    List<Doc>? allRows,
    List<Doc>? filtered,
    String? search,
    Map<String, String>? selects,
    Map<String, DateFilter>? dateRanges,
    String? error,
  }) {
    return CrudState(
      loading: loading ?? this.loading,
      allRows: allRows ?? this.allRows,
      filtered: filtered ?? this.filtered,
      search: search ?? this.search,
      selects: selects ?? this.selects,
      dateRanges: dateRanges ?? this.dateRanges,
      error: error,
    );
  }
}

/// Controlador genérico del CRUD: carga, filtra y exporta.
///
/// Equivale a `createCrudController` del panel original: los módulos solo
/// aportan su [CrudSpec].
///
/// El provider se crea una sola vez por módulo, en el `State` del
/// [CrudPage] (`crudControllerProvider(spec)`), para que el toolbar y la
/// tabla observen exactamente la misma instancia que esta.
class CrudController extends Notifier<CrudState> {
  CrudController(this.spec);

  final CrudSpec spec;

  @override
  CrudState build() {
    // La carga arranca después del primer build para no setear `state`
    // mientras el notifier todavía se está construyendo.
    Future.microtask(load);
    return const CrudState();
  }

  /// Relee los datos desde Firestore.
  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final rows = await spec.loader(ref);
      // Si el usuario navegó a otro módulo mientras cargaba, el provider de
      // este ya fue disposeado: tocar `state` explota.
      if (!ref.mounted) return;
      _commit(state.copyWith(loading: false, allRows: rows));
    } catch (err) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: err.toString());
    }
  }

  /// Aplica un nuevo término de búsqueda.
  void onSearch(String term) {
    _commit(state.copyWith(search: term));
  }

  /// Aplica un cambio en un filtro tipo select.
  void onSelect(String key, String value) {
    _commit(state.copyWith(selects: <String, String>{...state.selects, key: value}));
  }

  /// Aplica un cambio en uno de los extremos del filtro de fechas.
  void onDateBound(String key, {DateTime? start, DateTime? end, bool clearStart = false, bool clearEnd = false}) {
    final current = state.dateRanges[key] ?? const DateFilter();
    final next = <String, DateFilter>{...state.dateRanges};
    final updated = current.copyWith(
      start: start,
      end: end,
      clearStart: clearStart,
      clearEnd: clearEnd,
    );
    if (updated.isEmpty) {
      next.remove(key);
    } else {
      next[key] = updated;
    }
    _commit(state.copyWith(dateRanges: next));
  }

  /// Limpia todos los filtros activos.
  void resetFilters() {
    _commit(state.copyWith(search: '', selects: const {}, dateRanges: const {}));
  }

  /// Publica el nuevo estado recalculando `filtered` sobre `allRows`.
  void _commit(CrudState next) {
    state = next.copyWith(filtered: _applyFilters(next.allRows, next));
  }

  /// Reproduce la lógica de `applyFilters()` del panel original:
  /// búsqueda de texto libre + filtros select + rangos de fecha.
  List<Doc> _applyFilters(List<Doc> rows, CrudState s) {
    final query = s.search.trim().toLowerCase();
    return rows.where((row) {
      if (query.isNotEmpty && !_matchesSearch(row, query)) return false;

      for (final entry in s.selects.entries) {
        final value = entry.value;
        if (value.isEmpty) continue;
        final filter = spec.filters
            .where((f) => f.key == entry.key)
            .firstOrNull;
        final matcher = filter?.match;
        if (matcher != null) {
          if (!matcher(row, value)) return false;
        } else if ('${row[entry.key] ?? ''}' != value) {
          return false;
        }
      }

      for (final entry in s.dateRanges.entries) {
        final range = entry.value;
        if (range.isEmpty) continue;
        final d = Fmt.toDate(row[entry.key]);
        if (d == null) return false;
        final start = range.start;
        final end = range.end;
        if (start != null && d.isBefore(_startOfDay(start))) return false;
        if (end != null && d.isAfter(_endOfDay(end))) return false;
      }
      return true;
    }).toList();
  }

  bool _matchesSearch(Doc row, String query) {
    if (spec.searchText != null) {
      return spec.searchText!(row).toLowerCase().contains(query);
    }
    return row.toString().toLowerCase().contains(query);
  }

  /// Opciones derivadas de los datos para los filtros sin `options` fijas.
  List<FieldOption> resolveFilterOptions(FilterSpec filter) {
    if (filter.options.isNotEmpty) return filter.options;
    final seen = <String>{};
    final options = <FieldOption>[];
    for (final row in state.allRows) {
      final value = '${row[filter.key] ?? ''}';
      if (value.isEmpty || seen.contains(value)) continue;
      seen.add(value);
      options.add(FieldOption(value: value, label: value));
    }
    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  /// Genera y descarga el CSV de las filas filtradas.
  void exportCsv() {
    final columns = <CsvColumn>[
      for (final c in spec.columns)
        if (c.csv != null) CsvColumn(label: c.label, export: c.csv!),
    ];
    buildCsv(
      filename: spec.csvFilename,
      columns: columns,
      rows: state.filtered,
    );
  }

  static DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 0, 0, 0);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
}

/// Provider de un módulo CRUD.
///
/// Cada [CrudSpec] tiene su propio provider porque Riverpod identifica los
/// providers por identidad: dos módulos con specs distintos nunca comparten
/// estado, aunque el `CrudSpec` sea equivalente.
///
/// Se crea con `isAutoDispose: true` porque la función devuelve una instancia
/// nueva en cada llamada (no es un provider global declarado a nivel de
/// archivo): sin autodispose, cada visita a una página CRUD dejaba el notifier
/// y su `allRows` completo retenidos en el container de por vida. Con
/// autodispose el notifier vive mientras la página lo observa.
NotifierProvider<CrudController, CrudState> crudProviderFor(CrudSpec spec) =>
    NotifierProvider<CrudController, CrudState>(
      () => CrudController(spec),
      isAutoDispose: true,
    );
