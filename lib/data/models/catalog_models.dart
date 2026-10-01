import 'package:cloud_firestore/cloud_firestore.dart';

import 'usuario_model.dart';

typedef Doc = Map<String, Object?>;

/// Colección `ofertas` (carreras/titulaciones), ordenada por `createdAt` desc.
class OfertaModel {
  static const collection = 'ofertas';

  Future<List<Doc>> list() async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => <String, Object?>{'id': d.id, ...d.data()}).toList();
  }

  Future<Doc?> get(String id) async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .get();
    if (!snap.exists) return null;
    return <String, Object?>{'id': snap.id, ...?snap.data()};
  }

  Future<String> add(Map<String, Object?> data) async {
    final ref = await FirebaseFirestore.instance
        .collection(collection)
        .add(data);
    return ref.id;
  }

  Future<void> update(String id, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .update(data);
  }

  Future<void> remove(String id) async {
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }

  /// Flujo de moderación: publicar o despublicar la oferta en la app.
  Future<void> setAprobada(String id, bool aprobada) =>
      update(id, {'aprobada': aprobada});
}

/// Colección `instituciones` (centros educativos), con conversión a
/// [GeoPoint] para el mapa de la app móvil.
class InstitucionModel {
  static const collection = 'instituciones';

  Future<List<Doc>> list() async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => <String, Object?>{'id': d.id, ...d.data()}).toList();
  }

  Future<String> add(Map<String, Object?> data) async {
    final ref = await FirebaseFirestore.instance
        .collection(collection)
        .add(_withGeo(data));
    return ref.id;
  }

  Future<void> update(String id, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .update(_withGeo(data));
  }

  Future<void> remove(String id) async {
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }

  /// Convierte `latitud`/`longitud` a un `ubicacion` GeoPoint, igual que
  /// `InstitucionModel._withGeo` del panel original.
  ///
  /// Si el documento trae las coordenadas pero quedan vacías o incompletas, se
  /// borra el `ubicacion` previo: de lo contrario el GeoPoint sobrevive a la
  /// edición y queda desincronizado con los campos visibles del formulario.
  /// Solo se borra cuando las coordenadas vienen en el payload, para no tocar
  /// el GeoPoint en actualizaciones parciales que no las mencionan.
  static Map<String, Object?> _withGeo(Map<String, Object?> data) {
    final rest = <String, Object?>{...data};
    final hasLatKey = rest.containsKey('latitud');
    final hasLngKey = rest.containsKey('longitud');
    final latitud = rest.remove('latitud');
    final longitud = rest.remove('longitud');
    final lat = _toCoord(latitud);
    final lng = _toCoord(longitud);
    if (lat != null && lng != null) {
      rest['ubicacion'] = GeoPoint(lat, lng);
    } else if (hasLatKey || hasLngKey) {
      rest['ubicacion'] = FieldValue.delete();
    }
    return rest;
  }

  /// Convierte a `double` sin explotar si el valor no es numérico.
  static double? _toCoord(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return null;
    if (value < -90 || value > 90) return null;
    return value;
  }
}

/// Colección `tags` (etiquetas de ofertas). Sin fecha: se ordena por nombre.
class TagModel {
  static const collection = 'tags';

  Future<List<Doc>> list() async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .orderBy('nombre')
        .get();
    return snap.docs.map((d) => <String, Object?>{'id': d.id, ...d.data()}).toList();
  }

  Future<String> add(Map<String, Object?> data) async {
    final ref = await FirebaseFirestore.instance
        .collection(collection)
        .add(data);
    return ref.id;
  }

  Future<void> update(String id, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .update(data);
  }

  Future<void> remove(String id) async {
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }
}

/// Colección `avisos` (noticias/campañas de la app), ordenada por publicación.
class AvisoModel {
  static const collection = 'avisos';

  Future<List<Doc>> list() async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .orderBy('publicado', descending: true)
        .get();
    return snap.docs.map((d) => <String, Object?>{'id': d.id, ...d.data()}).toList();
  }

  Future<String> add(Map<String, Object?> data) async {
    final ref = await FirebaseFirestore.instance
        .collection(collection)
        .add(<String, Object?>{
          ...data,
          'publicado': FieldValue.serverTimestamp(),
        });
    return ref.id;
  }

  Future<void> update(String id, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .update(data);
  }

  Future<void> remove(String id) async {
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }
}

/// Colección `soporte` (reportes enviados desde la app).
class SoporteModel {
  static const collection = 'soporte';

  Future<List<Doc>> list() async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => <String, Object?>{'id': d.id, ...d.data()}).toList();
  }

  Future<void> setEstado(String id, String estado) =>
      update(id, {'estado': estado});

  Future<void> update(String id, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .update(data);
  }

  Future<void> remove(String id) async {
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }
}

/// Resultados del test vocacional.
///
/// Viven en `testVocacional/data/resultados` y los escribe la app móvil.
/// El admin solo lee y puede limpiar resultados, por eso no hay `add`/`update`.
class TestResultadoModel {
  static const collectionPath = 'testVocacional/data/resultados';

  /// Lista los resultados enriqueciéndolos con su usuario (join por `userUid`).
  Future<List<Doc>> list() async {
    final snap = await FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('createdAt', descending: true)
        .get();

    List<Doc> usuarios = const [];
    try {
      usuarios = await UsuarioModel().list();
    } catch (_) {
      // Si no se pueden leer los usuarios, se muestran los uids crudos.
    }
    // Un usuario sin `id`/`uid` (documento raro o mal formado) no debe romper
    // el listado completo: se lo saltea y el resultado queda sin `_usuario`.
    final byUid = <String, Doc>{};
    for (final u in usuarios) {
      final key = u['id'] ?? u['uid'];
      if (key is String && key.isNotEmpty) byUid[key] = u;
    }

    return snap.docs.map((d) {
      final row = <String, Object?>{'id': d.id, ...d.data()};
      row['_usuario'] = byUid[row['userUid']];
      return row;
    }).toList();
  }

  Future<void> remove(String id) async {
    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(id)
        .delete();
  }
}
