import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tone.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../router.dart' show kNavItems;
import '../auth/auth_controller.dart';

/// Esqueleto de la app: sidebar + topbar + contenido.
///
/// Espejo de `js/views/layout.js`: misma marca, mismo grupo "Gestión", misma
/// user-chip en el pie y el mismo saludo por horario. En móvil el sidebar pasa
/// a ser un drawer (`.sidebar` + `.sidebar-backdrop` del CSS).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _wide = AppTokens.breakpointMobile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = ref.watch(authControllerProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final isWide = MediaQuery.sizeOf(context).width >= _wide;

    final sidebar = _Sidebar(
      location: location,
      adminName: auth.adminName,
      initials: Fmt.initials(
        auth.adminDoc?['nombre'] as String?,
        auth.adminDoc?['apellido'] as String?,
      ),
      onClose: isWide ? null : () => _scaffoldKey.currentState?.closeDrawer(),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: p.bgMain,
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: p.bgSurface,
              child: SafeArea(child: sidebar),
            ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: AppTokens.sidebarWidth,
              child: ColoredBox(
                color: p.bgSurface,
                child: SafeArea(right: false, child: sidebar),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _Topbar(
                  title: _titleFor(location),
                  greeting: '${_timeGreeting()}, ${auth.adminName} 👋',
                  onMenu: isWide ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                // La caja de contenido va ACOTADA a propósito: las páginas
                // tienen sus propias regiones scrolleables (la tabla, los
                // gráficos) y necesitan una altura definida para poder usar
                // `Expanded`. Por eso acá no hay `SingleChildScrollView`
                // —cada página scrollea ella misma.
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(
                      isWide
                          ? AppTokens.contentPadding
                          : AppTokens.contentPaddingMobile,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _titleFor(String location) {
    for (final item in kNavItems) {
      if (item.route == location) return item.label;
    }
    return 'CURSAR';
  }

  /// Saludación por franja horaria, igual que `timeGreeting()`.
  static String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.location,
    required this.adminName,
    required this.initials,
    required this.onClose,
  });

  final String location;
  final String adminName;
  final String initials;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CURSAR',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: AppTokens.xl,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Panel de administración',
                      style: TextStyle(color: p.textMuted, fontSize: AppTokens.xs),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                  color: p.textSecondary,
                  tooltip: 'Cerrar menú',
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: Text(
                    'GESTIÓN',
                    style: TextStyle(
                      color: p.textMuted,
                      fontSize: AppTokens.xs,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final item in kNavItems)
                  _NavItem(
                    label: item.label,
                    icon: item.icon,
                    active: location == item.route,
                    onTap: () {
                      onClose?.call();
                      GoRouter.of(context).go(item.route);
                    },
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: p.accentSoft,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: p.accent,
                        fontSize: AppTokens.sm,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          adminName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: AppTokens.md,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Administrador',
                          style: TextStyle(
                            color: p.textMuted,
                            fontSize: AppTokens.xs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, _) => AppButton(
                  label: 'Cerrar sesión',
                  icon: Icons.logout,
                  tone: Tone.danger,
                  small: true,
                  block: true,
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = active ? p.accent : p.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? p.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: AppTokens.md2,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Topbar extends ConsumerWidget {
  const _Topbar({
    required this.title,
    required this.greeting,
    required this.onMenu,
  });

  final String title;
  final String greeting;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: AppTokens.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border(bottom: BorderSide(color: p.borderSubtle)),
      ),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu, size: 20),
              color: p.textSecondary,
              tooltip: 'Abrir menú',
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: AppTokens.xxl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textMuted, fontSize: AppTokens.xs),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Cambiar tema claro/oscuro',
            child: IconButton(
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              icon: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 19,
              ),
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
