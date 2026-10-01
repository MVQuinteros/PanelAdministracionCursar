import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cursar_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/model_providers.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Ofertas.
///
/// Incluye el flujo de moderación: aprobar / desaprobar para que la oferta
/// se vea en la app. Necesita instituciones y tags para resolver el join de
/// la columna "Institución" y las opciones del formulario, por eso el spec se
/// arma después de esa carga.
class OfertasPage extends ConsumerStatefulWidget {
  const OfertasPage({super.key});

  @override
  ConsumerState<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends ConsumerState<OfertasPage> {
  static const areas = <String>[
    'Tecnología',
    'Ingeniería',
    'Salud',
    'Educación',
    'Creativa',
    'Administración',
    'Economía',
    'Ciencias Sociales',
    'Ciencias Ambientales',
    'Derecho',
    'Humanidades',
  ];

  late Future<_OfertasRefs> _refs;
  CrudSpec? _spec;

  @override
  void initState() {
    super.initState();
    _refs = _loadRefs();
  }

  Future<_OfertasRefs> _loadRefs() async {
    // Cada lectura es independiente: si una colección no se puede leer, el
    // módulo sigue con la otra. Mismo `safeList()` del original y mismo
    // criterio que el dashboard (`DashboardData._safe`).
    final refs = await (
      _safeList(() => ref.read(institucionModelProvider).list()),
      _safeList(() => ref.read(tagModelProvider).list()),
    ).wait;
    return _OfertasRefs(refs.$1, refs.$2);
  }

  static Future<List<Map<String, Object?>>> _safeList(
    Future<List<Map<String, Object?>>> Function() read,
  ) async {
    try {
      return await read();
    } catch (_) {
      return const <Map<String, Object?>>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OfertasRefs>(
      future: _refs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingCard());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'No se pudieron cargar instituciones y tags: ${snapshot.error}',
              style: TextStyle(color: context.palette.danger),
            ),
          );
        }
        // El spec se memoiza: `CrudPage` reinicia el módulo si cambia la
        // identidad del spec, y eso volvería a disparar la carga.
        return CrudPage(spec: _spec ??= _specFor(snapshot.requireData));
      },
    );
  }

  CrudSpec _specFor(_OfertasRefs data) {
    final instNames = institutionNamesById(data.instituciones);
    final tagNames = tagNamesOf(data.tags);

    return CrudSpec(
      title: 'Ofertas',
      subtitle: 'Carreras y titulaciones publicadas',
      autoTimestamp: true,
      loader: (ref) async {
        final rows = await ref.read(ofertaModelProvider).list();
        return rows
            .map((r) => <String, Object?>{
                  ...r,
                  'institucionNombre': instNames[r['institucionUid']] ?? '—',
                })
            .toList();
      },
      filters: const <FilterSpec>[
        FilterSpec(key: 'area', label: 'Área'),
        FilterSpec(
          key: 'aprobada',
          label: 'Estado',
          options: <FieldOption>[
            FieldOption(value: 'true', label: 'Aprobadas'),
            FieldOption(value: 'false', label: 'Pendientes'),
          ],
          match: _matchAprobada,
        ),
        FilterSpec(key: 'createdAt', label: 'Alta', type: FilterType.dateRange),
      ],
      bannerText:
          'Las ofertas con estado pendiente aún no se muestran en la app. '
          'Usá el botón Aprobar para publicarlas.',
      bannerTone: Tone.warning,
      bannerIcon: Icons.warning_amber_rounded,
      columns: <ColumnSpec>[
        ColumnSpec(
          key: 'nombre',
          label: 'Nombre',
          width: 220,
          cell: (context, row) => StrongText(Fmt.display(row['nombre'])),
          csv: (row) => Fmt.display(row['nombre']),
        ),
        ColumnSpec(
          key: 'institucionUid',
          label: 'Institución',
          width: 180,
          cell: (context, row) => MutedText(Fmt.display(row['institucionNombre'])),
          csv: (row) => '${row['institucionNombre'] ?? ''}',
        ),
        ColumnSpec(
          key: 'area',
          label: 'Área',
          width: 150,
          cell: (context, row) => MutedText(Fmt.display(row['area'])),
          csv: (row) => Fmt.display(row['area']),
        ),
        ColumnSpec(
          key: 'nivel',
          label: 'Nivel',
          width: 110,
          cell: (context, row) => MutedText(Fmt.display(row['nivel'])),
          csv: (row) => Fmt.display(row['nivel']),
        ),
        ColumnSpec(
          key: 'modalidad',
          label: 'Modalidad',
          width: 120,
          cell: (context, row) => MutedText(Fmt.display(row['modalidad'])),
          csv: (row) => Fmt.display(row['modalidad']),
        ),
        ColumnSpec(
          key: 'duracionAnios',
          label: 'Años',
          width: 70,
          cell: (context, row) => MutedText(Fmt.display(row['duracionAnios'])),
          csv: (row) => Fmt.display(row['duracionAnios']),
        ),
        ColumnSpec(
          key: 'aprobada',
          label: 'Estado',
          width: 110,
          cell: (context, row) => row['aprobada'] == true
              ? const StatusBadge('Aprobada', tone: Tone.success)
              : const StatusBadge('Pendiente', tone: Tone.warning),
          csv: (row) => row['aprobada'] == true ? 'Aprobada' : 'Pendiente',
        ),
        ColumnSpec(
          key: 'createdAt',
          label: 'Creada',
          width: 150,
          cell: (context, row) => MutedText(Fmt.dateTime(row['createdAt'])),
          csv: (row) => Fmt.dateTime(row['createdAt']),
        ),
      ],
      fields: <FieldSpec>[
        FieldSpec(
          name: 'institucionUid',
          label: 'Institución',
          type: FieldType.select,
          required: true,
          options: <FieldOption>[
            for (final i in data.instituciones)
              if (i['id'] is String)
                FieldOption(value: i['id']! as String, label: institutionLabel(i)),
          ],
        ),
        const FieldSpec(
          name: 'nombre',
          label: 'Nombre de la oferta',
          type: FieldType.text,
          required: true,
          full: true,
        ),
        const FieldSpec(
          name: 'descripcion',
          label: 'Descripción',
          type: FieldType.textarea,
          required: true,
          full: true,
        ),
        FieldSpec(
          name: 'area',
          label: 'Área',
          type: FieldType.datalist,
          required: true,
          options: <FieldOption>[
            for (final a in areas) FieldOption(value: a, label: a),
          ],
        ),
        const FieldSpec(
          name: 'nivel',
          label: 'Nivel',
          type: FieldType.select,
          required: true,
          options: <FieldOption>[
            FieldOption(value: 'Universitario', label: 'Universitario'),
            FieldOption(value: 'Terciario', label: 'Terciario'),
          ],
        ),
        const FieldSpec(
          name: 'duracionAnios',
          label: 'Duración (años)',
          type: FieldType.number,
        ),
        const FieldSpec(
          name: 'modalidad',
          label: 'Modalidad',
          type: FieldType.select,
          required: true,
          options: <FieldOption>[
            FieldOption(value: 'Presencial', label: 'Presencial'),
            FieldOption(value: 'Bimodal', label: 'Bimodal'),
            FieldOption(value: 'Virtual', label: 'Virtual'),
          ],
        ),
        const FieldSpec(
          name: 'salidaLaboral',
          label: 'Salida laboral',
          type: FieldType.text,
          full: true,
        ),
        const FieldSpec(
          name: 'requisitos',
          label: 'Requisitos',
          type: FieldType.textarea,
          full: true,
        ),
        FieldSpec(
          name: 'tag',
          label: 'Tag',
          type: FieldType.datalist,
          options: <FieldOption>[
            for (final t in tagNames) FieldOption(value: t, label: t),
          ],
        ),
        const FieldSpec(
          name: 'aprobada',
          label: 'Publicada (aprobada)',
          type: FieldType.toggle,
        ),
      ],
      rowActions: const <RowActionSpec>[
        RowActionSpec(
          action: 'aprobar',
          label: 'Aprobar',
          icon: Icons.check,
          tone: Tone.success,
          title: 'Publicar oferta',
          visible: _isPending,
          patch: <String, Object?>{'aprobada': true},
          doneMessage: 'Oferta aprobada y publicada.',
        ),
        RowActionSpec(
          action: 'desaprobar',
          label: 'Rechazar',
          icon: Icons.close,
          tone: Tone.warning,
          title: 'Quitar la aprobación',
          visible: _isApproved,
          patch: <String, Object?>{'aprobada': false},
          doneMessage: 'Oferta desaprobada (queda oculta en la app).',
        ),
        RowActionSpec(
          action: 'edit',
          label: 'Editar',
          icon: Icons.edit_outlined,
          tone: Tone.secondary,
          title: 'Editar oferta',
        ),
        RowActionSpec(
          action: 'delete',
          label: 'Eliminar',
          icon: Icons.delete_outline,
          tone: Tone.danger,
          title: 'Eliminar oferta',
        ),
      ],
    );
  }

  static bool _isPending(Map<String, Object?> row) => row['aprobada'] != true;

  static bool _isApproved(Map<String, Object?> row) => row['aprobada'] == true;

  static bool _matchAprobada(Map<String, Object?> row, String value) =>
      value == 'true' ? row['aprobada'] == true : row['aprobada'] != true;
}

/// Instituciones y tags cargados para armar el spec de Ofertas.
class _OfertasRefs {
  const _OfertasRefs(this.instituciones, this.tags);

  final List<Map<String, Object?>> instituciones;
  final List<Map<String, Object?>> tags;
}

/// Nombre legible de una institución, para la columna y el select del
/// formulario.
///
/// Hay documentos sin `nombre`: los que dejaron los triggers de Cloud
/// Functions (`eliminar_isft180_v1`, `logos_storage_v1`, que solo tienen
/// `createdAt` y `trigger`). El panel original los toleraba
/// —`instName.get(uid) || '—'`—, pero el `!` del port Dart reventaba la página
/// entera, porque el join corre dentro del `build`. Por eso la cascada es
/// explícita y nunca desreferencia.
String institutionLabel(Map<String, Object?> doc) {
  for (final key in const <String>['nombre', 'nombreCompleto']) {
    final value = doc[key];
    if (value is String && value.trim().isNotEmpty) return value;
  }
  return '(sin nombre)';
}

/// Índice `institucionUid → nombre` para el join de la tabla.
///
/// Los documentos sin `id` se descartan en vez de romper el mapa.
Map<String, String> institutionNamesById(
  List<Map<String, Object?>> instituciones,
) {
  return <String, String>{
    for (final i in instituciones)
      if (i['id'] is String) i['id']! as String: institutionLabel(i),
  };
}

/// Nombres de los tags para el datalist del formulario.
List<String> tagNamesOf(List<Map<String, Object?>> tags) {
  return <String>[
    for (final t in tags)
      if (t['nombre'] is String && '${t['nombre']}'.trim().isNotEmpty)
        t['nombre']! as String,
  ];
}
