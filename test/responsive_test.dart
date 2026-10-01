import 'package:cursar_admin_flutter/core/theme/app_theme.dart';
import 'package:cursar_admin_flutter/core/theme/tone.dart';
import 'package:cursar_admin_flutter/core/widgets/app_button.dart';
import 'package:cursar_admin_flutter/core/widgets/dialogs.dart';
import 'package:cursar_admin_flutter/core/widgets/toast.dart';
import 'package:cursar_admin_flutter/features/auth/auth_controller.dart';
import 'package:cursar_admin_flutter/features/auth/login_page.dart';
import 'package:cursar_admin_flutter/features/crud/crud_form_dialog.dart';
import 'package:cursar_admin_flutter/features/crud/crud_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/layout_harness.dart';

/// Tests de layout de las superficies flotantes y de las que `layout_test.dart`
/// no cubría: formulario, diálogos, toast y login.
///
/// Motivo: son las que se abren encima del contenido, así que no siguen la
/// caja de contenido de `AppShell` y se pueden salir de la pantalla sin que
/// ningún test las mire. Acá se las fuerza a los anchos donde más duelen.
void main() {
  late List<String> layoutErrors;

  setUp(() => layoutErrors = installLayoutErrorCapture());
  tearDown(removeLayoutErrorCapture);

  group('formulario', () {
    for (final entry in floatingViewports.entries) {
      testWidgets('no desborda a ${entry.key}', (tester) async {
        await pumpForm(tester, entry.value);

        expect(find.byType(CrudFormDialog), findsOneWidget);
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }

    testWidgets('a 1280 los campos van de a dos', (tester) async {
      await pumpForm(tester, const Size(1280, 800));

      // Mismo `dy` = misma fila del grid de 2 columnas. El label lleva el
      // asterisco de obligatorio: `_Field` arma `'${spec.label} *'`.
      expect(
        tester.getTopLeft(find.text('Área *')).dy,
        tester.getTopLeft(find.text('Institución')).dy,
      );
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    for (final entry in <String, Size>{
      '420x860': const Size(420, 860),
      '360x640': const Size(360, 640),
    }.entries) {
      testWidgets('a ${entry.key} los campos van de a uno', (tester) async {
        await pumpForm(tester, entry.value);

        // `dy` mayor = está en la fila de abajo, no al lado.
        expect(
          tester.getTopLeft(find.text('Institución')).dy,
          greaterThan(tester.getTopLeft(find.text('Área *')).dy),
        );
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }

    for (final entry in floatingViewports.entries) {
      testWidgets('el desplegable del datalist entra a ${entry.key}', (
        tester,
      ) async {
        await pumpForm(tester, entry.value);

        // El `datalist` filtra por lo que se escribe (`optionsBuilder` compara contra
        // `value.text`), así que hay que escribir algo que matchee: con el
        // valor inicial no matchea ninguna opción y la lista no abre.
        final field = find.descendant(
          of: find.byType(RawAutocomplete<FieldOption>),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(field, 'tec');
        await settle(tester);

        // Las opciones se abren en un overlay propio con `maxWidth` fijo: es lo
        // que más se sale en pantallas chicas.
        expect(find.text('Instituto de Tecnología'), findsOneWidget);

        final rect = tester.getRect(find.text('Instituto de Tecnología'));
        expect(
          rect.left,
          greaterThanOrEqualTo(0),
          reason: 'la opción arranca en $rect.left, fuera de pantalla',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(entry.value.width),
          reason: 'la opción termina en ${rect.right}, fuera de pantalla',
        );
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }
  });

  group('diálogos', () {
    for (final entry in floatingViewports.entries) {
      testWidgets('la confirmación no desborda a ${entry.key}', (tester) async {
        await pumpLauncher(
          tester,
          entry.value,
          (context) => confirmDialog(
            context,
            title: 'Borrar la oferta "Técnico Superior en Programación y '
                'Desarrollo de Software con especialización en cloud"?',
            message: 'Esta acción no se puede deshacer. Si la oferta tiene '
                'postulaciones asociadas, también se van a borrar.',
            confirmLabel: 'Borrar',
            danger: true,
          ),
        );

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });

      testWidgets('el modal no desborda a ${entry.key}', (tester) async {
        await pumpLauncher(
          tester,
          entry.value,
          (context) => showAppModal<void>(
            context: context,
            title: 'Exportar ofertas',
            submitLabel: 'Exportar',
            onSubmit: (_) async {},
            contentBuilder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Se genera un CSV con todas las ofertas filtradas y se '
                  'descarga al dispositivo. El proceso puede tardar un poco '
                  'si hay muchas ofertas cargadas.',
                ),
                const SizedBox(height: 16),
                // Fila de acciones con labels cortos: tiene que entrar en el modal. Los
                // labels largos van en el botón de bloque de abajo, que sí
                // puede envolver el texto.
                Row(
                  children: <Widget>[
                    AppButton(
                      label: 'CSV',
                      tone: Tone.secondary,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Excel',
                      tone: Tone.secondary,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const AppButton(
                  label: 'Descargar CSV con todas las ofertas filtradas',
                  block: true,
                ),
              ],
            ),
          ),
        );

        expect(find.byType(Dialog), findsOneWidget);
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }
  });

  group('toast', () {
    for (final entry in floatingViewports.entries) {
      testWidgets('entra entero a ${entry.key}', (tester) async {
        late BuildContext ctx;
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = entry.value;
        addTearDown(() => tester.view.reset());

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

        toast(ctx, 'Oferta aprobada correctamente', kind: ToastKind.success);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // El toast va con `Positioned(right: 20, width: 320)`: si no se le
        // clampa el ancho, en pantallas de menos de 340px se sale por la
        // izquierda. `getRect` mide el texto, que va con el `Expanded` de la
        // tarjeta, así que si el borde izquierdo es negativo lo detecta.
        // El toast va con `Positioned(right: 20, width: 320)`. Hay que medir la
        // TARJETA, no el texto: el texto arranca ~18px más adentro (padding +
        // punto + gap), así que sigue en pantalla aunque la tarjeta ya se haya
        // salido por la izquierda. El `GestureDetector` es el hijo directo del
        // `Positioned`, así que su rect es el de la tarjeta.
        final card = find.ancestor(
          of: find.text('Oferta aprobada correctamente'),
          matching: find.byType(GestureDetector),
        );
        final rect = tester.getRect(card.first);

        expect(
          rect.left,
          greaterThanOrEqualTo(0),
          reason: 'la tarjeta arranca en ${rect.left}, fuera de pantalla',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(entry.value.width),
          reason: 'la tarjeta termina en ${rect.right}, fuera de pantalla',
        );
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));

        // Dejar que se auto-cierre: si queda vivo, el timer de 4.2 s dispara
        // "A Timer is still pending" al final del test.
        await tester.pump(const Duration(milliseconds: 4200));
        await tester.pumpAndSettle();
      });
    }
  });

  group('login', () {
    for (final entry in floatingViewports.entries) {
      testWidgets('no desborda a ${entry.key}', (tester) async {
        await pumpLogin(tester, entry.value);

        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.text('Entrar'), findsOneWidget);
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }

    testWidgets('el hint largo no desborda a 320x640', (tester) async {
      await pumpLogin(tester, const Size(320, 640));

      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });
  });
}

/// Abre un launcher genérico y dispara la acción, para poder testear cualquier
/// diálogo/toast sin repetir el andamiaje en cada test.
Future<void> pumpLauncher(
  WidgetTester tester,
  Size size,
  Future<void> Function(BuildContext) launch,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() => tester.view.reset());

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => launch(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await settle(tester);
}

/// Monta el login con el controlador de sesión falso: el real se suscribe a
/// `FirebaseAuth.instance` en `build()`, y sin inicializar eso revienta.
Future<void> pumpLogin(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() => tester.view.reset());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const LoginPage()),
    ),
  );

  await settle(tester);
}

Future<void> pumpForm(WidgetTester tester, Size size) async {
  await pumpLauncher(tester, size, (context) {
    return showDialog<void>(
      context: context,
      builder: (_) => CrudFormDialog(
        title: 'Editar oferta',
        fields: _ofertaFields,
        initialValues: _ofertaValues,
        onSubmit: (_) async {},
      ),
    );
  });
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

// ---------------------------------------------------------------------------
// Datos de prueba
// ---------------------------------------------------------------------------

const _institucionElegida = 'Instituto Centroamericano de Estudios';

const _ofertaFields = <FieldSpec>[
  FieldSpec(
    name: 'nombre',
    label: 'Carrera',
    required: true,
    full: true,
    placeholder: 'Técnico Superior en Programación',
  ),
  FieldSpec(
    name: 'area',
    label: 'Área',
    type: FieldType.select,
    required: true,
    options: <FieldOption>[
      FieldOption(value: 'Tecnología', label: 'Tecnología'),
      FieldOption(value: 'Salud', label: 'Salud'),
      FieldOption(value: 'Educación', label: 'Educación'),
    ],
  ),
  // `datalist`: el tipo que exige `focusNode` junto al controller.
  FieldSpec(
    name: 'institucion',
    label: 'Institución',
    type: FieldType.datalist,
    options: <FieldOption>[
      FieldOption(value: 'Instituto de Tecnología', label: 'Instituto de Tecnología'),
      FieldOption(
        value: 'Centro Universitario de Salud',
        label: 'Centro Universitario de Salud',
      ),
      FieldOption(
        value: 'Escuela Normal Superior',
        label: 'Escuela Normal Superior',
      ),
    ],
  ),
  FieldSpec(name: 'cupos', label: 'Cupos', type: FieldType.number),
  FieldSpec(name: 'inicio', label: 'Inicio', type: FieldType.date),
  FieldSpec(
    name: 'descripcion',
    label: 'Descripción',
    type: FieldType.textarea,
    rows: 4,
    full: true,
  ),
  FieldSpec(
    name: 'destacada',
    label: 'Destacada en la portada',
    type: FieldType.toggle,
  ),
];

const _ofertaValues = <String, Object?>{
  'nombre': 'Técnico Superior en Programación y Desarrollo de Software con '
      'especialización en cloud computing y arquitectura de sistemas',
  'area': 'Tecnología',
  'institucion': _institucionElegida,
  'cupos': 30,
  'inicio': '2024-03-01',
  'descripcion':
      'Carrera de tres años con foco en desarrollo web, bases de datos y '
      'despliegue en la nube. Requiere conocimientos prévios de álgebra y '
      'lógica, y se artiicula con el último año de la escuela secundaria.',
  'destacada': true,
};