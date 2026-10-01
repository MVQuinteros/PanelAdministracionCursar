import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/model_providers.dart';
import '../../data/models/usuario_model.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Usuarios.
///
/// El alta se hace desde la app móvil: por eso `allowAdd: false` y
/// `autoTimestamp: false`.
class UsuariosPage extends StatelessWidget {
  const UsuariosPage({super.key});

  static final CrudSpec spec = CrudSpec(
    title: 'Usuarios',
    subtitle: 'Cuentas de la app CURSAR',
    allowAdd: false,
    autoTimestamp: false,
    loader: (ref) => ref.read(usuarioModelProvider).list(),
    bannerText:
        'El alta de usuarios se realiza desde la app móvil. Acá podés ver, '
        'editar perfil, cambiar el rol (usuario / admin) y eliminar cuentas.',
    filters: <FilterSpec>[
      const FilterSpec(key: 'localidad', label: 'Localidad'),
      const FilterSpec(
        key: 'rol',
        label: 'Rol',
        options: <FieldOption>[
          FieldOption(value: 'usuario', label: 'Usuario'),
          FieldOption(value: 'admin', label: 'Admin'),
        ],
      ),
      const FilterSpec(
        key: 'ultimoLogin',
        label: 'Último acceso',
        type: FilterType.dateRange,
      ),
    ],
    columns: <ColumnSpec>[
      ColumnSpec(
        label: 'Nombre',
        width: 200,
        cell: (context, row) => StrongText(
          UsuarioModel.displayName(row),
        ),
        csv: (row) =>
            '${row['nombre'] ?? ''} ${row['apellido'] ?? ''}'.trim(),
      ),
      ColumnSpec(
        label: 'Email',
        width: 240,
        cell: (context, row) => MutedText(Fmt.display(row['email'])),
        csv: (row) => Fmt.display(row['email']),
      ),
      ColumnSpec(
        label: 'Localidad',
        width: 150,
        cell: (context, row) => MutedText(Fmt.display(row['localidad'])),
        csv: (row) => Fmt.display(row['localidad']),
      ),
      ColumnSpec(
        label: 'Rol',
        width: 110,
        cell: (context, row) => row['rol'] == 'admin'
            ? const StatusBadge('Admin', tone: Tone.success)
            : const StatusBadge('Usuario', tone: Tone.neutral),
        csv: (row) => '${row['rol'] ?? ''}',
      ),
      ColumnSpec(
        label: 'Último acceso',
        width: 150,
        cell: (context, row) => MutedText(Fmt.dateTime(row['ultimoLogin'])),
        csv: (row) => Fmt.dateTime(row['ultimoLogin']),
      ),
      ColumnSpec(
        label: 'Nacimiento',
        width: 130,
        cell: (context, row) => MutedText(Fmt.date(row['fechaNacimiento'])),
        csv: (row) => Fmt.date(row['fechaNacimiento']),
      ),
    ],
    fields: <FieldSpec>[
      const FieldSpec(
        name: 'nombre',
        label: 'Nombre',
        type: FieldType.text,
        required: true,
      ),
      const FieldSpec(
        name: 'apellido',
        label: 'Apellido',
        type: FieldType.text,
        required: true,
      ),
      const FieldSpec(name: 'localidad', label: 'Localidad'),
      const FieldSpec(
        name: 'fechaNacimiento',
        label: 'Fecha de nacimiento',
        type: FieldType.date,
      ),
      const FieldSpec(
        name: 'rol',
        label: 'Rol',
        type: FieldType.select,
        options: <FieldOption>[
          FieldOption(value: 'usuario', label: 'Usuario'),
          FieldOption(value: 'admin', label: 'Administrador'),
        ],
      ),
      const FieldSpec(
        name: 'modoOscuro',
        label: 'Tema oscuro',
        type: FieldType.toggle,
      ),
    ],
    rowActions: <RowActionSpec>[
      const RowActionSpec(
        action: 'edit',
        label: 'Editar',
        tone: Tone.secondary,
        icon: Icons.edit_outlined,
        title: 'Editar usuario',
      ),
      const RowActionSpec(
        action: 'delete',
        label: 'Eliminar',
        tone: Tone.danger,
        icon: Icons.delete_outline,
        title: 'Eliminar usuario',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}
