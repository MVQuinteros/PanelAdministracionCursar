import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/banner.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/toast.dart';
import '../../data/models/model_providers.dart';
import '../auth/auth_controller.dart';
import '../crud/crud_spec.dart';
import '../crud/crud_table.dart';
import '../crud/crud_widgets.dart';
import 'admin_policy.dart';

/// Módulo Administradores.
///
/// Dar o quitar el acceso al panel. **No crea cuentas**: el panel solo puede
/// cambiar el `rol` de un documento de `usuarios`, o sea de alguien que ya se
/// registró en la app móvil. Crear credenciales nuevas necesitaría Cloud
/// Functions con el Admin SDK, que este proyecto no tiene.
///
/// Cada cambio deja un rastro en el mismo documento (`rolAnterior`,
/// `rolUpdatedAt`, `rolUpdatedBy`), así se sabe quién dio o quitó el acceso y
/// cuándo, sin necesidad de una colección nueva ni de tocar las reglas: el
/// administrador ya tiene permiso total sobre `usuarios`.
class AdministradoresPage extends ConsumerStatefulWidget {
  const AdministradoresPage({super.key});

  @override
  ConsumerState<AdministradoresPage> createState() =>
      _AdministradoresPageState();
}

class _AdministradoresPageState extends ConsumerState<AdministradoresPage> {
  /// Mismo umbral que `CrudPage`: por debajo de esto la tabla toma un alto fijo
  /// y la página scrollea, en vez de aplastarse hasta quedar ilegible.
  static const _minHeightForStretch = 520.0;

  static final ColumnSpec _colNombre = ColumnSpec(
    label: 'Nombre',
    width: 230,
    cell: (context, row) => StrongText(AdminPolicy.nombre(row)),
    csv: (row) => AdminPolicy.nombre(row),
  );

  static final ColumnSpec _colEmail = ColumnSpec(
    label: 'Email',
    width: 260,
    cell: (context, row) => MutedText(Fmt.display(row['email'])),
    csv: (row) => Fmt.display(row['email']),
  );

  bool _cargando = true;
  String? _error;
  List<UsuarioDoc> _usuarios = const <UsuarioDoc>[];
  String _busqueda = '';
  bool _verEx = false;
  bool _guardando = false;

  /// Email del admin que está operando, para la auditoría. Sale del documento
  /// (`adminDoc`) y, si no estuviera, de la sesión de Firebase Auth.
  String get _emailActual {
    final auth = ref.read(authControllerProvider);
    final email = '${auth.adminDoc?['email'] ?? ''}'.trim();
    return email.isNotEmpty ? email : (auth.user?.email ?? '');
  }

  /// uid de la sesión actual: con esto se bloquea auto-quitarse el acceso.
  String? get _uidActual =>
      ref.read(authControllerProvider).adminDoc?['id'] as String?;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final filas = await ref.read(usuarioModelProvider).list();
      if (!mounted) return;
      setState(() {
        _usuarios = filas;
        _cargando = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: LoadingCard(label: 'Cargando usuarios…'));
    }
    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No se pudieron cargar los usuarios: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.danger),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Reintentar',
                  icon: Icons.refresh,
                  small: true,
                  onPressed: _cargar,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filas = (_verEx
            ? AdminPolicy.exAdmins(_usuarios)
            : AdminPolicy.admins(_usuarios))
        .where((u) => AdminPolicy.coincide(u, _busqueda))
        .toList();

    final tabla = filas.isEmpty
        ? _vacio()
        : CrudTable(spec: _spec(_verEx), rows: filas, onAction: _accion);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxHeight < _minHeightForStretch;
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ViewHead('Cuentas con acceso al panel'),
            const InfoBanner(
              text: 'El panel no crea cuentas ni contraseñas: la persona se '
                  'registra en la app CURSAR y desde acá se le da (o se le '
                  'quita) el acceso. Cada cambio queda registrado con quién lo '
                  'hizo y cuándo.',
            ),
            _barra(),
            const SizedBox(height: 16),
            if (stacked)
              SizedBox(height: AppTokens.tableMaxHeight, child: tabla)
            else
              Expanded(child: tabla),
          ],
        );
        return stacked ? SingleChildScrollView(child: body) : body;
      },
    );
  }

  Widget _barra() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: _verEx ? 'Buscar ex administrador…' : 'Buscar administrador…',
              prefixIcon: const Icon(Icons.search, size: 16),
            ),
          ),
        ),
        AppButton(
          label: 'Agregar administrador',
          icon: Icons.person_add_alt_1,
          tone: Tone.primary,
          small: true,
          onPressed: _guardando ? null : _elegir,
        ),
        AppButton(
          label: _verEx ? 'Ver administradores' : 'Ver ex administradores',
          icon: _verEx ? Icons.people_alt_outlined : Icons.history,
          tone: Tone.secondary,
          small: true,
          onPressed: () => setState(() {
            _verEx = !_verEx;
            _busqueda = '';
          }),
        ),
      ],
    );
  }

  Widget _vacio() => EmptyState(
    icon: Icons.admin_panel_settings_outlined,
    title: _verEx ? 'Sin ex administradores' : 'Sin administradores',
    text: _busqueda.trim().isNotEmpty
        ? 'Ninguno coincide con la búsqueda.'
        : (_verEx
              ? 'Acá quedan los que tenían acceso y se les quitó.'
              : 'Dale acceso a un usuario de la app con "Agregar '
                    'administrador".'),
  );

  /// Columnas y acciones de la tabla, según se esté viendo a los admins
  /// actuales o a los que ya no lo son.
  CrudSpec _spec(bool ex) {
    const quitar = RowActionSpec(
      action: 'quitar',
      label: 'Quitar acceso',
      tone: Tone.danger,
      icon: Icons.person_remove_alt_1,
      title: 'Quitar el acceso al panel',
    );
    const dar = RowActionSpec(
      action: 'dar',
      label: 'Dar acceso',
      tone: Tone.success,
      icon: Icons.person_add_alt_1,
      title: 'Volver a darle acceso al panel',
    );

    return CrudSpec(
      title: 'Administradores',
      subtitle: 'Cuentas con acceso al panel',
      // La tabla se alimenta de `_usuarios`; el `loader` no se usa en esta
      // pantalla, pero `CrudSpec` lo exige.
      loader: (ref) async => const <UsuarioDoc>[],
      columns: ex
          ? <ColumnSpec>[
              _colNombre,
              _colEmail,
              ColumnSpec(
                label: 'Acceso quitado',
                width: 175,
                cell: (context, row) => MutedText(Fmt.dateTime(row['rolUpdatedAt'])),
                csv: (row) => Fmt.dateTime(row['rolUpdatedAt']),
              ),
              ColumnSpec(
                label: 'Quitado por',
                width: 220,
                cell: (context, row) => MutedText(Fmt.display(row['rolUpdatedBy'])),
                csv: (row) => Fmt.display(row['rolUpdatedBy']),
              ),
            ]
          : <ColumnSpec>[
              _colNombre,
              _colEmail,
              ColumnSpec(
                label: 'Último acceso',
                width: 175,
                cell: (context, row) => MutedText(Fmt.dateTime(row['ultimoLogin'])),
                csv: (row) => Fmt.dateTime(row['ultimoLogin']),
              ),
              ColumnSpec(
                label: 'Admin desde',
                width: 175,
                cell: (context, row) => MutedText(Fmt.dateTime(row['rolUpdatedAt'])),
                csv: (row) => Fmt.dateTime(row['rolUpdatedAt']),
              ),
              ColumnSpec(
                label: 'Otorgado por',
                width: 220,
                cell: (context, row) => MutedText(Fmt.display(row['rolUpdatedBy'])),
                csv: (row) => Fmt.display(row['rolUpdatedBy']),
              ),
            ],
      rowActions: ex ? const <RowActionSpec>[dar] : const <RowActionSpec>[quitar],
    );
  }

  Future<void> _accion(String action, UsuarioDoc row) async {
    if (_guardando) return;
    switch (action) {
      case 'dar':
        await _dar(row);
        return;
      case 'quitar':
        await _quitar(row);
        return;
    }
  }

  /// Elegir a quién darle acceso, entre los usuarios que todavía no lo tienen.
  Future<void> _elegir() async {
    final candidatos = AdminPolicy.candidatos(_usuarios);
    if (candidatos.isEmpty) {
      toast(
        context,
        'Todos los usuarios ya tienen acceso al panel.',
        kind: ToastKind.info,
      );
      return;
    }

    final elegido = await showAppModal<UsuarioDoc>(
      context: context,
      title: 'Agregar administrador',
      maxWidth: 560,
      contentBuilder: (_) => _ElegirUsuario(usuarios: candidatos),
    );
    if (elegido == null || !mounted) return;
    await _dar(elegido);
  }

  Future<void> _dar(UsuarioDoc row) async {
    final ok = await confirmDialog(
      context,
      title: 'Dar acceso al panel',
      message: '${AdminPolicy.etiqueta(row)} va a poder entrar al panel y '
          'administrar todo (usuarios, ofertas, avisos, roles). Entra con su '
          'cuenta de la app CURSAR. ¿Confirmás?',
      confirmLabel: 'Dar acceso',
    );
    if (!ok) return;

    await _guardar(
      row,
      AdminPolicy.darAdmin(
        rolAnterior: '${row['rol'] ?? 'usuario'}',
        por: _emailActual,
      ),
      '${AdminPolicy.nombre(row)} ya es administrador.',
    );
  }

  Future<void> _quitar(UsuarioDoc row) async {
    final bloqueo = AdminPolicy.bloqueoQuitar(
      u: row,
      adminsTotal: AdminPolicy.admins(_usuarios).length,
      uidActual: _uidActual,
    );
    if (bloqueo != null) {
      toast(context, bloqueo, kind: ToastKind.error);
      return;
    }

    final ok = await confirmDialog(
      context,
      title: 'Quitar acceso al panel',
      message: '${AdminPolicy.etiqueta(row)} deja de ser administrador. Su '
          'cuenta de la app sigue igual: solo pierde el acceso al panel.',
      confirmLabel: 'Quitar acceso',
      danger: true,
    );
    if (!ok) return;

    await _guardar(
      row,
      AdminPolicy.quitarAdmin(por: _emailActual),
      '${AdminPolicy.nombre(row)} ya no es administrador.',
    );
  }

  Future<void> _guardar(
    UsuarioDoc row,
    Map<String, Object?> patch,
    String mensaje,
  ) async {
    final id = '${row['id']}';
    setState(() => _guardando = true);
    try {
      await ref.read(usuarioModelProvider).update(id, <String, Object?>{
        ...patch,
        'rolUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      toast(context, mensaje, kind: ToastKind.success);
      await _cargar();
    } catch (err) {
      if (mounted) {
        toast(
          context,
          'No se pudo cambiar el rol: $err',
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

/// Lista de usuarios sin acceso, con buscador, para elegir a quién dárselo.
class _ElegirUsuario extends StatefulWidget {
  const _ElegirUsuario({required this.usuarios});

  final List<UsuarioDoc> usuarios;

  @override
  State<_ElegirUsuario> createState() => _ElegirUsuarioState();
}

class _ElegirUsuarioState extends State<_ElegirUsuario> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final filas = widget.usuarios
        .where((u) => AdminPolicy.coincide(u, _busqueda))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _busqueda = v),
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre o email…',
            prefixIcon: Icon(Icons.search, size: 16),
          ),
        ),
        const SizedBox(height: 12),
        if (filas.isEmpty)
          const EmptyState(
            title: 'Sin resultados',
            text: 'No hay usuarios que coincidan con la búsqueda.',
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filas.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: p.borderSubtle),
              itemBuilder: (context, i) {
                final u = filas[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(child: StrongText(AdminPolicy.nombre(u))),
                                if (AdminPolicy.fueAdmin(u)) ...[
                                  const SizedBox(width: 8),
                                  const StatusBadge('Ex admin', tone: Tone.warning),
                                ],
                              ],
                            ),
                            MutedText(Fmt.display(u['email'])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        label: 'Dar acceso',
                        icon: Icons.person_add_alt_1,
                        small: true,
                        onPressed: () => Navigator.of(context).pop(u),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
