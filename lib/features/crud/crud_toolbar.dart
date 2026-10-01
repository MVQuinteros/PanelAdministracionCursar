import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/theme/tone.dart';
import '../../core/utils/debounce.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import 'crud_spec.dart';

/// Toolbar del CRUD: búsqueda, filtros y acciones.
///
/// Equivale a `toolbarHTML()` + los binds de `renderToolbar()` del panel
/// original. Recibe el [provider] que creó [CrudPage] y lee el notifier desde
/// ahí, de modo que toolbar y tabla comparten la misma instancia y estado.
class CrudToolbar extends ConsumerStatefulWidget {
  const CrudToolbar({
    super.key,
    required this.spec,
    required this.provider,
    required this.onAdd,
  });

  final CrudSpec spec;
  final NotifierProvider<CrudController, CrudState> provider;
  final VoidCallback onAdd;

  @override
  ConsumerState<CrudToolbar> createState() => _CrudToolbarState();
}

class _CrudToolbarState extends ConsumerState<CrudToolbar> {
  late final Debouncer _debouncer;
  late final TextEditingController _searchText;

  CrudController get _c => ref.read(widget.provider.notifier);

  @override
  void initState() {
    super.initState();
    _searchText = TextEditingController();
    _debouncer = debounce(
      const Duration(milliseconds: 200),
      () => _c.onSearch(_searchText.text),
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = ref.watch(widget.provider);
    final hasFilters = widget.spec.filters.isNotEmpty;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchText,
            onChanged: (_) => _debouncer(),
            decoration: InputDecoration(
              hintText: 'Buscar…',
              prefixIcon: Icon(Icons.search, size: 17, color: p.textSecondary),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
          ),
        ),
        for (final filter in widget.spec.filters) ...[
          if (filter.type == FilterType.select)
            _SelectFilter(
              filter: filter,
              selected: state.selects[filter.key] ?? '',
              options: _c.resolveFilterOptions(filter),
              onChanged: (v) => _c.onSelect(filter.key, v),
            )
          else
            _DateRangeFilter(
              filter: filter,
              value: state.dateRanges[filter.key] ?? const DateFilter(),
              onChanged: ({DateTime? start, DateTime? end, bool clearStart = false, bool clearEnd = false}) =>
                  _c.onDateBound(
                filter.key,
                start: start,
                end: end,
                clearStart: clearStart,
                clearEnd: clearEnd,
              ),
            ),
        ],
        if (hasFilters && state.hasActiveFilters)
          AppButton(
            label: 'Quitar filtros',
            tone: Tone.secondary,
            small: true,
            onPressed: () {
              _searchText.clear();
              _c.resetFilters();
            },
          ),
        if (widget.spec.allowAdd)
          AppButton(
            label: 'Nuevo',
            icon: Icons.add,
            tone: Tone.primary,
            small: true,
            onPressed: widget.onAdd,
          ),
        AppButton(
          label: 'Exportar',
          icon: Icons.download_outlined,
          tone: Tone.secondary,
          small: true,
          onPressed: _c.exportCsv,
        ),
      ],
    );
  }
}

class _SelectFilter extends StatelessWidget {
  const _SelectFilter({
    required this.filter,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final FilterSpec filter;
  final String selected;
  final List<FieldOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // `DropdownButton` asserta si `value` no corresponde a ningún item. Las
    // opciones de un filtro dinámico se derivan de las filas cargadas, así que
    // la selección puede desaparecer al recargar (se borró el último elemento
    // con ese valor). En ese caso mantenemos el valor con una etiqueta de
    // respaldo para no romper la página; el chip sigue reflejando el filtro
    // activo hasta que el usuario lo cambie.
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: '',
        child: Text(
          '${filter.label}: todas',
          style: TextStyle(color: p.textSecondary),
        ),
      ),
      for (final o in options)
        DropdownMenuItem(
          value: o.value,
          child: Text(o.label, overflow: TextOverflow.ellipsis),
        ),
      if (selected.isNotEmpty && !options.any((o) => o.value == selected))
        DropdownMenuItem(
          value: selected,
          child: Text(
            '$selected (sin resultados)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          hint: Text(
            '${filter.label}: todas',
            style: TextStyle(color: p.textSecondary, fontSize: AppTokens.md2),
          ),
          style: TextStyle(color: p.textPrimary, fontSize: AppTokens.md2),
          dropdownColor: p.bgSurface,
          items: items,
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }
}

/// Filtro "Desde … a …".
///
/// Reemplaza los dos `<input type="date">` independientes del original: el
/// diálogo de rango cubre ambos casos y `…` representa el extremo vacío.
class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter({
    required this.filter,
    required this.value,
    required this.onChanged,
  });

  final FilterSpec filter;
  final DateFilter value;
  final void Function({
    DateTime? start,
    DateTime? end,
    bool clearStart,
    bool clearEnd,
  })
  onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value.isEmpty
        ? null
        : DateTimeRange(
            start: value.start ?? now,
            end: value.end ?? now,
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      initialDateRange: initial,
      helpText: filter.label,
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: context.palette.bgSurface,
            headerBackgroundColor: context.palette.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    onChanged(start: picked.start, end: picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final label = value.isEmpty
        ? filter.label
        : '${value.start == null ? '…' : Fmt.date(value.start)} – '
            '${value.end == null ? '…' : Fmt.date(value.end)}';

    return AppButton(
      label: label,
      icon: Icons.date_range_outlined,
      tone: value.isNotEmpty ? Tone.info : Tone.secondary,
      small: true,
      onPressed: () => _pick(context),
    );
  }
}
