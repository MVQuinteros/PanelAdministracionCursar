import 'package:cursar_admin_flutter/core/theme/app_theme.dart';
import 'package:cursar_admin_flutter/core/widgets/badge.dart';
import 'package:cursar_admin_flutter/core/widgets/banner.dart';
import 'package:cursar_admin_flutter/core/widgets/empty_state.dart';
import 'package:cursar_admin_flutter/features/crud/crud_page.dart';
import 'package:cursar_admin_flutter/features/crud/crud_spec.dart';
import 'package:cursar_admin_flutter/features/crud/crud_widgets.dart';
import 'package:cursar_admin_flutter/features/dashboard/dashboard_controller.dart';
import 'package:cursar_admin_flutter/features/dashboard/dashboard_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de layout: renderizan las páginas reales a distintas resoluciones y
/// fallan si algo desborda.
///
/// Motivo y datos: ver `support/layout_harness.dart`. Acá está el harness
/// compartido con `responsive_test.dart`.

import 'support/layout_harness.dart';

void main() {
  late List<String> layoutErrors;

  setUp(() => layoutErrors = installLayoutErrorCapture());
  tearDown(removeLayoutErrorCapture);

  group('dashboard', () {
    for (final entry in layoutViewports.entries) {
      testWidgets('no desborda a ${entry.key}', (tester) async {
        await pumpAt(
          tester,
          child: ProviderScope(
            overrides: [
              dashboardProvider.overrideWith((ref) async => _dashboardData),
            ],
            child: const DashboardPage(),
          ),
          size: entry.value,
          mobile: entry.value.width < AppTokens.breakpointMobile,
        );

        expect(find.byType(DashboardPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }

    testWidgets('saca las dos donas y las dos barras', (tester) async {
      await pumpAt(
        tester,
        child: ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) async => _dashboardData),
          ],
          child: const DashboardPage(),
        ),
        size: const Size(1440, 900),
      );

      expect(find.byType(PieChart), findsNWidgets(2));
      expect(find.byType(BarChart), findsNWidgets(2));
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });
  });

  group('crud', () {
    // `CrudPage` es un ConsumerStatefulWidget: necesita su propio scope. El
    // `loader` del spec es una función pura, así que no hay que overridear nada
    // para evitar Firestore.
    Widget crud({List<Map<String, Object?>>? rows, bool banner = false}) {
      return ProviderScope(
        child: CrudPage(spec: _crudSpec(rows: rows, banner: banner)),
      );
    }

    for (final entry in layoutViewports.entries) {
      testWidgets('no desborda a ${entry.key}', (tester) async {
        await pumpAt(
          tester,
          child: crud(),
          size: entry.value,
          mobile: entry.value.width < AppTokens.breakpointMobile,
        );

        // "0 - Técnico Superior" también está dentro de "10 - ..." y "20 - ...".
        expect(find.textContaining('Técnico Superior'), findsAtLeastNWidgets(1));
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }

    testWidgets('el estado vacío no desborda', (tester) async {
      await pumpAt(
        tester,
        child: crud(rows: const <Map<String, Object?>>[]),
        size: const Size(1280, 800),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('el banner largo no desborda', (tester) async {
      await pumpAt(
        tester,
        child: crud(banner: true),
        size: const Size(420, 860),
        mobile: true,
      );

      expect(find.byType(InfoBanner), findsOneWidget);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });
  });
}

// ---------------------------------------------------------------------------
// Datos de prueba
// ---------------------------------------------------------------------------

const _areas = <String>[
  'Tecnología',
  'Ingeniería',
  'Salud',
  'Educación',
  'Creativa',
  'Administración',
  'Economía',
  'Derecho',
];

const _localidades = <String>[
  'Rosario',
  'Córdoba',
  'Mendoza',
  'La Plata',
  'Tucumán',
  'Neuquén',
  'Salta',
  'Paraná',
  'Mar del Plata',
  'Bahía Blanca',
  'Santa Fe',
  'Posadas',
];

/// 30 ofertas: hoy hay muchas menos, pero este es el peor caso razonable
/// (8 áreas, 4 acciones por fila, nombres largos).
List<Map<String, Object?>> _ofertas() => List<Map<String, Object?>>.generate(30, (i) {
  return <String, Object?>{
    'id': '$i',
    'nombre':
        '$i - Técnico Superior en Programación y Desarrollo de Software con '
        'especialización en cloud computing y arquitectura de sistemas',
    'area': _areas[i % _areas.length],
    'institucion': 'Instituto de Tecnología ${i % 7}',
    'aprobada': i.isEven,
    'createdAt': DateTime(2024, 1 + (i % 12), 1 + (i % 28)),
  };
});

List<Map<String, Object?>> _usuarios() => List<Map<String, Object?>>.generate(40, (i) {
  return <String, Object?>{
    'id': '$i',
    'nombre': 'Usuario de prueba con nombre larguísimo $i',
    'apellido': 'Apellido Compuesto',
    'email': 'usuario.de.prueba.larguisimo.$i@example.com',
    'localidad': _localidades[i % _localidades.length],
    'rol': i.isEven ? 'admin' : 'user',
  };
});

DashboardData get _dashboardData => DashboardData(
  ofertas: _ofertas(),
  usuarios: _usuarios(),
  instituciones: <Map<String, Object?>>[
    <String, Object?>{
      'id': 'i1',
      'nombre': 'Instituto Superior de Tecnología',
      'estado': 'aprobada',
    },
    <String, Object?>{
      'id': 'i2',
      'nombre': 'Centro Universitario de Salud',
      'estado': 'pendiente',
    },
  ],
  tags: <Map<String, Object?>>[
    <String, Object?>{'id': 't1', 'nombre': 'becas'},
  ],
  avisos: <Map<String, Object?>>[
    <String, Object?>{'id': 'a1', 'titulo': 'Convocatoria abierta'},
  ],
  soporte: <Map<String, Object?>>[
    <String, Object?>{'id': 's1', 'estado': 'pendiente'},
  ],
  resultados: List<Map<String, Object?>>.generate(12, (i) {
    return <String, Object?>{
      'id': 'r$i',
      'areaInteres': _areas[i % _areas.length],
      'userUid': 'uid$i',
    };
  }),
);

/// Spec CRUD realista: 5 columnas, 3 filtros, 4 acciones por fila.
CrudSpec _crudSpec({List<Map<String, Object?>>? rows, bool banner = false}) {
  final data = rows ?? _ofertas();

  return CrudSpec(
    title: 'Ofertas',
    subtitle: 'Aprobación y gestión de carreras',
    bannerText: banner
        ? 'Este es un banner deliberadamente largo para comprobar que el '
              'texto se envuelve bien en pantallas angostas y no desborda la '
              'caja de contenido hacia la derecha.'
        : null,
    loader: (ref) async => data,
    columns: <ColumnSpec>[
      ColumnSpec(
        key: 'nombre',
        label: 'Carrera',
        width: 320,
        cell: (context, row) => StrongText('${row['nombre']}'),
      ),
      ColumnSpec(
        key: 'area',
        label: 'Área',
        width: 140,
        cell: (context, row) => MutedText('${row['area']}'),
      ),
      ColumnSpec(
        key: 'institucion',
        label: 'Institución',
        width: 220,
        cell: (context, row) => MutedText('${row['institucion']}'),
      ),
      ColumnSpec(
        key: 'aprobada',
        label: 'Estado',
        width: 130,
        cell: (context, row) => StatusBadge(
          row['aprobada'] == true ? 'Aprobada' : 'Pendiente',
          tone: row['aprobada'] == true ? Tone.success : Tone.warning,
        ),
      ),
      ColumnSpec(
        key: 'createdAt',
        label: 'Alta',
        width: 130,
        cell: (context, row) => MutedText('${row['createdAt']}'),
      ),
    ],
    filters: <FilterSpec>[
      const FilterSpec(key: 'area', label: 'Área'),
      FilterSpec(
        key: 'aprobada',
        label: 'Estado',
        options: const <FieldOption>[
          FieldOption(value: 'true', label: 'Aprobadas'),
          FieldOption(value: 'false', label: 'Pendientes'),
        ],
        match: (row, value) => value == 'true'
            ? row['aprobada'] == true
            : row['aprobada'] != true,
      ),
      const FilterSpec(key: 'createdAt', label: 'Alta', type: FilterType.dateRange),
    ],
    rowActions: const <RowActionSpec>[
      RowActionSpec(
        action: 'approve',
        label: 'Aprobar',
        tone: Tone.success,
        icon: Icons.check,
        patch: <String, Object?>{'aprobada': true},
        doneMessage: 'Oferta aprobada',
      ),
      RowActionSpec(
        action: 'reject',
        label: 'Rechazar',
        tone: Tone.danger,
        icon: Icons.close,
        patch: <String, Object?>{'aprobada': false},
        doneMessage: 'Oferta rechazada',
      ),
      RowActionSpec(action: 'edit', label: 'Editar', icon: Icons.edit),
      RowActionSpec(
        action: 'delete',
        label: 'Borrar',
        tone: Tone.danger,
        icon: Icons.delete_outline,
      ),
    ],
  );
}
