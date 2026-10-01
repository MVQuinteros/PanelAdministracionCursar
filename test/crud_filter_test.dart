import 'package:cursar_admin_flutter/features/crud/crud_spec.dart';
import 'package:cursar_admin_flutter/features/crud/ofertas_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Datos de prueba: tres ofertas con estados y fechas distintas.
final _rows = <Map<String, Object?>>[
  <String, Object?>{
    'id': '1',
    'nombre': 'Técnico en Programación',
    'area': 'Tecnología',
    'aprobada': true,
    'createdAt': DateTime(2024, 3, 1),
  },
  <String, Object?>{
    'id': '2',
    'nombre': 'Licenciatura en Administración',
    'area': 'Administración',
    'aprobada': false,
    'createdAt': DateTime(2024, 6, 15),
  },
  <String, Object?>{
    'id': '3',
    'nombre': 'Técnico en Electrónica',
    'area': 'Tecnología',
    'aprobada': false,
    'createdAt': DateTime(2023, 11, 2),
  },
];

CrudSpec _spec() => CrudSpec(
  title: 'Ofertas',
  subtitle: 'test',
  loader: (ref) async => _rows,
  filters: <FilterSpec>[
    const FilterSpec(key: 'area', label: 'Área'),
    FilterSpec(
      key: 'aprobada',
      label: 'Estado',
      options: <FieldOption>[
        FieldOption(value: 'true', label: 'Aprobadas'),
        FieldOption(value: 'false', label: 'Pendientes'),
      ],
      match: (row, value) =>
          value == 'true' ? row['aprobada'] == true : row['aprobada'] != true,
    ),
    const FilterSpec(
      key: 'createdAt',
      label: 'Alta',
      type: FilterType.dateRange,
    ),
  ],
  columns: <ColumnSpec>[],
);

void main() {
  late ProviderContainer container;
  late NotifierProvider<CrudController, CrudState> provider;

  setUp(() {
    container = ProviderContainer();
    provider = crudProviderFor(_spec());
    // `listen` mantiene el provider vivo y dispara el `build()` inicial.
    container.listen(provider, (_, _) {});
  });

  tearDown(() => container.dispose());

  CrudController controller() => container.read(provider.notifier);
  CrudState state() => container.read(provider);

  /// Espera a que termine la carga disparada desde `build()`.
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('carga las filas y las deja visibles', () async {
    await settle();

    expect(state().loading, isFalse);
    expect(state().error, isNull);
    expect(state().allRows, hasLength(3));
    expect(state().filtered, hasLength(3));
  });

  test('la búsqueda filtra por texto libre', () async {
    await settle();

    controller().onSearch('electrónica');
    expect(state().filtered.map((r) => r['id']), <String>['3']);
  });

  test('combina búsqueda con filtro select', () async {
    await settle();

    controller().onSearch('técnico');
    controller().onSelect('area', 'Tecnología');
    expect(
      state().filtered.map((r) => r['id']),
      containsAll(<String>['1', '3']),
    );

    controller().onSelect('area', '');
    controller().onSelect('aprobada', 'true');
    expect(state().filtered.map((r) => r['id']), <String>['1']);
  });

  test('el rango de fechas incluye todo el día del extremo', () async {
    await settle();

    controller().onDateBound(
      'createdAt',
      start: DateTime(2024, 3, 1),
      end: DateTime(2024, 3, 1),
    );
    // `createdAt` del documento 1 es 2024-03-01 00:00:00: debe entrar.
    expect(state().filtered.map((r) => r['id']), <String>['1']);
  });

  test('resetFilters limpia búsqueda y filtros', () async {
    await settle();

    controller().onSearch('técnico');
    controller().onSelect('area', 'Tecnología');
    expect(state().hasActiveFilters, isTrue);

    controller().resetFilters();
    expect(state().hasActiveFilters, isFalse);
    expect(state().filtered, hasLength(3));
  });

  test('las opciones de filtro se derivan de los datos', () async {
    await settle();

    final options = controller().resolveFilterOptions(_spec().filters.first);
    expect(
      options.map((o) => o.value),
      <String>['Administración', 'Tecnología'],
    );
  });

  // Regresión del join de Ofertas.
  //
  // Hay instituciones sin `nombre`: las dejaron los triggers de Cloud
  // Functions (`eliminar_isft180_v1`, `logos_storage_v1`, que solo tienen
  // `createdAt` y `trigger`). Con el `!` del port Dart el `_specFor` reventaba
  // dentro del `build` y se caía la página entera de Ofertas, mientras el
  // panel original solo mostraba `—` en esa fila.
  group('join de instituciones de Ofertas', () {
    test('no lanza con una institución sin nombre', () {
      final labels = institutionNamesById(<Map<String, Object?>>[
        <String, Object?>{'id': 'inst_ok', 'nombre': 'ISFT 180'},
        <String, Object?>{'id': 'eliminar_isft180_v1', 'trigger': true},
      ]);

      expect(labels, <String, String>{
        'inst_ok': 'ISFT 180',
        'eliminar_isft180_v1': '(sin nombre)',
      });
    });

    test('descarta los documentos sin id', () {
      final labels = institutionNamesById(<Map<String, Object?>>[
        <String, Object?>{'nombre': 'ISFT 180'},
        <String, Object?>{'id': 'logos_storage_v1', 'trigger': true},
      ]);

      expect(labels.containsKey('logos_storage_v1'), isTrue);
      expect(labels, hasLength(1));
    });

    test('cae en nombreCompleto cuando no hay nombre', () {
      expect(
        institutionLabel(<String, Object?>{
          'nombreCompleto': 'Universidad Nacional',
        }),
        'Universidad Nacional',
      );
    });

    test('ignora nombres vacíos o de tipo incorrecto', () {
      expect(institutionLabel(<String, Object?>{'nombre': '   '}),
          '(sin nombre)');
      expect(institutionLabel(<String, Object?>{'nombre': 42}), '(sin nombre)');
      expect(institutionLabel(<String, Object?>{}), '(sin nombre)');
    });
  });

  group('nombres de tags de Ofertas', () {
    test('descarta los tags sin nombre utilizable', () {
      expect(
        tagNamesOf(<Map<String, Object?>>[
          <String, Object?>{'nombre': 'Programación'},
          <String, Object?>{'descripcion': 'sin nombre'},
        ]),
        <String>['Programación'],
      );
    });
  });
}
