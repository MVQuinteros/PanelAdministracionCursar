import 'package:cursar_admin_flutter/core/theme/app_theme.dart';
import 'package:cursar_admin_flutter/core/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El toast pasó de `SnackBar` a `Overlay` porque `SnackBar` exige `width` y
/// `margin` mutuamente excluyentes (`assert(width == null || margin == null)`),
/// y eso reventaba en cada login. Estos tests fijan el comportamiento nuevo:
/// anclado abajo a la derecha, uno a la vez, y que se limpie solo.
void main() {
  late BuildContext ctx;

  Future<void> mount(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 600);
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
  }

  testWidgets('aparece abajo a la derecha', (tester) async {
    await mount(tester);

    toast(ctx, 'Oferta aprobada', kind: ToastKind.success);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Oferta aprobada'), findsOneWidget);

    // Derecha: el texto tiene que estar en la mitad derecha del viewport
    // (el `right: 20` del `Positioned`), no centrado como un `SnackBar`.
    final center = tester.getCenter(find.text('Oferta aprobada'));
    expect(center.dx, greaterThan(400));
    expect(center.dy, greaterThan(300));
  });

  testWidgets('se va solo a los 4.2 s', (tester) async {
    await mount(tester);

    toast(ctx, 'Listo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Listo'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pumpAndSettle();

    expect(find.text('Listo'), findsNothing);
  });

  testWidgets('un toast nuevo reemplaza al anterior', (tester) async {
    await mount(tester);

    toast(ctx, 'Primero');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    toast(ctx, 'Segundo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Primero'), findsNothing);
    expect(find.text('Segundo'), findsOneWidget);
  });

  testWidgets('sin Overlay no rompe (contexto de test)', (tester) async {
    // Contexto sin `Overlay` debajo: el toast debe ser un no-op silencioso.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            expect(() => toast(context, 'x'), returnsNormally);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
