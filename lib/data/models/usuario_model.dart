import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Map genérico de un documento de Firestore (id + campos).
typedef Doc = Map<String, Object?>;

/// Colección `usuarios`. Ordenada por `ultimoLogin` descendente.
class UsuarioModel {
  static const collection = 'usuarios';
  static const sortField = 'ultimoLogin';

  Future<List<Doc>> list() async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .orderBy(sortField, descending: true)
        .get();
    return snap.docs.map((d) => <String, Object?>{'id': d.id, ...d.data()}).toList();
  }

  Future<Doc?> get(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .get();
    if (!snap.exists) return null;
    return <String, Object?>{'id': snap.id, ...?snap.data()};
  }

  Future<void> setRol(String uid, String rol) => update(uid, {'rol': rol});

  /// Crea el documento del usuario usando su uid como id (registro admin).
  Future<void> createWithUid(String uid, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .set(data);
  }

  Future<void> update(String uid, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .update(data);
  }

  Future<void> remove(String uid) async {
    await FirebaseFirestore.instance.collection(collection).doc(uid).delete();
  }

  /// El usuario es admin si su documento tiene `rol == 'admin'`.
  static bool isAdmin(Doc? doc) => doc?['rol'] == 'admin';

  /// Nombre legible: nombre + apellido, o el email como fallback.
  static String displayName(Doc? doc) {
    if (doc == null) return '';
    final nombre = (doc['nombre'] as String?)?.trim() ?? '';
    final apellido = (doc['apellido'] as String?)?.trim() ?? '';
    final full = '$nombre $apellido'.trim();
    return full.isNotEmpty ? full : ((doc['email'] as String?) ?? '');
  }

  @visibleForTesting
  static String nombreCompleto(Doc doc) => displayName(doc);
}
