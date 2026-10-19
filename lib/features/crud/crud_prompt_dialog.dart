import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/widgets/dialogs.dart';
import 'crud_spec.dart';

/// Diálogo de una acción declarativa que lleva prompt ([RowActionSpec.prompt]).
///
/// Muestra el detalle de la fila (si el prompt define [RowPromptSpec.detail]),
/// un campo de texto multilinea con el valor actual precargado y, si hay
/// [RowPromptSpec.toggle], un checkbox. Al confirmar entrega a [onSubmit] el
/// patch a escribir sobre el documento; recién entonces se cierra, así que si
/// la escritura falla el diálogo queda abierto con lo tipeado.
///
/// Vive fuera de `CrudPage` a propósito: no toca Firestore, así que se testea
/// aislado (ver `test/row_prompt_test.dart`).
Future<void> showRowPrompt(
  BuildContext context, {
  required RowPromptSpec prompt,
  required Doc row,
  required Future<bool> Function(Map<String, Object?> patch) onSubmit,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(text: '${row[prompt.field] ?? ''}');
  final toggle = prompt.toggle;
  // Se lee desde el `onSubmit` (que cierra después del builder), así que el
  // `StatefulBuilder` del checkbox puede mutarlo sin reconstruir el diálogo.
  var checked = toggle?.defaultValue ?? true;

  await showAppModal<void>(
    context: context,
    title: prompt.title,
    submitLabel: prompt.submitLabel,
    contentBuilder: (ctx) {
      final p = ctx.palette;
      return _DisposesController(
        controller: controller,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prompt.detail case final detail?) ...[
                detail(ctx, row),
                const SizedBox(height: 16),
              ],
              Text(
                prompt.required ? '${prompt.label} *' : prompt.label,
                style: TextStyle(
                  fontSize: AppTokens.sm,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller,
                autofocus: true,
                minLines: prompt.rows,
                maxLines: prompt.rows + 4,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: AppTokens.md,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  helperText: prompt.hint,
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  if (!prompt.required) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribí algo antes de confirmar.';
                  }
                  return null;
                },
              ),
              if (toggle != null) ...[
                const SizedBox(height: 4),
                StatefulBuilder(
                  builder: (ctx2, setLocal) {
                    final tp = ctx2.palette;
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        checked = v ?? checked;
                        setLocal(() {});
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        toggle.label,
                        style: TextStyle(
                          fontSize: AppTokens.sm,
                          color: tp.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
    onSubmit: (ctx) async {
      final form = formKey.currentState;
      if (form == null || !form.validate()) return;

      final patch = <String, Object?>{
        ...?prompt.extraPatch?.call(),
        prompt.field: controller.text.trim(),
        if (toggle != null)
          toggle.field: checked ? toggle.onValue : toggle.offValue,
      };

      final ok = await onSubmit(patch);
      if (!ok || !ctx.mounted) return;
      Navigator.of(ctx).pop();
    },
  );
}

/// Contenido del prompt, dueño del [TextEditingController].
///
/// Se libera recién al desmontar el diálogo, no al hacer pop: `showDialog`
/// completa apenas se cierra, pero la animación de salida sigue
/// reconstruyendo el contenido y ahí el controller tendría que seguir vivo
/// (soltarlo antes revienta con "A TextEditingController was used after
/// being disposed").
class _DisposesController extends StatefulWidget {
  const _DisposesController({required this.controller, required this.child});

  final TextEditingController controller;
  final Widget child;

  @override
  State<_DisposesController> createState() => _DisposesControllerState();
}

class _DisposesControllerState extends State<_DisposesController> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
