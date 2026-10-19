import 'package:cursar_admin_flutter/core/theme/app_theme.dart';
import 'package:cursar_admin_flutter/core/widgets/app_button.dart';
import 'package:cursar_admin_flutter/features/crud/crud_prompt_dialog.dart';
import 'package:cursar_admin_flutter/features/crud/crud_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/layout_harness.dart';

/// Tests del diálogo de las acciones con prompt (`RowActionSpec.prompt`).
///
/// `showRowPrompt` no toca Firestore: arma el patch y lo entrega por callback,
/// así que acá se cubre lo que importa (detalle, precarga, validación, toggle
/// y cierre condicional) sin dobles ni inicializar Firebase.
void main() {
  late List<String> layoutErrors;

  setUp(() => layoutErrors = installLayoutErrorCapture());
  tearDown(removeLayoutErrorCapture);

  final row = <String, Object?>{
    'id': 's1',
    'tipo': 'problema',
    'email': 'ana@mail.com',
    'userUid': 'uid-1',
    'mensaje': 'No puedo iniciar sesión desde el celular.',
    'respuesta': 'Ya lo revisamos.',
    'estado': 'nuevo',
  };

  /// Futuro del diálogo abierto; se espera al final de cada test.
  late Future<void> dialog;

  RowPromptSpec prompt({
    RowPromptToggle? toggle,
    Map<String, Object?> Function()? extraPatch,
    bool required = true,
  }) {
    return RowPromptSpec(
      title: 'Responder reporte',
      field: 'respuesta',
      label: 'Respuesta para el usuario',
      hint: 'Se muestra en la app, junto al reporte.',
      rows: 3,
      submitLabel: 'Enviar respuesta',
      doneMessage: 'Respuesta enviada al usuario.',
      required: required,
      detail: (context, r) => Text('Detalle: ${r['mensaje']}'),
      toggle: toggle,
      extraPatch: extraPatch,
    );
  }

  const conResuelto = RowPromptToggle(
    field: 'estado',
    label: 'Marcar como resuelto',
    onValue: 'resuelto',
    offValue: 'nuevo',
  );

  Future<void> openPrompt(
    WidgetTester tester, {
    required RowPromptSpec spec,
    required Future<bool> Function(Map<String, Object?> patch) onSubmit,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    dialog = showRowPrompt(
      ctx,
      prompt: spec,
      row: row,
      onSubmit: onSubmit,
    );
    await tester.pumpAndSettle();
  }

  Future<void> closeCancelling(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    await dialog;
  }

  group('showRowPrompt', () {
    testWidgets('muestra el detalle y precarga la respuesta actual', (
      tester,
    ) async {
      await openPrompt(tester, spec: prompt(), onSubmit: (_) async => true);

      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.text('Detalle: No puedo iniciar sesión desde el celular.'),
        findsOneWidget,
        reason: 'el mensaje completo no aparece en el diálogo',
      );
      expect(
        find.text('Ya lo revisamos.'),
        findsOneWidget,
        reason: 'la respuesta existente no se precargó en el campo',
      );
      expect(find.text('Enviar respuesta'), findsOneWidget);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));

      await closeCancelling(tester);
    });

    testWidgets('no confirma con el campo vacío', (tester) async {
      var called = false;
      await openPrompt(
        tester,
        spec: prompt(),
        onSubmit: (_) async {
          called = true;
          return true;
        },
      );

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.widgetWithText(AppButton, 'Enviar respuesta'));
      await tester.pump();

      expect(called, isFalse, reason: 'confirmó sin escribir nada');
      expect(find.text('Escribí algo antes de confirmar.'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));

      await closeCancelling(tester);
    });

    testWidgets('arma el patch con el texto, extraPatch y el toggle activo', (
      tester,
    ) async {
      Map<String, Object?>? saved;
      await openPrompt(
        tester,
        spec: prompt(
          toggle: conResuelto,
          extraPatch: () => <String, Object?>{'respondidoPor': 'admin@x'},
        ),
        onSubmit: (patch) async {
          saved = patch;
          return true;
        },
      );

      await tester.enterText(find.byType(TextFormField), '  Te ayudamos.  ');
      await tester.tap(find.widgetWithText(AppButton, 'Enviar respuesta'));
      await tester.pumpAndSettle();

      expect(
        saved,
        <String, Object?>{
          'respondidoPor': 'admin@x',
          'respuesta': 'Te ayudamos.',
          'estado': 'resuelto',
        },
        reason: 'el patch no armó bien lo que hay que grabar',
      );
      expect(find.byType(Dialog), findsNothing, reason: 'no se cerró');
      await dialog;
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('desmarcando el toggle escribe el valor apagado', (
      tester,
    ) async {
      Map<String, Object?>? saved;
      await openPrompt(
        tester,
        spec: prompt(toggle: conResuelto),
        onSubmit: (patch) async {
          saved = patch;
          return true;
        },
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Seguimos revisando.');
      await tester.tap(find.widgetWithText(AppButton, 'Enviar respuesta'));
      await tester.pumpAndSettle();

      expect(saved?['estado'], 'nuevo');
      expect(saved?['respuesta'], 'Seguimos revisando.');
      await dialog;
    });

    testWidgets('si la escritura falla el diálogo sigue abierto', (
      tester,
    ) async {
      var called = false;
      await openPrompt(
        tester,
        spec: prompt(),
        onSubmit: (_) async {
          called = true;
          return false;
        },
      );

      await tester.enterText(find.byType(TextFormField), 'Respuesta');
      await tester.tap(find.widgetWithText(AppButton, 'Enviar respuesta'));
      await tester.pumpAndSettle();

      expect(called, isTrue, reason: 'no intentó grabar');
      expect(
        find.byType(Dialog),
        findsOneWidget,
        reason: 'perdió lo tipeado al fallar la escritura',
      );

      await closeCancelling(tester);
    });

    testWidgets('cancelar no llama a onSubmit', (tester) async {
      var called = false;
      await openPrompt(
        tester,
        spec: prompt(),
        onSubmit: (_) async {
          called = true;
          return true;
        },
      );

      await closeCancelling(tester);

      expect(called, isFalse);
      expect(find.byType(Dialog), findsNothing);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });
  });
}
