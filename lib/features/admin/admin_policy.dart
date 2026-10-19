// Reglas de acceso al panel: quién es administrador y qué se escribe al dar o
// quitar el rol.
//
// Vive aparte de la pantalla (`administradores_page.dart`), y sin dependencias
// de Flutter ni de Firestore, para poder testearla sola: acá están las dos
// decisiones peligrosas (auto-quitarse el acceso y quedarse sin ningún admin)
// que en la UI se traducen en bloqueos.

/// Un documento de `usuarios` (mapa crudo de Firestore, con su `id`).
typedef UsuarioDoc = Map<String, Object?>;

abstract final class AdminPolicy {
  /// El documento tiene acceso al panel. Es la misma condición que evalúa la
  /// regla de Firestore (`rol == 'admin'`), así que lo que la pantalla muestra
  /// habilitado coincide con lo que la base va a permitir.
  static bool esAdmin(UsuarioDoc u) => u['rol'] == 'admin';

  /// Fue admin y ya no lo es: le queda la marca `rolAnterior` que dejamos al
  /// quitarle el acceso. Sirve para el historial sin colección aparte.
  static bool fueAdmin(UsuarioDoc u) =>
      u['rol'] != 'admin' && u['rolAnterior'] == 'admin';

  /// Nombre legible: nombre + apellido, o el email como respaldo.
  static String nombre(UsuarioDoc u) {
    final nombre = '${u['nombre'] ?? ''}'.trim();
    final apellido = '${u['apellido'] ?? ''}'.trim();
    final completo = '$nombre $apellido'.trim();
    return completo.isNotEmpty ? completo : '${u['email'] ?? ''}'.trim();
  }

  /// Identificación para los diálogos de confirmación: "Nombre (email)".
  static String etiqueta(UsuarioDoc u) {
    final display = nombre(u);
    final email = '${u['email'] ?? ''}'.trim();
    if (email.isEmpty || email == display) return display;
    return '$display ($email)';
  }

  /// Motivo por el que NO se puede quitar el acceso a [u], o `null` si se
  /// puede.
  ///
  /// Los dos bloqueos evitan el mismo final: un panel al que nadie puede
  /// entrar. Como `isAdmin()` se resuelve leyendo el propio documento, en
  /// cuanto no queda ningún `rol: 'admin'` la única salida es la consola de
  /// Firebase.
  static String? bloqueoQuitar({
    required UsuarioDoc u,
    required int adminsTotal,
    required String? uidActual,
  }) {
    if (uidActual != null && '${u['id']}' == uidActual) {
      return 'No podés quitarte el acceso a vos mismo: te quedarías sin panel. '
          'Pedile a otro administrador que lo haga.';
    }
    if (adminsTotal <= 1) {
      return 'Es el único administrador. Si le quitás el acceso, nadie puede '
          'volver a entrar al panel (la única salida sería la consola de '
          'Firebase).';
    }
    return null;
  }

  /// Búsqueda por nombre o email, ignorando mayúsculas y acentos.
  static bool coincide(UsuarioDoc u, String consulta) {
    final q = _normalizar(consulta.trim());
    if (q.isEmpty) return true;
    return _normalizar(nombre(u)).contains(q) ||
        _normalizar('${u['email'] ?? ''}').contains(q);
  }

  /// Campos que se escriben al dar acceso de administrador.
  ///
  /// `rolAnterior` guarda de dónde venía (para poder mostrarlo en "Ex
  /// administradores" y para tener el rastro); `rolUpdatedBy` es el email del
  /// admin que hizo el cambio. El `rolUpdatedAt` lo agrega la pantalla con el
  /// `serverTimestamp()` de Firestore.
  static Map<String, Object?> darAdmin({
    required String rolAnterior,
    required String por,
  }) =>
      <String, Object?>{
        'rol': 'admin',
        'rolAnterior': rolAnterior,
        'rolUpdatedBy': por,
      };

  /// Campos que se escriben al quitar el acceso. La cuenta de la app no se
  /// toca: la persona sigue siendo usuaria de CURSAR, solo pierde el panel.
  static Map<String, Object?> quitarAdmin({required String por}) =>
      <String, Object?>{
        'rol': 'usuario',
        'rolAnterior': 'admin',
        'rolUpdatedBy': por,
      };

  /// Cuenta con `rol: 'admin'` que además ya tiene acceso.
  static List<UsuarioDoc> admins(List<UsuarioDoc> usuarios) =>
      usuarios.where(esAdmin).toList();

  /// Usuarios a los que se les puede dar acceso: todos menos los que ya son
  /// administradores.
  static List<UsuarioDoc> candidatos(List<UsuarioDoc> usuarios) =>
      usuarios.where((u) => !esAdmin(u)).toList();

  /// Ex administradores: los que tenían el rol y se les quitó.
  static List<UsuarioDoc> exAdmins(List<UsuarioDoc> usuarios) =>
      usuarios.where(fueAdmin).toList();

  /// Normaliza para comparar: minúsculas y sin acentos (el panel se usa en
  /// español y "Gómez" se busca como "gomez").
  static String _normalizar(String texto) {
    const conAcento = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const sinAcento = 'aaaaaeeeeiiiiooooouuuunc';

    final buffer = StringBuffer();
    for (final rune in texto.toLowerCase().runes) {
      final letra = String.fromCharCode(rune);
      final indice = conAcento.indexOf(letra);
      buffer.write(indice == -1 ? letra : sinAcento[indice]);
    }
    return buffer.toString();
  }
}
