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
/// así que acá se cubre lo que importa (detalle, precarga, validación, toggle,
/// cierre condicional, `afterSave` y el botón de mail) sin dobles ni
/// inicializar Firebase.
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
    Future<void> Function(BuildContext, Doc, Map<String, Object?>)? afterSave,
    RowPromptMail? mail,
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
      afterSave: afterSave,
      mail: mail,
    );
  }

  const conResuelto = RowPromptToggle(
    field: 'estado',
    label: 'Marcar como resuelto',
    onValue: 'resuelto',
    offValue: 'nuevo',
  );

  RowPromptMail mailPara(String to) {
    return RowPromptMail(
      to: (_) => to,
      subject: (_) => 'Respuesta a tu reporte',
      buildBody: (_, text) => 'Hola,\n\n$text',
    );
  }

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

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Enviar respuesta'));
    await tester.pumpAndSettle();
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
      await confirm(tester);

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
      await confirm(tester);

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
      await confirm(tester);

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
      await confirm(tester);

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

  group('afterSave', () {
    testWidgets('se llama con el patch después de guardar', (tester) async {
      Map<String, Object?>? recibido;
      var filas = 0;
      await openPrompt(
        tester,
        spec: prompt(
          afterSave: (ctx, r, patch) async {
            filas++;
            recibido = patch;
          },
        ),
        onSubmit: (_) async => true,
      );

      await tester.enterText(find.byType(TextFormField), 'Listo');
      await confirm(tester);

      expect(filas, 1, reason: 'no se avisó después de guardar');
      expect(recibido?['respuesta'], 'Listo');
      expect(find.byType(Dialog), findsNothing);
      await dialog;
    });

    testWidgets('no se llama si el guardado falla', (tester) async {
      var filas = 0;
      await openPrompt(
        tester,
        spec: prompt(afterSave: (ctx, r, patch) async => filas++),
        onSubmit: (_) async => false,
      );

      await tester.enterText(find.byType(TextFormField), 'Listo');
      await confirm(tester);

      expect(filas, 0, reason: 'avisó pese a que no se guardó');
      await closeCancelling(tester);
    });

    testWidgets('no se llama al cancelar', (tester) async {
      var filas = 0;
      await openPrompt(
        tester,
        spec: prompt(afterSave: (ctx, r, patch) async => filas++),
        onSubmit: (_) async => true,
      );

      await closeCancelling(tester);

      expect(filas, 0);
    });

    testWidgets('si falla, avisa y cierra igual', (tester) async {
      await openPrompt(
        tester,
        spec: prompt(
          afterSave: (ctx, r, patch) async => throw StateError('sin permiso'),
        ),
        onSubmit: (_) async => true,
      );

      await tester.enterText(find.byType(TextFormField), 'Listo');
      await confirm(tester);

      expect(
        find.text('Se guardó la respuesta, pero no se pudo avisar en la app.'),
        findsOneWidget,
      );
      expect(
        find.byType(Dialog),
        findsNothing,
        reason: 'la respuesta ya estaba guardada: no debe quedar el diálogo',
      );
      await dialog;
    });
  });

  group('botón Enviar por mail', () {
    testWidgets('aparece cuando el prompt lo define', (tester) async {
      await openPrompt(
        tester,
        spec: prompt(mail: mailPara('ana@mail.com')),
        onSubmit: (_) async => true,
      );

      expect(find.widgetWithText(AppButton, 'Enviar por mail'), findsOneWidget);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));

      await closeCancelling(tester);
    });

    testWidgets('no aparece si el prompt no lo define', (tester) async {
      await openPrompt(tester, spec: prompt(), onSubmit: (_) async => true);

      expect(find.widgetWithText(AppButton, 'Enviar por mail'), findsNothing);

      await closeCancelling(tester);
    });

    testWidgets('queda deshabilitado si el ticket no tiene email', (
      tester,
    ) async {
      await openPrompt(
        tester,
        spec: prompt(mail: mailPara('')),
        onSubmit: (_) async => true,
      );

      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Enviar por mail'),
      );
      expect(button.onPressed, isNull);

      await closeCancelling(tester);
    });

    testWidgets('el mail sale con el texto actual del campo', (tester) async {
      String? textoUsado;
      var abiertos = 0;
      await openPrompt(
        tester,
        spec: prompt(
          mail: RowPromptMail(
            to: (_) => 'ana@mail.com',
            subject: (_) => 'Respuesta a tu reporte',
            buildBody: (_, text) {
              abiertos++;
              textoUsado = text;
              return 'Hola,\n\n$text';
            },
          ),
        ),
        onSubmit: (_) async => true,
      );

      await tester.enterText(find.byType(TextFormField), 'Probando el mail');
      await tester.tap(find.widgetWithText(AppButton, 'Enviar por mail'));
      await tester.pump();

      expect(abiertos, 1, reason: 'no se armó el mail');
      expect(
        textoUsado,
        'Probando el mail',
        reason: 'el cuerpo quedó con el texto de antes de escribir',
      );

      await closeCancelling(tester);
    });
  });
}
