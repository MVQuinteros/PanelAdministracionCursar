import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/widgets/banner.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/toast.dart';
import 'crud_form_dialog.dart';
import 'crud_models.dart';
import 'crud_spec.dart';
import 'crud_table.dart';
import 'crud_toolbar.dart';

/// Página CRUD genérica.
///
/// Es el reemplazo directo de `createCrudController(...)` + `crudView.js`:
/// toolbar, banner, tabla y diálogos de alta/edición y borrado.
///
/// Dueña del provider del módulo: el [CrudController] se crea una única vez
/// acá y se pasa a la toolbar y a la tabla, así todos observan el mismo estado.
class CrudPage extends ConsumerStatefulWidget {
  const CrudPage({super.key, required this.spec});

  final CrudSpec spec;

  @override
  ConsumerState<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends ConsumerState<CrudPage> {
  /// Alto mínimo para que la tabla ocupe lo que sobra. Por debajo de esto
  /// (head + banner + toolbar + banner = ~200 px) la tabla se vuelve
  /// ilegible, así que la página pasa a scrollear.
  static const _minHeightForStretch = 520.0;

  late NotifierProvider<CrudController, CrudState> _provider;

  /// Notifier vivo del módulo. Se resuelve siempre a través del provider para
  /// no duplicar la instancia (ni su estado) fuera del container.
  CrudController get _c => ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    _provider = crudProviderFor(widget.spec);
  }

  @override
  void didUpdateWidget(CrudPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El spec cambió (por ejemplo, Ofertas recompone sus campos cuando
    // terminan de cargar instituciones y tags): se reconstruye el módulo.
    if (!identical(oldWidget.spec, widget.spec)) {
      _provider = crudProviderFor(widget.spec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final state = ref.watch(_provider);

    if (state.loading) {
      return const Center(child: LoadingCard());
    }
    if (state.error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error al cargar este módulo: ${state.error}',
              style: TextStyle(color: context.palette.danger),
            ),
          ),
        ),
      );
    }

    final table = state.filtered.isEmpty
        ? const EmptyState()
        : CrudTable(
            spec: spec,
            rows: state.filtered,
            onAction: _handleAction,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        // El head + banner + toolbar ya se comen bastante alto. Si lo que
        // sobra no alcanza para una tabla usable (móvil, o ventana baja),
        // scrollea la página y la tabla toma un alto fijo en vez de estirarse
        // hasta quedar en 20 px.
        final stacked = constraints.maxHeight < _minHeightForStretch;

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ViewHead(spec.subtitle),
            if (spec.bannerText != null)
              InfoBanner(
                text: spec.bannerText!,
                tone: spec.bannerTone,
                icon: spec.bannerIcon,
              ),
            CrudToolbar(
              spec: spec,
              provider: _provider,
              onAdd: () => _openForm(null),
            ),
            const SizedBox(height: 16),
            if (stacked)
              SizedBox(height: AppTokens.tableMaxHeight, child: table)
            else
              Expanded(child: table),
          ],
        );

        return stacked ? SingleChildScrollView(child: body) : body;
      },
    );
  }

  Future<void> _handleAction(String action, Doc row) async {
    switch (action) {
      case 'edit':
        await _openForm(row);
        return;
      case 'delete':
        await _confirmDelete(row);
        return;
    }
    // Acciones declarativas (aprobar, resolver, reabrir, …).
    final spec = widget.spec.rowActions
        .where((a) => a.action == action)
        .firstOrNull;
    final patch = spec?.patch;
    if (patch == null) return;
    if (!mounted) return;

    final id = row['id']! as String;
    try {
      await crudWritableOf(widget.spec.title).save(id, patch);
    } catch (err) {
      if (mounted) {
        toast(
          context,
          'No se pudo aplicar la acción: $err',
          kind: ToastKind.error,
        );
      }
      return;
    }
    final message = spec?.doneMessage;
    if (message != null && mounted) {
      toast(context, message, kind: ToastKind.success);
    }
    if (!mounted) return;
    await _c.load();
  }

  Future<void> _openForm(Doc? row) async {
    final spec = widget.spec;
    final isEdit = row != null;
    final id = isEdit ? row['id']! as String : null;
    final model = crudWritableOf(spec.title);
    final successMessage =
        isEdit ? 'Cambios guardados.' : '${spec.title} creado correctamente.';

    final values = <String, Object?>{...spec.addValues};
    if (row != null) {
      for (final f in spec.fields) {
        values[f.name] = row[f.name];
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => CrudFormDialog(
        title: isEdit ? 'Editar ${spec.singular}' : 'Nuevo ${spec.singular}',
        fields: spec.fields,
        initialValues: values,
        onSubmit: (formValues) async {
          // `autoTimestamp` del original: al crear se agrega el `createdAt`
          // del servidor. En una edición solo van los campos del formulario.
          if (id == null && spec.autoTimestamp) {
            formValues['createdAt'] = FieldValue.serverTimestamp();
          }
          // Si falla, el error lo muestra el propio diálogo.
          await model.save(id, formValues);
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop(true);
          if (mounted) {
            toast(context, successMessage, kind: ToastKind.success);
          }
        },
      ),
    );
    if (saved == true && mounted) {
      await _c.load();
    }
  }

  Future<void> _confirmDelete(Doc row) async {
    final model = crudWritableOf(widget.spec.title);
    final id = row['id']! as String;
    final ok = await confirmDialog(
      context,
      title: 'Eliminar registro',
      message: 'Esta acción es irreversible. ¿Eliminar este registro y todos '
          'sus datos?',
      confirmLabel: 'Eliminar',
      danger: true,
    );
    if (!ok) return;
    try {
      await model.remove(id);
      if (mounted) {
        toast(context, 'Registro eliminado.', kind: ToastKind.success);
      }
    } catch (err) {
      if (mounted) {
        toast(context, 'No se pudo eliminar: $err', kind: ToastKind.error);
      }
      return;
    }
    if (!mounted) return;
    await _c.load();
  }
}
