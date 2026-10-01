/// Harness compartido por los tests de layout.
///
/// `flutter analyze` no ve nada del layout real: los "RenderFlex overflowed by
/// N pixels" y los "non-zero flex but incoming height constraints are unbounded"
/// son errores de RUNTIME, y en el navegador aparecen recién cuando la
/// pantalla tiene la resolución equivocada. Estos helpers los vuelven
/// deterministas.
library;

import 'package:cursar_admin_flutter/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resoluciones a cubrir: notebook normal, notebook angosto, móvil y el móvil
/// chico que es el que más duele.
const layoutViewports = <String, Size>{
  '1440x900': Size(1440, 900),
  '1280x800': Size(1280, 800),
  '420x860': Size(420, 860),
  '360x640': Size(360, 640),
};

/// Anchos que solo tienen sentido para superficies flotantes (toast, diálogos),
/// que están anclados a un borde y por eso se salen antes que el contenido.
const floatingViewports = <String, Size>{
  '420x860': Size(420, 860),
  '360x640': Size(360, 640),
  '320x640': Size(320, 640),
};

/// Intercepta `FlutterError.onError`, que es el canal por el que Flutter
/// reporta los desbordes, y acumula todo para poder listarlo junto en vez de
/// cortar en el primero.
///
/// Devuelve la lista: llamarla una vez por test desde `setUp`.
List<String> installLayoutErrorCapture() {
  final previous = FlutterError.onError;
  final errors = <String>[];
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    previous?.call(details);
  };
  return errors;
}

/// Restaura el handler original. Llamar desde `tearDown`.
void removeLayoutErrorCapture() => FlutterError.onError = null;

/// Monta [child] dentro de la misma caja de contenido que arma `AppShell`, a la
/// resolución pedida.
///
/// [child] se pasa ya envuelto en su `ProviderScope` cuando hace falta.
Future<void> pumpAt(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  bool mobile = false,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() => tester.view.reset());

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(
            mobile
                ? AppTokens.contentPaddingMobile
                : AppTokens.contentPadding,
          ),
          child: child,
        ),
      ),
    ),
  );

  await settle(tester);
}

/// Deja correr lo que haya que correr tras un `pumpWidget`: un `pump` para el
/// loader, otro para que llegue la data, y `pumpAndSettle` para el resto
/// (charts, animaciones de entrada, barras de scroll).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

/// Mensaje de fallo: lista todos los errores de layout juntos.
String layoutReason(List<String> errors) {
  if (errors.isEmpty) return 'sin errores';
  return 'errores de layout:\n${errors.join('\n---\n')}';
}