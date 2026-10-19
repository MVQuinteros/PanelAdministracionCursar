import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';
import 'router.dart';

/// Config del panel, equivalente a `config` de `js/config/firebase-config.js`.
abstract final class AppConfig {
  /// Permite crear cuentas admin desde esta web.
  ///
  /// ---------------------------------------------------------------------
  /// ATENCIÓN: dejarlo en `true` hace que cualquier persona que abra el
  /// panel pueda crearse su propia cuenta con rol `admin` (aparece el botón
  /// "Registrarme" en el login).
  ///
  /// Está en `false` a propósito, como corresponde a un panel publicado.
  /// Este flag es SOLO del frontend: no afecta a la app móvil CURSAR ni a
  /// ningún otro proyecto, y no requiere tocar `firestore.rules`.
  /// ---------------------------------------------------------------------
  static const bool permitirRegistro = false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Estos valores NO son secretos: la seguridad depende de las Security Rules
  // de Firestore, no de ocultar la configuración. Es el mismo proyecto que
  // usa la app móvil CURSAR.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final initialTheme = await loadInitialTheme();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => ThemeModeController(initialTheme)),
      ],
      child: const CursarAdminApp(),
    ),
  );
}

class CursarAdminApp extends ConsumerWidget {
  const CursarAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'CURSAR · Panel de administración',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _PanelScrollBehavior(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        // Limitar el escalado de texto del sistema para que el panel no se
        // rompa con fuentes muy grandes (el CSS usaba px fijos).
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Arrastre de los scrollables con el mouse, para las tablas anchas.
///
/// Flutter deja `PointerDeviceKind.mouse` afuera de `dragDevices` por defecto:
/// en escritorio los scrollables se mueven con la rueda y con la barra. En el
/// panel eso no alcanza, porque varias tablas son más anchas que la pantalla
/// (Soporte pide ~1480 px y en un monitor de 1440 entran ~1144) y la columna de
/// Acciones —donde viven "Responder", "Editar", etc.— queda fuera de la vista.
/// Sin arrastre, la única forma de llegar era la barra horizontal del pie, que
/// es finita y pasa desapercibida.
class _PanelScrollBehavior extends MaterialScrollBehavior {
  const _PanelScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}
