import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/model_providers.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Instituciones (centros educativos).
class InstitucionesPage extends StatelessWidget {
  const InstitucionesPage({super.key});

  static final CrudSpec spec = CrudSpec(
    title: 'Instituciones',
    subtitle: 'Centros educativos registrados',
    autoTimestamp: true,
    loader: (ref) => ref.read(institucionModelProvider).list(),
    addValues: const <String, Object?>{'estado': 'pendiente'},
    filters: const <FilterSpec>[
      FilterSpec(key: 'ciudad', label: 'Ciudad'),
      FilterSpec(
        key: 'estado',
        label: 'Estado',
        options: <FieldOption>[
          FieldOption(value: 'pendiente', label: 'Pendiente'),
          FieldOption(value: 'aprobada', label: 'Aprobada'),
          FieldOption(value: 'rechazada', label: 'Rechazada'),
        ],
        match: _matchEstado,
      ),
      FilterSpec(key: 'createdAt', label: 'Creada', type: FilterType.dateRange),
    ],
    bannerText:
        'Las instituciones con latitud/longitud aparecen en el mapa de la '
        'app. El estado permite marcarlas como pendiente, aprobada o rechazada.',
    columns: <ColumnSpec>[
      ColumnSpec(
        key: 'nombre',
        label: 'Nombre',
        width: 220,
        cell: (context, row) => StrongText(Fmt.display(row['nombre'])),
        csv: (row) => Fmt.display(row['nombre']),
      ),
      ColumnSpec(
        key: 'ciudad',
        label: 'Ciudad',
        width: 190,
        cell: (context, row) => MutedText(_ciudad(row)),
        csv: (row) => _ciudad(row),
      ),
      ColumnSpec(
        key: 'telefono',
        label: 'Teléfono',
        width: 140,
        cell: (context, row) => MutedText(Fmt.display(row['telefono'])),
        csv: (row) => Fmt.display(row['telefono']),
      ),
      ColumnSpec(
        key: 'email',
        label: 'Email',
        width: 200,
        cell: (context, row) => MutedText(Fmt.display(row['email'])),
        csv: (row) => Fmt.display(row['email']),
      ),
      ColumnSpec(
        key: 'estado',
        label: 'Estado',
        width: 120,
        cell: (context, row) => _estadoBadge(row),
        csv: (row) => '${row['estado'] ?? 'pendiente'}',
      ),
      ColumnSpec(
        key: 'createdAt',
        label: 'Creada',
        width: 130,
        cell: (context, row) => MutedText(Fmt.date(row['createdAt'])),
        csv: (row) => Fmt.date(row['createdAt']),
      ),
    ],
    fields: const <FieldSpec>[
      FieldSpec(
        name: 'nombre',
        label: 'Nombre',
        type: FieldType.text,
        required: true,
        full: true,
      ),
      FieldSpec(
        name: 'descripcion',
        label: 'Descripción',
        type: FieldType.textarea,
        full: true,
      ),
      FieldSpec(
        name: 'direccion',
        label: 'Dirección',
        type: FieldType.text,
        full: true,
      ),
      FieldSpec(
        name: 'ciudad',
        label: 'Ciudad',
        type: FieldType.text,
        required: true,
      ),
      FieldSpec(name: 'provincia', label: 'Provincia'),
      FieldSpec(name: 'telefono', label: 'Teléfono'),
      FieldSpec(name: 'email', label: 'Email', type: FieldType.email),
      FieldSpec(name: 'sitioWeb', label: 'Sitio web'),
      FieldSpec(name: 'logoURL', label: 'URL del logo'),
      FieldSpec(
        name: 'latitud',
        label: 'Latitud',
        type: FieldType.number,
        hint: 'Para el mapa del mobile.',
      ),
      FieldSpec(
        name: 'longitud',
        label: 'Longitud',
        type: FieldType.number,
        hint: 'Para el mapa del mobile.',
      ),
      FieldSpec(
        name: 'estado',
        label: 'Estado',
        type: FieldType.select,
        options: <FieldOption>[
          FieldOption(value: 'pendiente', label: 'Pendiente'),
          FieldOption(value: 'aprobada', label: 'Aprobada'),
          FieldOption(value: 'rechazada', label: 'Rechazada'),
        ],
      ),
    ],
    rowActions: const <RowActionSpec>[
      RowActionSpec(
        action: 'edit',
        label: 'Editar',
        icon: Icons.edit_outlined,
        tone: Tone.secondary,
        title: 'Editar institución',
      ),
      RowActionSpec(
        action: 'delete',
        label: 'Eliminar',
        icon: Icons.delete_outline,
        tone: Tone.danger,
        title: 'Eliminar institución',
      ),
    ],
  );

  static String _ciudad(Map<String, Object?> row) =>
      [row['ciudad'], row['provincia']]
          .where((v) => v != null && '$v'.isNotEmpty)
          .join(', ');

  static Widget _estadoBadge(Map<String, Object?> row) {
    final estado = '${row['estado'] ?? 'pendiente'}';
    return switch (estado) {
      'aprobada' => StatusBadge(estado, tone: Tone.success),
      'rechazada' => StatusBadge(estado, tone: Tone.danger),
      _ => StatusBadge(estado, tone: Tone.warning),
    };
  }

  static bool _matchEstado(Map<String, Object?> row, String value) =>
      '${row['estado'] ?? 'pendiente'}' == value;

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}
