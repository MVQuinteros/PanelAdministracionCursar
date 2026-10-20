import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/model_providers.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';
import 'instituciones_policy.dart';

/// Módulo Instituciones (centros educativos).
///
/// Además del alta/edición, permite **aprobar o rechazar** cada institución
/// desde la tabla, con motivo y auditoría (`estadoPor`, `estadoFecha`,
/// `historialEstados`). El identificador oficial (CUE para establecimientos,
/// SPU para universidades, o la dependencia para sedes) se muestra en la
/// columna "Identificador" y linkea al registro oficial.
class InstitucionesPage extends StatelessWidget {
  const InstitucionesPage({super.key});

  static final CrudSpec spec = CrudSpec(
    title: 'Instituciones',
    subtitle: 'Centros educativos registrados',
    autoTimestamp: true,
    auditarEstado: true,
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
        'Las instituciones aprobadas se muestran en la app; las pendientes y '
        'rechazadas quedan ocultas. Usá Aprobar o Rechazar sobre cada fila.',
    bannerTone: Tone.info,
    bannerIcon: Icons.info_outline,
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
      // "Identificador" ocupa el ancho que antes tenía "Email": el CUE es el
      // dato que el admin necesita ver para verificar la institución, y el
      // email sigue estando en el formulario de edición.
      ColumnSpec(
        key: 'cue',
        label: 'Identificador',
        width: 200,
        cell: (context, row) {
          final info = InstitucionesPolicy.info(row);
          return VerifyLinkCell(
            label: info.etiqueta,
            url: info.url,
            esCodigo: info.esCodigo,
          );
        },
        csv: (row) => InstitucionesPolicy.csvIdentificador(row),
      ),
      ColumnSpec(
        key: 'telefono',
        label: 'Teléfono',
        width: 140,
        cell: (context, row) => MutedText(Fmt.display(row['telefono'])),
        csv: (row) => Fmt.display(row['telefono']),
      ),
      ColumnSpec(
        key: 'estado',
        label: 'Estado',
        width: 120,
        cell: (context, row) => _estadoBadge(row),
        csv: (row) => InstitucionesPolicy.estado(row),
      ),
      ColumnSpec(
        key: 'createdAt',
        label: 'Creada',
        width: 130,
        cell: (context, row) => MutedText(Fmt.date(row['createdAt'])),
        csv: (row) => Fmt.date(row['createdAt']),
      ),
    ],
    fields: <FieldSpec>[
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
      // El CUE es opcional (las universidades y las sedes no lo tienen), pero
      // si se carga tiene que respetar el formato oficial: 9 dígitos, o 13 si
      // incluye el anexo.
      FieldSpec(
        name: 'cue',
        label: 'CUE',
        pattern: InstitucionesPolicy.cueRegex,
        patternMessage: 'El CUE son 9 dígitos (o 13 si incluye el anexo).',
        hint: 'Clave Única de Establecimiento. Solo establecimientos no '
            'universitarios; las universidades se identifican por SPU.',
      ),
      FieldSpec(
        name: 'fuente',
        label: 'Fuente',
        type: FieldType.select,
        hint: 'Tipo de identificador oficial: CUE o SPU.',
        options: <FieldOption>[
          FieldOption(value: 'CUE', label: 'CUE'),
          FieldOption(value: 'SPU', label: 'SPU'),
        ],
      ),
      FieldSpec(
        name: 'dependeDe',
        label: 'Depende de',
        hint: 'Para sedes y anexos: la institución madre (ej. la universidad).',
        full: true,
      ),
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
    rowActions: <RowActionSpec>[
      RowActionSpec(
        action: 'aprobar',
        label: 'Aprobar',
        icon: Icons.check,
        tone: Tone.success,
        title: 'Aprobar institución',
        visible: (row) => !InstitucionesPolicy.esAprobada(row),
        patch: InstitucionesPolicy.aprobar(),
        doneMessage: 'Institución aprobada: ya se ve en la app.',
      ),
      // Rechazar pide el motivo en un diálogo: queda guardado en
      // `motivoRechazo` y la auditoría la agrega `CrudPage`.
      RowActionSpec(
        action: 'rechazar',
        label: 'Rechazar',
        icon: Icons.close,
        tone: Tone.warning,
        title: 'Rechazar institución',
        visible: (row) => !InstitucionesPolicy.esRechazada(row),
        patch: InstitucionesPolicy.rechazar(),
        doneMessage: 'Institución rechazada.',
        prompt: RowPromptSpec(
          title: 'Rechazar institución',
          field: 'motivoRechazo',
          label: 'Motivo del rechazo',
          hint: 'Queda guardado en la ficha y es obligatorio para confirmar.',
          rows: 4,
          submitLabel: 'Rechazar',
          required: true,
          doneMessage: 'Institución rechazada.',
        ),
      ),
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
    return switch (InstitucionesPolicy.estado(row)) {
      'aprobada' => StatusBadge('Aprobada', tone: Tone.success),
      'rechazada' => StatusBadge('Rechazada', tone: Tone.danger),
      final otro => StatusBadge(otro, tone: Tone.warning),
    };
  }

  static bool _matchEstado(Map<String, Object?> row, String value) =>
      InstitucionesPolicy.estado(row) == value;

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}
