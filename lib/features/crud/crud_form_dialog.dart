import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/utils/formatters.dart';
import 'crud_spec.dart';

/// Formulario modal genérico, construido desde una lista de [FieldSpec].
///
/// Sustituye a `formHTML()` + `readForm()` del panel original.
class CrudFormDialog extends StatefulWidget {
  const CrudFormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.initialValues,
    required this.onSubmit,
  });

  final String title;
  final List<FieldSpec> fields;
  final Map<String, Object?> initialValues;
  final Future<void> Function(Map<String, Object?> values) onSubmit;

  @override
  State<CrudFormDialog> createState() => _CrudFormDialogState();
}

class _CrudFormDialogState extends State<CrudFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _toggles;

  /// Solo para los campos `datalist`: `RawAutocomplete` asserta que
  /// `focusNode` y `textEditingController` vayan juntos o ninguno de los dos.
  late final Map<String, FocusNode> _focusNodes;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = <String, TextEditingController>{};
    _toggles = <String, bool>{};
    _focusNodes = <String, FocusNode>{};

    for (final f in widget.fields) {
      if (f.type == FieldType.datalist) {
        _focusNodes[f.name] = FocusNode();
      }
      if (f.type == FieldType.toggle) {
        _toggles[f.name] = widget.initialValues[f.name] == true;
        // El controller se crea igual: `_Field` lo toma siempre como no-null.
        _controllers[f.name] = TextEditingController();
        continue;
      }
      final raw = widget.initialValues[f.name];
      String text;
      if (raw == null) {
        text = '';
      } else {
        // Normaliza Timestamp / ISO string a `yyyy-MM-dd` para los campos de
        // fecha, y deja el resto tal cual.
        final date = f.type == FieldType.date ? Fmt.toDate(raw) : null;
        text = date != null ? _isoDate(date) : raw.toString();
      }
      _controllers[f.name] = TextEditingController(text: text);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _setToggle(String name, bool value) {
    setState(() => _toggles[name] = value);
  }

  /// Lee el formulario (equivalente a `readForm`).
  Map<String, Object?> _read() {
    final data = <String, Object?>{};
    for (final f in widget.fields) {
      switch (f.type) {
        case FieldType.toggle:
          data[f.name] = _toggles[f.name] ?? false;
        case FieldType.number:
          final text = _controllers[f.name]!.text.trim();
          data[f.name] = text.isEmpty ? '' : num.tryParse(text);
        case FieldType.date:
          final text = _controllers[f.name]!.text.trim();
          if (text.isEmpty) {
            data[f.name] = '';
          } else {
            final parsed = DateTime.tryParse(text);
            data[f.name] = parsed == null
                ? text
                : DateTime(parsed.year, parsed.month, parsed.day);
          }
        default:
          data[f.name] = _controllers[f.name]!.text.trim();
      }
    }
    return data;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_read());
    } catch (err) {
      // Los errores de Firestore se muestran acá: el diálogo sigue abierto con
      // los valores que ya había cargado el usuario.
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'No se pudo guardar: $err';
        });
      }
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: context.palette.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(title: widget.title),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: _FieldGrid(fields: widget.fields, state: this),
                ),
              ),
            ),
            if (_error case final message?)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.palette.dangerSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: context.palette.danger,
                    fontSize: AppTokens.sm,
                  ),
                ),
              ),
            _Footer(
              submitLabel: 'Guardar',
              busy: _busy,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppTokens.xl,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            color: p.textSecondary,
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.submitLabel,
    required this.busy,
    required this.onCancel,
    required this.onSubmit,
  });

  final String submitLabel;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        // `Wrap` y no `Row`: con dos botones, en pantallas de menos de ~360px
        // el `Row` se sale del diálogo ("overflowed by 43 pixels on the
        // right"). Envuelto, los botones pasan a la línea de abajo en vez de
        // desbordar. En pantallas anchas queda igual que antes.
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: busy ? null : onCancel,
            child: Text('Cancelar', style: TextStyle(color: p.textSecondary)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(submitLabel),
          ),
        ],
      ),
    );
  }
}

/// Grid responsive de campos (`.form-grid` con `minmax(220px, 1fr)`).
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.fields, required this.state});

  final List<FieldSpec> fields;
  final _CrudFormDialogState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Una columna en móvil, dos en desktop: mismo criterio que el CSS.
        final columns = constraints.maxWidth > 480 ? 2 : 1;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final f in fields)
              SizedBox(
                width: f.full || columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 14) / 2,
                child: _Field(spec: f, state: state),
              ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.spec, required this.state});

  final FieldSpec spec;
  final _CrudFormDialogState state;

  String? _validate(String? v) {
    if (spec.required && (v == null || v.trim().isEmpty)) {
      return 'Campo obligatorio.';
    }
    if (spec.type == FieldType.email &&
        v != null &&
        v.trim().isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Email inválido.';
    }
    return null;
  }

  /// Devuelve [options] garantizando que [current] tenga un item propio.
  ///
  /// El valor guardado en el documento puede quedar fuera de las opciones
  /// actuales (una institución o un tag que fue borrado, o una lista derivada
  /// de los datos que todavía no lo incluye). Sin esto,
  /// `DropdownButtonFormField` dispara el assert "There should be exactly one
  /// item with DropdownButton's value" y cae el diálogo.
  static List<FieldOption> _optionsWithCurrent(
    List<FieldOption> options,
    String current,
  ) {
    if (current.isEmpty) return options;
    if (options.any((o) => o.value == current)) return options;
    return [
      ...options,
      FieldOption(value: current, label: '$current (no disponible)'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // El controller existe siempre: `_CrudFormDialogState.initState` lo crea
    // para todos los campos, incluso los toggles.
    final controller = state._controllers[spec.name]!;

    final label = Text(
      spec.required ? '${spec.label} *' : spec.label,
      style: TextStyle(
        fontSize: AppTokens.sm,
        fontWeight: FontWeight.w600,
        color: p.textSecondary,
      ),
    );

    switch (spec.type) {
      case FieldType.toggle:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  spec.label,
                  style: TextStyle(
                    fontSize: AppTokens.md,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: state._toggles[spec.name] ?? false,
                onChanged: (v) => state._setToggle(spec.name, v),
              ),
            ],
          ),
        );

      case FieldType.select:
        // El valor guardado puede no estar entre las opciones actuales (p. ej.
        // una institución o un tag que fue borrado, o una lista derivada de
        // los datos que todavía no lo incluye). `DropdownButtonFormField`
        // asserta si `initialValue` no tiene un item con ese `value`, así que
        // lo inyectamos con una etiqueta de respaldo en vez de romper el
        // diálogo.
        final options = _optionsWithCurrent(spec.options, controller.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: controller.text.isEmpty ? null : controller.text,
              items: [
                for (final o in options)
                  DropdownMenuItem(value: o.value, child: Text(o.label)),
              ],
              dropdownColor: p.bgSurface,
              isExpanded: true,
              validator: _validate,
              onChanged: (v) => controller.text = v ?? '',
            ),
            if (spec.hint != null) _Hint(spec.hint!),
          ],
        );

      case FieldType.datalist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 6),
            RawAutocomplete<FieldOption>(
              textEditingController: controller,
              focusNode: state._focusNodes[spec.name],
              optionsBuilder: (value) {
                final q = value.text.trim().toLowerCase();
                if (q.isEmpty) return const <FieldOption>[];
                return spec.options
                    .where((o) => o.value.toLowerCase().contains(q))
                    .toList();
              },
              onSelected: (o) => controller.text = o.value,
              fieldViewBuilder: (context, ctrl, focus, submit) => TextFormField(
                controller: ctrl,
                focusNode: focus,
                validator: _validate,
                decoration: InputDecoration(
                  hintText: spec.placeholder,
                  helperText: spec.hint,
                  helperMaxLines: 2,
                ),
              ),
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: p.bgSurface,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 220,
                      maxWidth: 320,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final o = options.elementAt(i);
                        return InkWell(
                          onTap: () => onSelected(o),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(o.label),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (spec.hint != null) _Hint(spec.hint!),
          ],
        );

      case FieldType.textarea:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              maxLines: spec.rows,
              validator: _validate,
              decoration: InputDecoration(
                hintText: spec.placeholder,
                helperText: spec.hint,
                helperMaxLines: 2,
              ),
            ),
          ],
        );

      case FieldType.date:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              validator: _validate,
              readOnly: true,
              onTap: () => _pickDate(context, controller),
              decoration: InputDecoration(
                hintText: 'dd/mm/aaaa',
                suffixIcon: const Icon(Icons.event_outlined, size: 18),
              ),
            ),
            if (spec.hint != null) _Hint(spec.hint!),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              validator: _validate,
              keyboardType: switch (spec.type) {
                FieldType.email => TextInputType.emailAddress,
                FieldType.number => const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                _ => TextInputType.text,
              },
              inputFormatters: spec.type == FieldType.number
                  ? <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?[0-9]*\.?[0-9]*'),
                      ),
                    ]
                  : null,
              decoration: InputDecoration(
                hintText: spec.placeholder,
                helperText: spec.hint,
                helperMaxLines: 2,
              ),
            ),
          ],
        );
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final p = context.palette;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year + 20),
      helpText: spec.label,
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: p.bgSurface,
            headerBackgroundColor: p.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        text,
        style: TextStyle(fontSize: AppTokens.xs, color: context.palette.textMuted),
      ),
    );
  }
}
