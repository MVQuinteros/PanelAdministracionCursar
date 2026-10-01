import 'package:firebase_auth/firebase_auth.dart';

/// Mensajes de error de Firebase Auth en español.
///
/// Mapeo de `AUTH_ERROR_MESSAGES` en `js/controllers/authController.js`.
/// Los códigos son los mismos entre el SDK web y el de Flutter.
abstract final class AuthErrors {
  static const Map<String, String> _messages = <String, String>{
    'invalid-email': 'El email no tiene un formato válido.',
    'user-disabled': 'Esta cuenta fue deshabilitada.',
    'user-not-found': 'No existe una cuenta con ese email.',
    'wrong-password': 'La contraseña es incorrecta.',
    'invalid-credential': 'El email o la contraseña son incorrectos.',
    'invalid-login-credentials': 'El email o la contraseña son incorrectos.',
    'too-many-requests': 'Demasiados intentos fallidos. '
        'Esperá un momento y probá de nuevo.',
    'email-already-in-use': 'Ya existe una cuenta con ese email.',
    'weak-password': 'La contraseña debe tener al menos 6 caracteres.',
    'operation-not-allowed': 'El registro está deshabilitado en Firebase '
        'Authentication.',
    'network-request-failed': 'Sin conexión a internet. Revisá tu red.',
  };

  static const String fallback =
      'Ocurrió un error de autenticación. Reintentá.';

  /// Traduce cualquier error de Firebase Auth a un mensaje en español.
  static String from(Object error) {
    final code = _codeOf(error);
    if (code == null) return fallback;
    return _messages[code] ?? fallback;
  }

  /// Lee el `code` de un [FirebaseAuthException]; null si no lo tiene.
  static String? _codeOf(Object error) {
    if (error is! FirebaseAuthException) return null;
    final code = error.code;
    // El SDK web a veces deja el prefijo "auth/".
    return code.startsWith('auth/') ? code.substring(5) : code;
  }
}
