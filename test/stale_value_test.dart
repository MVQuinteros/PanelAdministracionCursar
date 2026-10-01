import 'package:cursar_admin_flutter/core/theme/app_theme.dart';
import 'package:cursar_admin_flutter/features/crud/crud_form_dialog.dart';
import 'package:cursar_admin_flutter/features/crud/crud_spec.dart';
import 'package:cursar_admin_flutter/features/crud/crud_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de regresión para los valores "colgando" de los desplegables.
///
/// `DropdownButton` y `DropdownButtonFormField` assertan cuando el `value` /
/// `initialValue` no corresponde a ningún item. Eso pasaba de verdad en dos
/// lugares del CRUD, y en ambos el assert caía la página entera (no solo el
/// diálogo o la toolbar):
///
///  - El formulario carga el valor guardado en el documento, pero las opciones
///    vienen de los datos actuales. Si la institución o el tag referenciado
///    fue borrado, el `initialValue` ya no está en la lista.
///  - Las opciones de un filtro dinámico se derivan de las filas cargadas. Si
///    el usuario tiene `Área = Tecnología` seleccionado y borra o busca hasta
///    que no queda ninguna oferta de esa área, la recarga arma el desplegable
///    sin ese valor mientras la selección sigue activa.
///
/// Ninguno de los dos se detecta con `flutter analyze`.

/// Se puede mutar desde el test para simular que las filas cambian entre
/// cargas (por ejemplo, un borrado que se lleva la última del área).
final _liveRows = <Map<String, Object?>>[
  <String, Object?>{'id': '1', 'nombre': 'Técnico', 'area': 'Tecnología'},
  <String, Object?>{
    'id': '2',
    'nombre': 'Licenciatura',
    'area': 'Administración',
  },
];

CrudSpec _spec() => CrudSpec(
  title: 'Ofertas',
  subtitle: 'test',
  loader: (ref) async => List<Map<String, Object?>>.from(_liveRows),
  filters: <FilterSpec>[const FilterSpec(key: 'area', label: 'Área')],
  columns: <ColumnSpec>[],
);

void main() {
  setUp(() {
    _liveRows
      ..clear()
      ..addAll(<Map<String, Object?>>[
        <String, Object?>{'id': '1', 'nombre': 'Técnico', 'area': 'Tecnología'},
        <String, Object?>{
          'id': '2',
          'nombre': 'Licenciatura',
          'area': 'Administración',
        },
      ]);
  });

  group('CrudFormDialog con un select cuyo valor ya no existe', () {
    testWidgets('no dispara el assert de DropdownButtonFormField', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: CrudFormDialog(
              title: 'Editar oferta',
              fields: const <FieldSpec>[
                FieldSpec(
                  name: 'institucionUid',
                  label: 'Institución',
                  type: FieldType.select,
                  required: true,
                  options: <FieldOption>[
                    FieldOption(value: 'inst-ok', label: 'ISFT 180'),
                    FieldOption(value: 'inst-2', label: 'UTN'),
                  ],
                ),
              ],
              // La institución referenciada ya no está en `options`.
              initialValues: <String, Object?>{'institucionUid': 'inst-borrada'},
              onSubmit: (_) async {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // El valor conservado tiene que quedar visible como opción de respaldo,
      // para que el admin pueda corregir la referencia en vez de perderla.
      expect(find.textContaining('inst-borrada'), findsWidgets);
    });

    testWidgets('no agrega respaldo cuando el valor sí existe', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: CrudFormDialog(
              title: 'Editar oferta',
              fields: const <FieldSpec>[
                FieldSpec(
                  name: 'institucionUid',
                  label: 'Institución',
                  type: FieldType.select,
                  options: <FieldOption>[
                    FieldOption(value: 'inst-ok', label: 'ISFT 180'),
                  ],
                ),
              ],
              initialValues: <String, Object?>{'institucionUid': 'inst-ok'},
              onSubmit: (_) async {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('no disponible'), findsNothing);
    });
  });

  group('CrudToolbar con un filtro cuya selección ya no existe', () {
    testWidgets('no dispara el assert de DropdownButton', (tester) async {
      final provider = crudProviderFor(_spec());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: CrudToolbar(
                spec: _spec(),
                provider: provider,
                onAdd: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CrudToolbar)),
      );

      // Se selecciona un área que sí existe entre las filas.
      container.read(provider.notifier).onSelect('area', 'Tecnología');
      await tester.pump();
      expect(tester.takeException(), isNull);

      // ...y después el set de filas ya no la contiene.
      _liveRows.removeAt(0);
      await container.read(provider.notifier).load();
      await tester.pump();

      expect(tester.takeException(), isNull);
      // La selección se muestra con una etiqueta de respaldo, no desaparece
      // en silencio ni rompe la toolbar.
      expect(find.textContaining('sin resultados'), findsWidgets);
    });
  });
}
