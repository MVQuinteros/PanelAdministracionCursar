import 'package:cursar_admin_flutter/core/theme/app_theme.dart';
import 'package:cursar_admin_flutter/features/crud/crud_form_dialog.dart';
import 'package:cursar_admin_flutter/features/crud/crud_spec.dart';
import 'package:cursar_admin_flutter/features/crud/instituciones_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests del módulo Instituciones.
///
/// La parte de decisión (`InstitucionesPolicy`) se testea sola, sin Firestore ni
/// widget tree: ahí viven el patrón del CUE, qué link de verificación
/// corresponde a cada institución y qué estado tiene una ficha sin `estado`.
/// Después se monta el formulario para verificar que un CUE mal escrito no deje
/// guardar y que uno válido (o vacío) sí.
void main() {
  group('InstitucionesPolicy.cueValido', () {
    test('acepta 9 dígitos y 13 con anexo', () {
      expect(InstitucionesPolicy.cueValido('061533000'), isTrue);
      expect(InstitucionesPolicy.cueValido('0615330000001'), isTrue);
      // Con espacios alrededor también vale: se normaliza.
      expect(InstitucionesPolicy.cueValido(' 060633100 '), isTrue);
    });

    test('rechaza largos y caracteres que no son dígitos', () {
      expect(InstitucionesPolicy.cueValido(null), isFalse);
      expect(InstitucionesPolicy.cueValido(''), isFalse);
      expect(InstitucionesPolicy.cueValido('06153300'), isFalse); // 8
      expect(InstitucionesPolicy.cueValido('0615330000'), isFalse); // 10
      expect(InstitucionesPolicy.cueValido('06153300A'), isFalse);
      expect(InstitucionesPolicy.cueValido('0615-33000'), isFalse);
    });
  });

  group('InstitucionesPolicy.info', () {
    test('el CUE manda y linkea a SITRARED', () {
      final info = InstitucionesPolicy.info(<String, Object?>{
        'cue': '061533000',
        'fuente': 'CUE',
        'dependeDe': 'No debería usarse',
      });
      expect(info.etiqueta, '061533000');
      expect(info.esCodigo, isTrue);
      expect(info.url, InstitucionesPolicy.sitraredUrl);
    });

    test('una universidad sin CUE se identifica por SPU', () {
      final info = InstitucionesPolicy.info(<String, Object?>{'fuente': 'SPU'});
      expect(info.etiqueta, 'SPU');
      expect(info.esCodigo, isFalse);
      expect(info.url, InstitucionesPolicy.spuUrl);
    });

    test('fuente CUE sin código no es clickeable', () {
      final info = InstitucionesPolicy.info(<String, Object?>{'fuente': 'CUE'});
      expect(info.etiqueta, 'CUE (sin código)');
      expect(info.url, isNull);
    });

    test('una sede cae en dependeDe, sin link', () {
      final info = InstitucionesPolicy.info(<String, Object?>{
        'dependeDe': 'Universidad de Buenos Aires',
      });
      expect(info.etiqueta, 'Universidad de Buenos Aires');
      expect(info.esCodigo, isFalse);
      expect(info.url, isNull);
    });

    test('sin ningún identificador muestra un guion', () {
      final info = InstitucionesPolicy.info(<String, Object?>{});
      expect(info.etiqueta, '—');
      expect(info.url, isNull);
    });
  });

  group('InstitucionesPolicy.estado', () {
    test('una ficha sin estado cuenta como pendiente', () {
      expect(InstitucionesPolicy.estado(<String, Object?>{}), 'pendiente');
      expect(InstitucionesPolicy.esPendiente(<String, Object?>{}), isTrue);
    });

    test('reconoce aprobada y rechazada', () {
      expect(
        InstitucionesPolicy.esAprobada(<String, Object?>{'estado': 'aprobada'}),
        isTrue,
      );
      expect(
        InstitucionesPolicy.esRechazada(<String, Object?>{
          'estado': 'rechazada',
        }),
        isTrue,
      );
    });
  });

  group('InstitucionesPolicy.aprobar / rechazar', () {
    test('aprobar deja el estado y limpia el motivo de rechazo', () {
      expect(InstitucionesPolicy.aprobar(), <String, Object?>{
        'estado': 'aprobada',
        'motivoRechazo': '',
      });
    });

    test('rechazar solo cambia el estado (el motivo lo trae el prompt)', () {
      expect(InstitucionesPolicy.rechazar(), <String, Object?>{
        'estado': 'rechazada',
      });
    });
  });

  group('formulario: campo CUE', () {
    /// Monta el formulario con un único campo `cue` como el del spec real.
    Future<void> pumpForm(
      WidgetTester tester, {
      required String initial,
      required List<Map<String, Object?>> guardados,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: CrudFormDialog(
              title: 'Editar institución',
              fields: <FieldSpec>[
                FieldSpec(
                  name: 'cue',
                  label: 'CUE',
                  pattern: InstitucionesPolicy.cueRegex,
                  patternMessage: 'El CUE son 9 dígitos (o 13 si incluye el anexo).',
                ),
              ],
              initialValues: <String, Object?>{'cue': initial},
              onSubmit: (values) async => guardados.add(values),
            ),
          ),
        ),
      );
    }

    testWidgets('un CUE inválido no deja guardar', (tester) async {
      final guardados = <Map<String, Object?>>[];
      await pumpForm(tester, initial: '123', guardados: guardados);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(guardados, isEmpty);
      expect(
        find.text('El CUE son 9 dígitos (o 13 si incluye el anexo).'),
        findsOneWidget,
      );
    });

    testWidgets('un CUE válido guarda', (tester) async {
      final guardados = <Map<String, Object?>>[];
      await pumpForm(tester, initial: '061533000', guardados: guardados);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(guardados, hasLength(1));
      expect(guardados.single['cue'], '061533000');
    });

    testWidgets('vacío se acepta: el CUE es opcional', (tester) async {
      final guardados = <Map<String, Object?>>[];
      await pumpForm(tester, initial: '', guardados: guardados);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(guardados, hasLength(1));
    });
  });
}
