import 'package:cursar_admin_flutter/data/models/model_providers.dart';
import 'package:cursar_admin_flutter/data/models/usuario_model.dart';
import 'package:cursar_admin_flutter/features/admin/admin_policy.dart';
import 'package:cursar_admin_flutter/features/admin/administradores_page.dart';
import 'package:cursar_admin_flutter/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/layout_harness.dart';

/// Tests del módulo Administradores.
///
/// La lógica de decisión (`AdminPolicy`) se testea sola, sin Firestore ni
/// widget tree: ahí viven los dos bloqueos que evitan que el panel quede sin
/// nadie que pueda entrar. Después, la pantalla se renderiza con un modelo
/// falso para verificar que lista a quien corresponde y que no desborda.

/// Modelo de usuarios en memoria, con la misma forma que `UsuarioModel`.
class _UsuariosFalsos extends UsuarioModel {
  _UsuariosFalsos(this.filas);

  final List<Map<String, Object?>> filas;

  /// Escrituras registradas, por si un test quiere inspeccionarlas.
  final List<Map<String, Object?>> escrituras = <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> list() async => filas;

  @override
  Future<void> update(String uid, Map<String, Object?> data) async {
    escrituras.add(<String, Object?>{'id': uid, ...data});
    for (final fila in filas) {
      if (fila['id'] == uid) fila.addAll(data);
    }
  }
}

/// Sesión de prueba: solo interesa el documento del admin (uid y email).
class _AuthFalso extends AuthController {
  _AuthFalso(this.inicial);

  final AuthState inicial;

  @override
  AuthState build() => inicial;
}

Widget _pagina({
  required List<Map<String, Object?>> usuarios,
  String uid = 'yo',
}) {
  return ProviderScope(
    overrides: [
      usuarioModelProvider.overrideWith((ref) => _UsuariosFalsos(usuarios)),
      authControllerProvider.overrideWith(
        () => _AuthFalso(
          AuthState(
            status: AuthStatus.admin,
            adminDoc: <String, Object?>{
              'id': uid,
              'nombre': 'Admin',
              'apellido': 'De Prueba',
              'email': 'admin@cursar.app',
            },
          ),
        ),
      ),
    ],
    child: const AdministradoresPage(),
  );
}

Map<String, Object?> _usuario({
  required String id,
  String nombre = '',
  String apellido = '',
  String email = '',
  String rol = 'usuario',
  String? rolAnterior,
  DateTime? ultimoLogin,
  DateTime? rolUpdatedAt,
  String? rolUpdatedBy,
}) {
  return <String, Object?>{
    'id': id,
    'nombre': nombre,
    'apellido': apellido,
    'email': email,
    'rol': rol,
    'rolAnterior': rolAnterior,
    'ultimoLogin': ultimoLogin,
    'rolUpdatedAt': rolUpdatedAt,
    'rolUpdatedBy': rolUpdatedBy,
  };
}

/// Dos admins (uno soy yo), un usuario común, uno que fue admin y uno sin
/// nombre cargado.
List<Map<String, Object?>> _fixture() => <Map<String, Object?>>[
  _usuario(
    id: 'yo',
    nombre: 'Ana',
    apellido: 'Gómez',
    email: 'admin@cursar.app',
    rol: 'admin',
    ultimoLogin: DateTime(2026, 3, 1),
    rolUpdatedAt: DateTime(2026, 1, 10),
    rolUpdatedBy: 'fundadora@cursar.app',
  ),
  _usuario(
    id: 'a2',
    nombre: 'Bruno',
    apellido: 'Pérez',
    email: 'bruno@cursar.app',
    rol: 'admin',
    ultimoLogin: DateTime(2026, 3, 2),
    rolUpdatedAt: DateTime(2026, 2, 1),
    rolUpdatedBy: 'fundadora@cursar.app',
  ),
  _usuario(
    id: 'u3',
    nombre: 'Carla',
    apellido: 'Gómez',
    email: 'carla@gmail.com',
  ),
  _usuario(
    id: 'u4',
    nombre: 'Diego',
    apellido: 'Sosa',
    email: 'diego@gmail.com',
    rolAnterior: 'admin',
    rolUpdatedAt: DateTime(2026, 1, 20),
    rolUpdatedBy: 'admin@cursar.app',
  ),
  _usuario(id: 'u5', email: 'sin.nombre@gmail.com'),
];

void main() {
  group('AdminPolicy', () {
    final admin = _usuario(
      id: 'a',
      nombre: 'Ana',
      apellido: 'Gómez',
      email: 'ana@cursar.app',
      rol: 'admin',
    );
    final exAdmin = _usuario(
      id: 'b',
      nombre: 'Beto',
      apellido: 'Ruiz',
      email: 'beto@cursar.app',
      rolAnterior: 'admin',
    );
    final usuario = _usuario(id: 'c', nombre: 'Cami', email: 'cami@cursar.app');

    test('distingue admin, ex admin y usuario', () {
      expect(AdminPolicy.esAdmin(admin), isTrue);
      expect(AdminPolicy.esAdmin(exAdmin), isFalse);
      expect(AdminPolicy.fueAdmin(exAdmin), isTrue);
      expect(AdminPolicy.fueAdmin(admin), isFalse);
      expect(AdminPolicy.fueAdmin(usuario), isFalse);
    });

    test('nombre usa nombre + apellido y cae al email', () {
      expect(AdminPolicy.nombre(admin), 'Ana Gómez');
      expect(AdminPolicy.nombre(_usuario(id: 'x', nombre: 'Solo')), 'Solo');
      expect(
        AdminPolicy.nombre(_usuario(id: 'x', email: 'x@y.com')),
        'x@y.com',
      );
    });

    test('etiqueta suma el email, salvo que sea el mismo texto', () {
      expect(AdminPolicy.etiqueta(admin), 'Ana Gómez (ana@cursar.app)');
      expect(
        AdminPolicy.etiqueta(_usuario(id: 'x', email: 'x@y.com')),
        'x@y.com',
      );
    });

    test('busca por nombre o email, sin acentos ni mayúsculas', () {
      expect(AdminPolicy.coincide(admin, 'gomez'), isTrue);
      expect(AdminPolicy.coincide(admin, 'GÓMEZ'), isTrue);
      expect(AdminPolicy.coincide(admin, 'ana@'), isTrue);
      expect(AdminPolicy.coincide(admin, 'ruiz'), isFalse);
      expect(AdminPolicy.coincide(admin, '   '), isTrue);
    });

    test('separa administradores, candidatos y ex administradores', () {
      final usuarios = <Map<String, Object?>>[admin, exAdmin, usuario];
      expect(AdminPolicy.admins(usuarios), <Object>[admin]);
      expect(AdminPolicy.exAdmins(usuarios), <Object>[exAdmin]);
      expect(AdminPolicy.candidatos(usuarios), <Object>[exAdmin, usuario]);
    });

    test('bloquea quitarte el acceso a vos mismo', () {
      final motivo = AdminPolicy.bloqueoQuitar(
        u: admin,
        adminsTotal: 3,
        uidActual: 'a',
      );
      expect(motivo, isNotNull);
      expect(motivo, contains('vos mismo'));
    });

    test('bloquea quedarse sin ningún administrador', () {
      final motivo = AdminPolicy.bloqueoQuitar(
        u: admin,
        adminsTotal: 1,
        uidActual: 'otro',
      );
      expect(motivo, isNotNull);
      expect(motivo, contains('único administrador'));
    });

    test('permite quitar cuando hay otro admin y no sos vos', () {
      expect(
        AdminPolicy.bloqueoQuitar(u: admin, adminsTotal: 2, uidActual: 'otro'),
        isNull,
      );
    });

    test('el cambio de rol deja rastro de quién y qué había antes', () {
      expect(AdminPolicy.darAdmin(rolAnterior: 'usuario', por: 'a@b.com'), {
        'rol': 'admin',
        'rolAnterior': 'usuario',
        'rolUpdatedBy': 'a@b.com',
      });
      expect(AdminPolicy.quitarAdmin(por: 'a@b.com'), {
        'rol': 'usuario',
        'rolAnterior': 'admin',
        'rolUpdatedBy': 'a@b.com',
      });
    });
  });

  group('pantalla Administradores', () {
    late List<String> layoutErrors;

    setUp(() => layoutErrors = installLayoutErrorCapture());
    tearDown(removeLayoutErrorCapture);

    for (final entry in layoutViewports.entries) {
      testWidgets('no desborda a ${entry.key}', (tester) async {
        await pumpAt(
          tester,
          child: _pagina(usuarios: _fixture()),
          size: entry.value,
          mobile: entry.value.width < 900,
        );

        expect(find.byType(AdministradoresPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(layoutErrors, isEmpty, reason: layoutReason(layoutErrors));
      });
    }

    testWidgets('lista administradores y deja afuera al resto', (tester) async {
      await pumpAt(
        tester,
        child: _pagina(usuarios: _fixture()),
        size: const Size(1280, 800),
      );

      expect(find.text('Ana Gómez'), findsOneWidget);
      expect(find.text('Bruno Pérez'), findsOneWidget);
      expect(find.text('Carla Gómez'), findsNothing);
      expect(find.text('Quitar acceso'), findsNWidgets(2));
    });

    testWidgets('el botón de ex administradores cambia la lista', (
      tester,
    ) async {
      await pumpAt(
        tester,
        child: _pagina(usuarios: _fixture()),
        size: const Size(1280, 800),
      );

      await tester.tap(find.text('Ver ex administradores'));
      await tester.pumpAndSettle();

      expect(find.text('Diego Sosa'), findsOneWidget);
      expect(find.text('Bruno Pérez'), findsNothing);
      expect(find.text('Dar acceso'), findsOneWidget);
    });

    testWidgets('avisa cuando se quiere quitar al único admin', (tester) async {
      await pumpAt(
        tester,
        child: _pagina(
          uid: 'otro',
          usuarios: <Map<String, Object?>>[
            _usuario(
              id: 'a',
              nombre: 'Ana',
              apellido: 'Gómez',
              email: 'ana@cursar.app',
              rol: 'admin',
            ),
          ],
        ),
        size: const Size(1280, 800),
      );

      await tester.tap(find.text('Quitar acceso'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.textContaining('único administrador'), findsOneWidget);
    });
  });
}
