import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/model_providers.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Avisos (noticias/campañas que ve la app).
class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

  /// Tipos aceptados por el formulario; los mismos del original.
  static const List<String> tipos = <String>[
    'Información',
    'Novedad',
    'Promoción',
    'Mantenimiento',
    'General',
    'Inscripción',
    'Noticia',
    'Consejo',
  ];

  static final CrudSpec spec = CrudSpec(
    title: 'Avisos',
    subtitle: 'Noticias publicadas en el inicio de la app',
    // El `publicado` lo instala `AvisoModel.add` con serverTimestamp.
    autoTimestamp: false,
    loader: (ref) => ref.read(avisoModelProvider).list(),
    filters: const <FilterSpec>[
      FilterSpec(key: 'tipo', label: 'Tipo'),
      FilterSpec(key: 'publicado', label: 'Publicado', type: FilterType.dateRange),
    ],
    columns: <ColumnSpec>[
      ColumnSpec(
        key: 'titulo',
        label: 'Título',
        width: 260,
        cell: (context, row) => StrongText(Fmt.display(row['titulo'])),
        csv: (row) => Fmt.display(row['titulo']),
      ),
      ColumnSpec(
        key: 'tipo',
        label: 'Tipo',
        width: 130,
        cell: (context, row) => StatusBadge(
          '${row['tipo'] ?? 'General'}',
          tone: _tipoTone(row['tipo']),
        ),
        csv: (row) => '${row['tipo'] ?? ''}',
      ),
      ColumnSpec(
        key: 'publicado',
        label: 'Publicado',
        width: 150,
        cell: (context, row) => MutedText(Fmt.dateTime(row['publicado'])),
        csv: (row) => Fmt.dateTime(row['publicado']),
      ),
      ColumnSpec(
        key: 'link',
        label: 'Link',
        width: 200,
        // El campo es `dynamic` en Firestore: un documento legacy (o escrito
        // por otra vía) con un tipo distinto haría fallar un cast directo.
        cell: (context, row) =>
            ExternalLinkText(row['link'] is String ? row['link']! as String : null),
        csv: (row) => Fmt.display(row['link']),
      ),
    ],
    fields: <FieldSpec>[
      const FieldSpec(
        name: 'titulo',
        label: 'Título',
        type: FieldType.text,
        required: true,
        full: true,
      ),
      const FieldSpec(
        name: 'mensaje',
        label: 'Mensaje',
        type: FieldType.textarea,
        required: true,
        full: true,
      ),
      FieldSpec(
        name: 'tipo',
        label: 'Tipo',
        type: FieldType.datalist,
        options: <FieldOption>[
          for (final t in tipos) FieldOption(value: t, label: t),
        ],
      ),
      FieldSpec(
        name: 'link',
        label: 'Link (opcional)',
        type: FieldType.text,
        full: true,
        placeholder: 'https://…',
      ),
    ],
    rowActions: const <RowActionSpec>[
      RowActionSpec(
        action: 'edit',
        label: 'Editar',
        icon: Icons.edit_outlined,
        tone: Tone.secondary,
        title: 'Editar aviso',
      ),
      RowActionSpec(
        action: 'delete',
        label: 'Eliminar',
        icon: Icons.delete_outline,
        tone: Tone.danger,
        title: 'Eliminar aviso',
      ),
    ],
  );

  /// Equivale al mapa `TIPO_BADGE` + fallback a neutral.
  static Tone _tipoTone(Object? tipo) => switch (
      '${tipo ?? ''}'.trim().toLowerCase()) {
    'informacion' || 'inscripcion' => Tone.info,
    'novedad' || 'noticia' => Tone.success,
    'promocion' || 'consejo' => Tone.purple,
    'mantenimiento' => Tone.warning,
    _ => Tone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}
