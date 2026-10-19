import 'package:cursar_admin_flutter/core/widgets/badge.dart';
import 'package:cursar_admin_flutter/features/crud/crud_spec.dart';
import 'package:cursar_admin_flutter/features/crud/crud_table.dart';
import 'package:cursar_admin_flutter/features/crud/crud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/layout_harness.dart';

/// Tests de la tabla del CRUD.
///
/// `CrudTable` era la única superficie del panel sin cobertura: los tests
/// anteriores montaban formularios, diálogos, toasts, login y el layout de las
/// páginas, pero nunca la tabla. Eso dejaba sin verificar justo lo que más se
/// rompe: el scroll horizontal y el sync del header con el cuerpo.
///
/// Acá se la fuerza a los cuatro anchos del harness. El `CrudSpec` es
/// sintético: `CrudTable` solo lee `columns` y `rowActions` (el `loader` lo
/// usa el `CrudController`, que acá no existe), así que se monta sin Firebase.
void main() {
  late List<String> layoutErrors;

  setUp(() => layoutErrors = installLayoutErrorCapture());
  tearDown(removeLayoutErrorCapture);

  group('scroll horizontal', () {
    testWidgets('a 360 el contenido excede el viewport', (tester) async {
      await pumpTable(tester, const Size(360, 640));

      // 5 columnas de 220 px + acciones ~= 1460 px de ancho natural en una
      // pantalla de 360: tiene que haber scroll horizontal.
      final position = _horizontalScroll(tester);

      expect(position, isNotNull, reason: 'no se encontró el scroll horizontal');
      expect(
        position!.maxScrollExtent,
        greaterThan(0),
        reason: 'el contenido entra entero, no haría falta scrollear',
      );
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('con columnas angostas no hace falta scrollear', (
      tester,
    ) async {
      await pumpTable(tester, const Size(1440, 900), narrow: true);

      // Con columnas de 90 px todo entra en 1440: el `maxScrollExtent` tiene que
      // ser 0, que es lo que decide si se dibuja la barra o no.
      expect(_horizontalScroll(tester)!.maxScrollExtent, 0);
      expect(
        _horizontalScrollbar(tester),
        isNull,
        reason: 'la tabla entra entera: no debería haber barra horizontal',
      );
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('la barra horizontal aparece cuando la tabla no entra', (
      tester,
    ) async {
      await pumpTable(tester, const Size(360, 640));

      expect(_horizontalScrollbar(tester), isNotNull);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('la barra es visible, arrastrable y compartida con el cuerpo', (
      tester,
    ) async {
      await pumpTable(tester, const Size(360, 640));

      final finder = _horizontalScrollbar(tester)!;
      final bar = tester.widget<Scrollbar>(finder);

      // Estas tres propiedades son las que hacen que la barra sirva en el
      // navegador, y no se pueden ejercitar con un drag real: en un widget test
      // ni siquiera un `Scrollbar` de vanilla responde al arrastre del pulgar
      // (el binding no le dispara los gestos al `RenderMouseRegion`).
      expect(bar.thumbVisibility, isTrue, reason: 'la barra debe verse siempre');
      expect(bar.interactive, isTrue, reason: 'sin esto no se puede arrastrar');

      // Mismo controller que el scroll del cuerpo: por eso arrastrarla mueve la
      // tabla y por eso el listener del header la sigue.
      final bodyController = tester
          .widget<SingleChildScrollView>(_horizontalScrollView().last)
          .controller;
      expect(identical(bar.controller, bodyController), isTrue);

      // Y el track ocupa el ancho de la tabla: un `SizedBox` sin width dentro
      // de una `Column` colapsa a 0 px y la barra deja de ser arrastrable.
      expect(tester.getRect(finder).width, greaterThan(100));

      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('el header sigue al cuerpo al arrastrar', (tester) async {
      await pumpTable(tester, const Size(360, 640));

      // Se mide el `dx` del header contra el de la celda: si el header no
      // siguiera al cuerpo, el título de la columna quedaría sobre otra.
      const titulo = 'NOMBRE';
      final nombre = '${_rows.first['nombre']}';

      final headerBefore = tester.getTopLeft(find.text(titulo)).dx;
      final cellBefore = tester.getTopLeft(find.text(nombre)).dx;

      await tester.drag(_horizontalBody(tester), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final headerAfter = tester.getTopLeft(find.text(titulo)).dx;
      final cellAfter = tester.getTopLeft(find.text(nombre)).dx;

      expect(
        headerBefore - headerAfter,
        greaterThan(100),
        reason: 'el header no se movió al arrastrar el cuerpo',
      );
      expect(
        headerAfter - cellAfter,
        closeTo(headerBefore - cellBefore, 0.5),
        reason: 'header y cuerpo quedaron desalineados',
      );
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });
  });

  group('layout', () {
    for (final entry in layoutViewports.entries) {
      testWidgets('no desborda a ${entry.key}', (tester) async {
        await pumpTable(tester, entry.value);

        expect(find.byType(CrudTable), findsOneWidget);
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }
  });

  group('columna de Acciones', () {
    // Ancho *útil* del panel (viewport menos sidebar de 248 y padding): 1070 px
    // en un monitor de 1366 y 984 en uno de 1280. Es el número que importa y el
    // que dejaba a "Responder" fuera de la pantalla.
    testWidgets('se ve con 1070 px útiles (1366 con sidebar)', (tester) async {
      await pumpTablaSoporte(tester, const Size(1118, 900));

      expect(
        _horizontalScrollbar(tester),
        isNull,
        reason: 'las columnas deberían achicarse en vez de scrollear',
      );
      expectAccionesVisibles(tester);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('se ve con 984 px útiles (1280 con sidebar)', (tester) async {
      await pumpTablaSoporte(tester, const Size(1032, 800));

      expect(_horizontalScrollbar(tester), isNull);
      expectAccionesVisibles(tester);
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });

    testWidgets('en un ancho imposible vuelve al scroll horizontal', (
      tester,
    ) async {
      await pumpTablaSoporte(tester, const Size(420, 860));

      // 388 px para 6 columnas + Acciones: ni los mínimos entran. Ahí la tabla
      // conserva sus anchos y scrollea, que es preferible a partir los badges.
      expect(_horizontalScroll(tester)!.maxScrollExtent, greaterThan(0));
      expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
    });
  });
}

/// Verifica que los botones de cada fila caigan dentro de la tabla.
///
/// Es la regresión del reporte real: con los anchos declarados de Soporte, la
/// columna de Acciones se iba fuera del viewport (la tabla "se veía hasta
/// Recibido") y "Responder" era inalcanzable, aunque el botón existiera.
void expectAccionesVisibles(WidgetTester tester) {
  final tabla = tester.getRect(find.byType(CrudTable));

  for (final label in const <String>['Responder', 'Resolver', 'Eliminar']) {
    final boton = tester.getRect(find.text(label).first);
    expect(
      boton.left,
      greaterThanOrEqualTo(tabla.left - 1),
      reason: '$label se fue a la izquierda de la tabla',
    );
    expect(
      boton.right,
      lessThanOrEqualTo(tabla.right + 1),
      reason: '$label quedó fuera de la tabla: la columna Acciones es inalcanzable',
    );
  }
}

/// Monta la tabla con los anchos y las acciones reales de `SoportePage.spec`.
Future<void> pumpTablaSoporte(WidgetTester tester, Size size) async {
  await pumpAt(
    tester,
    size: size,
    mobile: size.width < 900,
    child: CrudTable(
      spec: _soporteSpec(),
      rows: _soporteRows,
      onAction: (action, row) {},
    ),
  );
}

/// Monta la tabla con filas falsas.
Future<void> pumpTable(
  WidgetTester tester,
  Size size, {
  bool narrow = false,
}) async {
  await pumpAt(
    tester,
    size: size,
    mobile: size.width < 900,
    child: CrudTable(
      spec: _spec(narrow: narrow),
      rows: _rows,
      onAction: (action, row) {},
    ),
  );
}

Finder _horizontalScrollView() => find.byWidgetPredicate(
  (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
);

/// Los scrolls horizontales de la tabla: header primero, cuerpo después.
///
/// Se buscan por `scrollDirection` y no por `ScrollableState` porque el header
/// también es horizontal: distinguirlos por posición en el árbol es frágil.
List<ScrollPosition> _horizontalScrolls(WidgetTester tester) {
  // `Scrollable` y no `SingleChildScrollView`: el segundo es un
  // StatelessWidget y `tester.stateList` necesita un StatefulWidget.
  return [
    for (final state in tester.stateList<ScrollableState>(find.byType(Scrollable)))
      if (state.axisDirection == AxisDirection.right) state.position,
  ];
}

/// El del cuerpo, que es el que el usuario arrastra.
ScrollPosition? _horizontalScroll(WidgetTester tester) {
  final all = _horizontalScrolls(tester);
  return all.isEmpty ? null : all.last;
}

/// Finder del `SingleChildScrollView` del cuerpo, para arrastrarlo.
Finder _horizontalBody(WidgetTester tester) => _horizontalScrollView().last;

/// La barra horizontal, identificada por compartir controller con el scroll
/// horizontal del cuerpo.
///
/// La tabla tiene dos `Scrollbar` (una vertical, una horizontal) y no hay
/// ninguna otra forma de distinguirlas por tipo: se buscan por identidad del
/// `ScrollController`.
Finder? _horizontalScrollbar(WidgetTester tester) {
  for (final scroll in tester.widgetList<SingleChildScrollView>(
    _horizontalScrollView(),
  )) {
    final controller = scroll.controller;
    if (controller == null) continue;
    for (final bar in tester.widgetList<Scrollbar>(find.byType(Scrollbar))) {
      if (identical(bar.controller, controller)) return find.byWidget(bar);
    }
  }
  return null;
}

CrudSpec _spec({bool narrow = false}) {
  final ancho = narrow ? 90.0 : 220.0;
  return CrudSpec(
    title: 'Ofertas',
    subtitle: 'Aprobación y gestión de carreras',
    loader: (_) async => _rows,
    columns: <ColumnSpec>[
      ColumnSpec(
        key: 'nombre',
        label: 'Nombre',
        width: ancho,
        cell: (context, row) => StrongText('${row['nombre']}'),
      ),
      ColumnSpec(
        key: 'institucion',
        label: 'Institución',
        width: ancho,
        cell: (context, row) => MutedText('${row['institucion']}'),
      ),
      ColumnSpec(
        key: 'area',
        label: 'Área',
        width: narrow ? 80 : 150,
        cell: (context, row) =>
            StatusBadge('${row['area']}', tone: Tone.info),
      ),
      ColumnSpec(
        key: 'estado',
        label: 'Estado',
        width: narrow ? 70 : 110,
        cell: (context, row) =>
            StatusBadge('${row['estado']}', tone: Tone.success),
      ),
      ColumnSpec(
        key: 'createdAt',
        label: 'Creada',
        width: narrow ? 80 : 150,
        cell: (context, row) => MutedText('${row['createdAt']}'),
      ),
    ],
    rowActions: const <RowActionSpec>[
      RowActionSpec(action: 'edit', label: 'Editar', tone: Tone.secondary),
      RowActionSpec(action: 'delete', label: 'Eliminar', tone: Tone.danger),
    ],
  );
}

final List<Doc> _rows = <Doc>[
  <String, Object?>{
    'id': 'o1',
    'nombre': 'Técnico Superior en Programación',
    'institucion': 'Instituto de Tecnología',
    'area': 'Tecnología',
    'estado': 'Pendiente',
    'createdAt': '12/03/2026',
  },
  <String, Object?>{
    'id': 'o2',
    'nombre': 'Analista en Sistemas',
    'institucion': 'Centro Universitario de Salud',
    'area': 'Salud',
    'estado': 'Aprobada',
    'createdAt': '02/04/2026',
  },
  <String, Object?>{
    'id': 'o3',
    'nombre': 'Licenciatura en Educación Infantil',
    'institucion': 'Escuela Normal Superior',
    'area': 'Educación',
    'estado': 'Pendiente',
    'createdAt': '20/05/2026',
  },
];

/// Spec con los anchos y las acciones reales de la tabla de Soporte.
///
/// Es la más ancha del panel: 1180 px de columnas más ~310 de Acciones. Se
/// repite acá, en vez de importar la página, para no arrastrar Firebase.
CrudSpec _soporteSpec() => CrudSpec(
  title: 'Soporte',
  subtitle: 'Reportes y consultas enviados desde la app',
  loader: (_) async => _soporteRows,
  columns: <ColumnSpec>[
    ColumnSpec(
      key: 'email',
      label: 'Email',
      width: 220,
      cell: (context, row) => TruncatedText('${row['email']}'),
    ),
    ColumnSpec(
      key: 'tipo',
      label: 'Tipo',
      width: 130,
      cell: (context, row) =>
          StatusBadge('${row['tipo']}', tone: Tone.neutral),
    ),
    ColumnSpec(
      key: 'mensaje',
      label: 'Mensaje',
      width: 340,
      cell: (context, row) => TruncatedText('${row['mensaje']}'),
    ),
    ColumnSpec(
      key: 'respuesta',
      label: 'Respuesta',
      width: 220,
      cell: (context, row) => const MutedText('Sin respuesta'),
    ),
    ColumnSpec(
      key: 'createdAt',
      label: 'Recibido',
      width: 150,
      cell: (context, row) => MutedText('${row['createdAt']}'),
    ),
    ColumnSpec(
      key: 'estado',
      label: 'Estado',
      width: 120,
      cell: (context, row) => const StatusBadge('Nuevo', tone: Tone.warning),
    ),
  ],
  rowActions: const <RowActionSpec>[
    RowActionSpec(
      action: 'responder',
      label: 'Responder',
      tone: Tone.primary,
      icon: Icons.reply_outlined,
    ),
    RowActionSpec(
      action: 'resolver',
      label: 'Resolver',
      tone: Tone.success,
      icon: Icons.check,
    ),
    RowActionSpec(
      action: 'delete',
      label: 'Eliminar',
      tone: Tone.danger,
      icon: Icons.delete_outline,
    ),
  ],
);

final List<Doc> _soporteRows = <Doc>[
  <String, Object?>{
    'id': 's1',
    'email': 'alumno@ejemplo.com',
    'tipo': 'Error',
    'mensaje': 'No puedo inscribirme a la materia: me da error al confirmar.',
    'respuesta': '',
    'createdAt': '18/10/2026 09:12',
    'estado': 'nuevo',
  },
  <String, Object?>{
    'id': 's2',
    'email': 'otro.alumno@ejemplo.com',
    'tipo': 'Consulta',
    'mensaje': '¿Cuándo abre la inscripción del segundo cuatrimestre?',
    'respuesta': 'Abre el 1 de agosto.',
    'createdAt': '17/10/2026 18:40',
    'estado': 'resuelto',
  },
];