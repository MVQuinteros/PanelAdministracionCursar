import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/auth_errors.dart';
import '../../data/models/usuario_model.dart';

/// Estados posibles de la sesión, equivalente al flujo de
/// `js/controllers/authController.js` (loading → login | denied | app).
enum AuthStatus { loading, unauthenticated, denied, admin }

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.adminDoc,
    this.error,
  });

  final AuthStatus status;
  final User? user;
  final Doc? adminDoc;
  final String? error;

  /// Nombre mostrable del admin (nombre + apellido, o email, o "Admin").
  String get adminName {
    final n = (adminDoc?['nombre'] as String?)?.trim() ?? '';
    final a = (adminDoc?['apellido'] as String?)?.trim() ?? '';
    final full = '$n $a'.trim();
    if (full.isNotEmpty) return full;
    final email = user?.email;
    return (email != null && email.isNotEmpty) ? email : 'Admin';
  }

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Doc? adminDoc,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      adminDoc: adminDoc ?? this.adminDoc,
      error: error,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<User?>? _sub;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  UsuarioModel get _usuarios => UsuarioModel();

  @override
  AuthState build() {
    _sub = _auth.authStateChanges().listen(_onAuthChanged);
    ref.onDispose(() => _sub?.cancel());
    return const AuthState();
  }

  /// Traduce el cambio de sesión de Firebase al flujo de la app.
  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final adminDoc = await _usuarios.get(firebaseUser.uid);
      if (UsuarioModel.isAdmin(adminDoc)) {
        state = AuthState(
          status: AuthStatus.admin,
          user: firebaseUser,
          adminDoc: adminDoc,
        );
      } else {
        state = AuthState(
          status: AuthStatus.denied,
          user: firebaseUser,
        );
      }
    } catch (_) {
      // Error leyendo el doc: por seguridad, acceso denegado.
      state = AuthState(status: AuthStatus.denied, user: firebaseUser);
    }
  }

  /// Relee el documento del admin (por ejemplo tras cambiarlo en otro lugar).
  Future<void> reloadAdminDoc() => _onAuthChanged(state.user);

  /// Login con email y contraseña. Devuelve `null` si funciona, o el mensaje
  /// de error ya traducido.
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } catch (err) {
      return AuthErrors.from(err);
    }
  }

  /// Registro de una cuenta admin (crea el doc con `rol: 'admin'`).
  Future<String?> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      await _usuarios.createWithUid(uid, <String, Object?>{
        'uid': uid,
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'email': email.trim(),
        'rol': 'admin',
        'localidad': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (err) {
      return AuthErrors.from(err);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
