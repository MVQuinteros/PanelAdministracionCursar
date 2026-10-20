// Reglas del módulo Instituciones: identificador oficial (CUE / SPU), link de
// verificación y auditoría de estado.
//
// Vive aparte de la pantalla (`instituciones_page.dart`), sin dependencias de
// Flutter ni de Firestore, para poder testearla sola: acá están las decisiones
// que no se ven en la UI (qué link corresponde a cada fuente, cuándo un CUE es
// válido, qué se escribe al aprobar o rechazar).

/// Un documento de `instituciones` (mapa crudo de Firestore, con su `id`).
typedef InstitucionDoc = Map<String, Object?>;

/// Ficha de verificación resuelta para una institución.
///
/// [etiqueta] es lo que se muestra en la tabla (el CUE, o "SPU", o la
/// dependencia); [url] es el link al registro oficial, o `null` si no hay nada
/// que verificar.
class IdentificadorInfo {
  const IdentificadorInfo({
    required this.etiqueta,
    required this.url,
    this.esCodigo = false,
  });

  /// Texto de la celda: el CUE, "SPU" o la institución madre.
  final String etiqueta;

  /// Link al registro oficial. `null` → la celda no es clickeable.
  final String? url;

  /// `true` cuando [etiqueta] es un código oficial (CUE), para mostrarlo en
  /// monoespaciado y no confundirlo con el nombre de la madre.
  final bool esCodigo;
}

abstract final class InstitucionesPolicy {
  /// Patrón oficial del CUE: 9 dígitos (2 jurisdicción + 5 establecimiento + 2
  /// localización) y, opcionalmente, 4 más del anexo.
  static final RegExp cueRegex = RegExp(r'^\d{9}(\d{4})?$');

  /// Un CUE es válido si respeta el patrón oficial.
  static bool cueValido(String? cue) =>
      cue != null && cueRegex.hasMatch(cue.trim());

  /// URL de la consulta ciudadana de SITRARED para un CUE.
  ///
  /// SITRARED no expone una URL por CUE: la consulta es un formulario con
  /// login, así que el link apunta al buscador, que es lo único estable y
  /// público. Se documenta el CUE en la celda para que el admin lo pegue.
  static const String sitraredUrl =
      'https://sitrared.educacion.gob.ar/SITRARED/meConsultaCiudadana/ConsultaCue/Index';

  /// Listado de universidades del SPU (Registro Nacional de Universidades).
  static const String spuUrl = 'https://www.argentina.gob.ar/educacion/universidades';

  /// Resuelve la ficha de verificación de [row].
  ///
  /// El orden importa: el CUE (establecimiento verificado) manda sobre `fuente`
  /// suelta; después la fuente; y por último la dependencia, que no verifica
  /// nada pero es información útil (una sede de la UBA).
  static IdentificadorInfo info(InstitucionDoc row) {
    final cue = _texto(row['cue']);
    if (cue.isNotEmpty) {
      return IdentificadorInfo(
        etiqueta: cue,
        url: sitraredUrl,
        esCodigo: true,
      );
    }

    switch (_texto(row['fuente']).toUpperCase()) {
      case 'SPU':
        return const IdentificadorInfo(etiqueta: 'SPU', url: spuUrl);
      case 'CUE':
        // Fuente declarada sin código: no hay nada clickeable que verificar.
        return const IdentificadorInfo(etiqueta: 'CUE (sin código)', url: null);
    }

    final dependeDe = _texto(row['dependeDe']);
    if (dependeDe.isNotEmpty) {
      return IdentificadorInfo(etiqueta: dependeDe, url: null);
    }

    return const IdentificadorInfo(etiqueta: '—', url: null);
  }

  /// Estado normalizado de la fila: los documentos sin `estado` cuentan como
  /// `pendiente`, igual que en la tabla y el filtro.
  static String estado(InstitucionDoc row) =>
      _texto(row['estado']).isEmpty ? 'pendiente' : _texto(row['estado']);

  static bool esPendiente(InstitucionDoc row) => estado(row) == 'pendiente';

  static bool esAprobada(InstitucionDoc row) => estado(row) == 'aprobada';

  static bool esRechazada(InstitucionDoc row) => estado(row) == 'rechazada';

  /// Campos que se escriben al aprobar.
  ///
  /// Limpia `motivoRechazo` (una institución aprobada no arrastra el motivo de
  /// un rechazo anterior) y deja `estado` en `aprobada`.
  static Map<String, Object?> aprobar() => <String, Object?>{
        'estado': 'aprobada',
        'motivoRechazo': '',
      };

  /// Campos que se escriben al rechazar. El motivo lo aporta el prompt y lo
  /// escribe el diálogo en `motivoRechazo`.
  static Map<String, Object?> rechazar() => <String, Object?>{
        'estado': 'rechazada',
      };

  /// Texto para el CSV de la columna identificador.
  static String csvIdentificador(InstitucionDoc row) => info(row).etiqueta;

  static String _texto(Object? value) => value == null ? '' : '$value'.trim();
}
