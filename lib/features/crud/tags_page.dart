import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/model_providers.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Tags.
///
/// El más simple de todos: dos campos, sin filtros, orden alfabético.
class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  static final CrudSpec spec = CrudSpec(
    title: 'Tags',
    subtitle: 'Etiquetas para categorizar ofertas',
    loader: (ref) => ref.read(tagModelProvider).list(),
    columns: <ColumnSpec>[
      ColumnSpec(
        label: 'Nombre',
        width: 240,
        cell: (context, row) => StrongText(Fmt.display(row['nombre'])),
        csv: (row) => Fmt.display(row['nombre']),
      ),
      ColumnSpec(
        label: 'Descripción',
        width: 420,
        cell: (context, row) => MutedText(Fmt.display(row['descripcion'])),
        csv: (row) => Fmt.display(row['descripcion']),
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
        name: 'descripcion',
        label: 'Descripción',
        type: FieldType.textarea,
        full: true,
      ),
    ],
    rowActions: <RowActionSpec>[
      const RowActionSpec(
        action: 'edit',
        label: 'Editar',
        tone: Tone.secondary,
        icon: Icons.edit_outlined,
        title: 'Editar tag',
      ),
      const RowActionSpec(
        action: 'delete',
        label: 'Eliminar',
        tone: Tone.danger,
        icon: Icons.delete_outline,
        title: 'Eliminar tag',
      ),
    ],
    autoTimestamp: false,
  );

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}
