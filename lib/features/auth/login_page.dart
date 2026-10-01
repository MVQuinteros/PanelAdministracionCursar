import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cursar_palette.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/toast.dart';
import '../../main.dart';
import 'auth_controller.dart';

/// Pantallas de auth: carga, login, registro y acceso denegado.
///
/// Espejo de `js/views/authView.js` + `js/controllers/authController.js`.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nombre.dispose();
    _apellido.dispose();
    super.dispose();
  }

  void _setError(String? message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = ref.read(authControllerProvider.notifier);
    final err = _registerMode
        ? await auth.register(
            nombre: _nombre.text,
            apellido: _apellido.text,
            email: _email.text,
            password: _password.text,
          )
        : await auth.signIn(_email.text, _password.text);

    if (!mounted) return;
    setState(() => _busy = false);

    if (err != null) {
      _setError(err);
    } else if (_registerMode) {
      toast(context, 'Cuenta admin creada. Bienvenido.', kind: ToastKind.success);
    } else {
      toast(context, 'Sesión iniciada correctamente.', kind: ToastKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).status;
    if (status == AuthStatus.loading) return const _LoadingScreen();
    if (status == AuthStatus.denied) return const DeniedPage();
    return _buildCard();
  }

  Widget _buildCard() {
    final p = context.palette;

    return Scaffold(
      body: _AuthBackground(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const BrandMark(size: 42),
                            const SizedBox(width: 12),
                            // `Expanded`: sin él la `Column` toma el ancho intrínseco de "Panel de
                            // administración" (~274px) y la fila desborda a la
                            // derecha en pantallas de 360px o menos. Con
                            // `Expanded` el subtítulo pasa a dos líneas.
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURSAR',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Panel de administración',
                                    style: TextStyle(
                                      fontSize: AppTokens.sm,
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _registerMode ? 'Registrar cuenta' : 'Iniciar sesión',
                          style: TextStyle(
                            fontSize: AppTokens.authTitle,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _registerMode
                              ? 'Se creará con rol admin.'
                              : 'Accedé con una cuenta con rol admin.',
                          style: TextStyle(
                            fontSize: AppTokens.md,
                            color: p.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          _AuthError(message: _error!),
                          const SizedBox(height: 14),
                        ],
                        if (_registerMode) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nombre,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: _required,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _apellido,
                                  decoration: const InputDecoration(
                                    labelText: 'Apellido',
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: _required,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Ingresá tu email.';
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'El email no tiene un formato válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                          obscureText: true,
                          onFieldSubmitted: (_) => _busy ? null : _submit(),
                          validator: (v) {
                            if ((v ?? '').isEmpty) return 'Ingresá tu contraseña.';
                            if (_registerMode && v!.length < 6) {
                              return 'Mínimo 6 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: _registerMode ? 'Crear cuenta admin' : 'Entrar',
                          tone: Tone.primary,
                          block: true,
                          onPressed: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 14),
                        if (!_registerMode) ...[
                          Text(
                            '¿Sos admin? Creá el usuario en Firebase Console → '
                            'Authentication, y en Firestore → usuarios/{uid} '
                            'poné rol: "admin".',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.6,
                              color: p.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (AppConfig.permitirRegistro)
                          _SwapLink(
                            text: '¿No tenés cuenta?',
                            action: 'Registrarme',
                            onTap: () =>
                                setState(() => _registerMode = true),
                          ),
                        // Va aparte del `permitirRegistro`: si no, al activar
                        // el registro no había forma de volver al login.
                        if (_registerMode)
                          _SwapLink(
                            text: '¿Ya tenés cuenta?',
                            action: 'Iniciar sesión',
                            onTap: () =>
                                setState(() => _registerMode = false),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio.' : null;
}

class _SwapLink extends StatelessWidget {
  const _SwapLink({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$text ',
          style: TextStyle(fontSize: 12.5, color: context.palette.textSecondary),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 12.5, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.dangerSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.danger.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12.5,
          color: isLight ? const Color(0xFFB42318) : const Color(0xFFFFA29F),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: p.accent),
            ),
            const SizedBox(height: 14),
            Text(
              'Verificando sesión…',
              style: TextStyle(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo con los dos radial-gradient del `.auth-screen` del CSS.
class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.bgMain,
        gradient: RadialGradient(
          center: const Alignment(-1, -1),
          radius: 1.1,
          colors: [p.accent.withValues(alpha: 0.13), Colors.transparent],
          stops: const [0, 0.6],
        ),
      ),
      child: child,
    );
  }
}

/// Pantalla de acceso denegado (`deniedScreen`).
class DeniedPage extends ConsumerWidget {
  const DeniedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final email = ref.watch(authControllerProvider).user?.email ?? '';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Acceso denegado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTokens.authTitle,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: AppTokens.md,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'La cuenta '),
                        TextSpan(
                          text: email,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text: ' no tiene rol de administrador. El acceso a '
                              'este panel está limitado a cuentas con '
                              'rol: "admin".',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Cambiar de cuenta',
                    tone: Tone.outline,
                    block: true,
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marca "C" de la marca, usada en el login y el sidebar.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: Text(
        'C',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.53,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Saludo según la franja horaria (`timeGreeting` del original).
String timeGreeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Buenos días';
  if (h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}
