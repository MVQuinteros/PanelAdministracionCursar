import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_page.dart';
import 'features/crud/avisos_page.dart';
import 'features/crud/instituciones_page.dart';
import 'features/crud/ofertas_page.dart';
import 'features/crud/soporte_page.dart';
import 'features/crud/tags_page.dart';
import 'features/crud/test_vocacional_page.dart';
import 'features/crud/usuarios_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/shell/app_shell.dart';

/// Definición de una entrada del menú lateral (`NAV` de `js/views/layout.js`).
class NavItem {
  const NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.title,
  });

  final String route;
  final String label;
  final IconData icon;

  /// Subtítulo que se muestra sobre la tabla (`.view-head`).
  final String title;
}

const List<NavItem> kNavItems = <NavItem>[
  NavItem(
    route: '/dashboard',
    label: 'Dashboard',
    icon: Icons.grid_view_rounded,
    title: 'Resumen general del sistema',
  ),
  NavItem(
    route: '/usuarios',
    label: 'Usuarios',
    icon: Icons.people_alt_outlined,
    title: 'Cuentas de la app y roles de acceso',
  ),
  NavItem(
    route: '/ofertas',
    label: 'Ofertas',
    icon: Icons.work_outline,
    title: 'Aprobación y gestión de carreras',
  ),
  NavItem(
    route: '/instituciones',
    label: 'Instituciones',
    icon: Icons.apartment_rounded,
    title: 'Centros educativos registrados',
  ),
  NavItem(
    route: '/tags',
    label: 'Tags',
    icon: Icons.sell_outlined,
    title: 'Etiquetas de categorización',
  ),
  NavItem(
    route: '/avisos',
    label: 'Avisos',
    icon: Icons.notifications_none_rounded,
    title: 'Noticias publicadas en la app',
  ),
  NavItem(
    route: '/soporte',
    label: 'Soporte',
    icon: Icons.help_outline_rounded,
    title: 'Reportes enviados desde la app',
  ),
  NavItem(
    route: '/test',
    label: 'Test vocacional',
    icon: Icons.assignment_outlined,
    title: 'Resultados del test orientativo vocacional',
  ),
];

/// Rutas del panel.
///
/// Usa URLs por hash (igual que el router del panel original), así que el
/// hosting estático (GitHub Pages) no necesita ningún rewrite.
///
/// El guard hace lo mismo que `initAuth()` + `showLogin()/showApp()`:
/// mientras verifica la sesión va a `/login`; si no hay sesión o no es admin
/// se queda en las pantallas de auth; si es admin, al dashboard.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen<AuthState>(
    authControllerProvider,
    (previous, next) {
      notifier.value++;
    },
  );

  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/usuarios',
            builder: (context, state) => const UsuariosPage(),
          ),
          GoRoute(
            path: '/ofertas',
            builder: (context, state) => const OfertasPage(),
          ),
          GoRoute(
            path: '/instituciones',
            builder: (context, state) => const InstitucionesPage(),
          ),
          GoRoute(
            path: '/tags',
            builder: (context, state) => const TagsPage(),
          ),
          GoRoute(
            path: '/avisos',
            builder: (context, state) => const AvisosPage(),
          ),
          GoRoute(
            path: '/soporte',
            builder: (context, state) => const SoportePage(),
          ),
          GoRoute(
            path: '/test',
            builder: (context, state) => const TestVocacionalPage(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      final onAuthScreen = loc == '/login' || loc.isEmpty;

      switch (status) {
        case AuthStatus.loading:
        case AuthStatus.unauthenticated:
        case AuthStatus.denied:
          return onAuthScreen ? null : '/login';
        case AuthStatus.admin:
          return onAuthScreen ? '/dashboard' : null;
      }
    },
  );
});
