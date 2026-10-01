import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/model_providers.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Test vocacional.
///
/// Solo lectura: los resultados los guarda la app móvil cuando un usuario
/// completa el test. El admin consulta y puede limpiar.
class TestVocacionalPage extends StatelessWidget {
  const TestVocacionalPage({super.key});

  static final CrudSpec spec = CrudSpec(
    title: 'Test vocacional',
    subtitle: 'Resultados generados en la app',
    allowAdd: false,
    autoTimestamp: false,
    loader: (ref) => ref.read(testResultadoModelProvider).list(),
    bannerText:
        'Los resultados los guarda la app móvil cuando un usuario completa el '
        'test (área de interés + ofertas recomendadas). Este módulo solo '
        'consulta y permite limpiar resultados.',
    filters: const <FilterSpec>[
      FilterSpec(key: 'areaInteres', label: 'Área de interés'),
      FilterSpec(key: 'createdAt', label: 'Fecha', type: FilterType.dateRange),
    ],
    columns: <ColumnSpec>[
      ColumnSpec(
        key: 'userUid',
        label: 'Usuario',
        width: 230,
        cell: (context, row) => _usuarioCell(row),
        csv: (row) => _usuarioCsv(row),
      ),
      ColumnSpec(
        key: 'areaInteres',
        label: 'Área de interés',
        width: 170,
        cell: (context, row) => StatusBadge(
          '${row['areaInteres'] ?? 'Sin área'}',
          tone: _areaTone(row['areaInteres']),
        ),
        csv: (row) => '${row['areaInteres'] ?? ''}',
      ),
      ColumnSpec(
        key: 'ofertasRecomendadas',
        label: 'Ofertas recomendadas',
        width: 170,
        cell: (context, row) {
          final list = row['ofertasRecomendadas'];
          final n = list is List ? list.length : 0;
          return StatusBadge('$n', tone: Tone.info);
        },
        csv: (row) {
          final list = row['ofertasRecomendadas'];
          return list is List ? list.join(', ') : '';
        },
      ),
      ColumnSpec(
        key: 'createdAt',
        label: 'Fecha',
        width: 150,
        cell: (context, row) => MutedText(Fmt.dateTime(row['createdAt'])),
        csv: (row) => Fmt.dateTime(row['createdAt']),
      ),
    ],
    rowActions: const <RowActionSpec>[
      RowActionSpec(
        action: 'delete',
        label: 'Eliminar',
        icon: Icons.delete_outline,
        tone: Tone.danger,
        title: 'Eliminar resultado del test',
      ),
    ],
  );

  /// Nombre + email del usuario unido, o el uid crudo con badge "sin cuenta".
  static Widget _usuarioCell(Map<String, Object?> row) {
    final usuario = row['_usuario'];
    if (usuario is Map<String, Object?>) {
      final nombre = [usuario['nombre'], usuario['apellido']]
          .where((v) => v != null && '$v'.trim().isNotEmpty)
          .map((v) => '$v'.trim())
          .join(' ');
      final email = '${usuario['email'] ?? ''}';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          StrongText(nombre.isEmpty ? (email.isEmpty ? 'Usuario' : email) : nombre),
          if (email.isNotEmpty) MutedText(email, fontSize: 12),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: MutedText('${row['userUid'] ?? ''}')),
        const SizedBox(width: 6),
        const StatusBadge('sin cuenta', tone: Tone.warning),
      ],
    );
  }

  static String _usuarioCsv(Map<String, Object?> row) {
    final usuario = row['_usuario'];
    if (usuario is Map<String, Object?>) {
      final nombre = [usuario['nombre'], usuario['apellido']]
          .where((v) => v != null && '$v'.trim().isNotEmpty)
          .map((v) => '$v'.trim())
          .join(' ');
      final email = '${usuario['email'] ?? ''}';
      return email.isEmpty ? nombre : '$nombre ($email)';
    }
    return '${row['userUid'] ?? ''}';
  }

  /// Equivale al mapa `AREA_TONE` del controlador original.
  static Tone _areaTone(Object? area) => switch ('${area ?? ''}') {
    'Tecnología' => Tone.purple,
    'Ingeniería' => Tone.info,
    'Salud' => Tone.success,
    'Educación' => Tone.warning,
    'Creativa' => Tone.danger,
    'Administración' => Tone.info,
    'Economía' => Tone.success,
    'Derecho' => Tone.warning,
    _ => Tone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}
