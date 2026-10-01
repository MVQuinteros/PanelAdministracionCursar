import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/model_providers.dart';
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Soporte: los reportes los crea la app móvil, el admin solo cambia
/// el estado (resolver / reabrir) o los borra.
class SoportePage extends StatelessWidget {
  const SoportePage({super.key});

  static final CrudSpec spec = CrudSpec(
    title: 'Soporte',
    subtitle: 'Reportes y consultas enviados desde la app',
    allowAdd: false,
    autoTimestamp: false,
    loader: (ref) => ref.read(soporteModelProvider).list(),
    bannerText:
        'Marcá los reportes como resuelto cuando estén atendidos para '
        'ordenar la bandeja.',
    filters: const <FilterSpec>[
      FilterSpec(key: 'tipo', label: 'Tipo'),
      FilterSpec(
        key: 'estado',
        label: 'Estado',
        options: <FieldOption>[
          FieldOption(value: 'nuevo', label: 'Nuevo'),
          FieldOption(value: 'resuelto', label: 'Resuelto'),
        ],
      ),
      FilterSpec(key: 'createdAt', label: 'Recibido', type: FilterType.dateRange),
    ],
    columns: <ColumnSpec>[
      ColumnSpec(
        key: 'email',
        label: 'Email',
        width: 220,
        cell: (context, row) => StrongText(Fmt.display(row['email'])),
        csv: (row) => Fmt.display(row['email']),
      ),
      ColumnSpec(
        key: 'tipo',
        label: 'Tipo',
        width: 130,
        cell: (context, row) => StatusBadge(
          '${row['tipo'] ?? 'General'}',
          tone: Tone.neutral,
        ),
        csv: (row) => '${row['tipo'] ?? ''}',
      ),
      ColumnSpec(
        key: 'mensaje',
        label: 'Mensaje',
        width: 340,
        cell: (context, row) => TruncatedText(Fmt.display(row['mensaje'])),
        csv: (row) => Fmt.display(row['mensaje']),
      ),
      ColumnSpec(
        key: 'createdAt',
        label: 'Recibido',
        width: 150,
        cell: (context, row) => MutedText(Fmt.dateTime(row['createdAt'])),
        csv: (row) => Fmt.dateTime(row['createdAt']),
      ),
      ColumnSpec(
        key: 'estado',
        label: 'Estado',
        width: 120,
        cell: (context, row) => row['estado'] == 'resuelto'
            ? const StatusBadge('Resuelto', tone: Tone.success)
            : const StatusBadge('Nuevo', tone: Tone.warning),
        csv: (row) => '${row['estado'] ?? 'nuevo'}',
      ),
    ],
    rowActions: const <RowActionSpec>[
      RowActionSpec(
        action: 'resolver',
        label: 'Resolver',
        tone: Tone.success,
        icon: Icons.check,
        title: 'Marcar como resuelto',
        visible: _isNotResolved,
        patch: <String, Object?>{'estado': 'resuelto'},
        doneMessage: 'Reporte marcado como resuelto.',
      ),
      RowActionSpec(
        action: 'reabrir',
        label: 'Reabrir',
        tone: Tone.warning,
        title: 'Reabrir reporte',
        visible: _isResolved,
        patch: <String, Object?>{'estado': 'nuevo'},
        doneMessage: 'Reporte reabierto.',
      ),
      RowActionSpec(
        action: 'delete',
        label: 'Eliminar',
        tone: Tone.danger,
        icon: Icons.delete_outline,
        title: 'Eliminar reporte',
      ),
    ],
  );

  static bool _isResolved(Map<String, Object?> row) => row['estado'] == 'resuelto';

  static bool _isNotResolved(Map<String, Object?> row) =>
      row['estado'] != 'resuelto';

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}
