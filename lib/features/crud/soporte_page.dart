import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/badge.dart';
import '../../data/models/catalog_models.dart'
    show NotificacionModel, SoporteModel;
import '../../data/models/model_providers.dart' hide Doc;
import 'crud_page.dart';
import 'crud_spec.dart';
import 'crud_widgets.dart';

/// Módulo Soporte: los reportes los crea la app móvil; el admin los lee, les
/// responde (el texto queda en `respuesta`, para que lo vea el usuario),
/// cambia el estado (resolver / reabrir) o los borra.
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
        key: 'respuesta',
        label: 'Respuesta',
        width: 220,
        cell: (context, row) {
          // Se mira el valor crudo: `Fmt.display` devuelve '—' para vacío y
          // entonces un reporte sin responder pasaría el `isEmpty`.
          final respuesta = '${row['respuesta'] ?? ''}'.trim();
          if (respuesta.isEmpty) return const MutedText('Sin respuesta');
          return Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 14,
                color: context.palette.success,
              ),
              const SizedBox(width: 6),
              Expanded(child: TruncatedText(respuesta)),
            ],
          );
        },
        csv: (row) => Fmt.display(row['respuesta']),
      ),
      ColumnSpec(
        key: 'createdAt',
        label: 'Recibido',
        width: 150,
        // `TruncatedText` y no `MutedText`: cuando la tabla se achica para que
        // entre la columna de Acciones, la fecha se recorta con "…" y el
        // tooltip deja ver el valor completo.
        cell: (context, row) => TruncatedText(Fmt.dateTime(row['createdAt'])),
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
    rowActions: <RowActionSpec>[
      // Responder: el prompt trae el detalle del reporte y deja escribir la
      // respuesta que verá el usuario en la app.
      RowActionSpec(
        action: 'responder',
        label: 'Responder',
        tone: Tone.primary,
        icon: Icons.reply_outlined,
        title: 'Responder reporte',
        prompt: RowPromptSpec(
          title: 'Responder reporte',
          field: 'respuesta',
          label: 'Respuesta para el usuario',
          hint: 'Se muestra en la app, junto al reporte que envió el usuario.',
          rows: 5,
          submitLabel: 'Enviar respuesta',
          doneMessage: 'Respuesta enviada al usuario.',
          detail: (context, row) => _ReporteDetalle(row: row),
          toggle: const RowPromptToggle(
            field: 'estado',
            label: 'Marcar como resuelto',
            onValue: 'resuelto',
            offValue: 'nuevo',
          ),
          extraPatch: () => <String, Object?>{
            'respondidoEn': FieldValue.serverTimestamp(),
            'respondidoPor':
                FirebaseAuth.instance.currentUser?.email ?? 'Admin',
          },
          afterSave: _notificarRespuesta,
          mail: RowPromptMail(
            to: (row) => '${row['email'] ?? ''}',
            subject: (row) => 'Respuesta a tu reporte · CURSAR',
            buildBody: (row, text) => 'Hola,\n\n'
                'Te escribimos por tu reporte de soporte:\n\n'
                '"${row['mensaje'] ?? ''}"\n\n'
                'Respuesta:\n$text\n\n'
                'Saludos,\nEquipo CURSAR',
          ),
        ),
      ),
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

  /// Deja la notificación personal en `notificaciones`, para que la app le
  /// avise al usuario que su reporte ya tiene respuesta.
  ///
  /// La app las lee filtrando por `userUid`.
  ///
  /// El destinatario sale de [SoporteModel.uidDe], que acepta `userUid` y `uid`
  /// (la app móvil escribe `uid`). Si el ticket no tiene ninguno de los dos
  /// —reportes viejos cargados a mano— no hay a quién avisarle: no se crea
  /// nada y la respuesta se guarda igual.
  static Future<void> _notificarRespuesta(
    BuildContext context,
    Doc row,
    Map<String, Object?> patch,
  ) async {
    final uid = SoporteModel.uidDe(row);
    if (uid.isEmpty) return;

    await NotificacionModel().add(<String, Object?>{
      'userUid': uid,
      'titulo': 'Respondimos tu reporte',
      'mensaje': 'Ya está la respuesta a tu reporte de soporte. '
          'Entrá a la app para verla.',
      'respuesta': '${patch['respuesta'] ?? ''}',
      'leido': false,
      'fecha': FieldValue.serverTimestamp(),
      'tipo': 'soporte',
      'soporteId': '${row['id'] ?? ''}',
    });
  }

  static bool _isResolved(Map<String, Object?> row) => row['estado'] == 'resuelto';

  static bool _isNotResolved(Map<String, Object?> row) =>
      row['estado'] != 'resuelto';

  @override
  Widget build(BuildContext context) {
    return CrudPage(spec: spec);
  }
}

/// Detalle del reporte dentro del diálogo de respuesta.
///
/// En la tabla el mensaje se ve truncado; acá se muestra entero, con quién lo
/// envió y cuándo, para poder contestar sin adivinar.
class _ReporteDetalle extends StatelessWidget {
  const _ReporteDetalle({required this.row});

  final Doc row;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mensaje = Fmt.display(row['mensaje']);
    final email = Fmt.display(row['email']);
    final uid = SoporteModel.uidDe(row);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge('${row['tipo'] ?? 'General'}', tone: Tone.neutral),
              const SizedBox(width: 8),
              Expanded(
                child: MutedText('Recibido ${Fmt.dateTime(row['createdAt'])}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DetailRow(label: 'De', value: email.isEmpty ? '—' : email),
          if (uid.isNotEmpty) ...[
            const SizedBox(height: 4),
            _DetailRow(label: 'Usuario', value: uid),
          ],
          const SizedBox(height: 12),
          Text(
            'MENSAJE',
            style: TextStyle(
              fontSize: AppTokens.xs,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mensaje.isEmpty ? '—' : mensaje,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: AppTokens.md,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila etiqueta/valor del detalle del reporte.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(fontSize: AppTokens.xs, color: p.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppTokens.sm,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
