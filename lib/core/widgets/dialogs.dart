import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/cursar_palette.dart';
import '../theme/tone.dart';
import 'app_button.dart';

/// Diálogo de confirmación que devuelve `true`/`false`.
///
/// Sustuye al `confirmDialog` de `js/views/notify.js` (que usaba un modal
/// propio); acá usamos `showDialog` con [AlertDialog].
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool danger = false,
}) async {
  final p = context.palette;
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          color: p.textPrimary,
          fontSize: AppTokens.xl,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(color: p.textSecondary, fontSize: AppTokens.md),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancelar',
            style: TextStyle(color: p.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        danger
            ? AppButton(
                label: confirmLabel,
                tone: Tone.danger,
                onPressed: () => Navigator.of(ctx).pop(true),
              )
            : AppButton(
                label: confirmLabel,
                tone: Tone.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
      ],
    ),
  );
  return ok ?? false;
}

/// Diálogo genérico con contenido libre. Devuelve el resultado de [onSubmit]
/// o `null` si se cancela.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder contentBuilder,
  String submitLabel = 'Guardar',
  bool danger = false,
  Future<void> Function(BuildContext context)? onSubmit,
  double maxWidth = 620,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    barrierDismissible: true,
    builder: (ctx) {
      final p = ctx.palette;
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: BorderSide(color: p.borderSubtle),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // head
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: AppTokens.xl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      color: p.textSecondary,
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: contentBuilder(ctx),
                ),
              ),
              // Pie con los botones; se oculta si no hay acción de submit.
              if (onSubmit case final submit?)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Wrap(
                    // Ver `_Footer` en `crud_form_dialog.dart`: `Row` desborda
                    // en pantallas angostas, `Wrap` salta de línea.
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: p.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: submitLabel,
                        tone: danger ? Tone.danger : Tone.primary,
                        onPressed: () async {
                          await submit(ctx);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Copia texto al portapapeles con feedback en un snackbar.
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Copiado al portapapeles')),
  );
}
