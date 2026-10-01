import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo base genérico para Firestore.
///
/// Espejo exacto de `js/models/BaseModel.js`: `ref`, `docRef`, `list`, `get`,
/// `add`, `update`, `remove` con el mismo comportamiento.
class BaseModel<T> {
  BaseModel({
    required this.collectionPath,
    required this.sortField,
    this.sortDirDesc = true,
    required this.fromDoc,
    required this.toMap,
  });

  final String collectionPath;
  final String sortField;
  final bool sortDirDesc;
  final T Function(DocumentSnapshot<Map<String, Object?>> doc) fromDoc;
  final Map<String, Object?> Function(T data) toMap;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> ref() =>
      _db.collection(collectionPath);

  DocumentReference<Map<String, Object?>> docRef(String id) =>
      _db.collection(collectionPath).doc(id);

  /// Obtiene todos los documentos de la colección ordenados por `sortField`.
  Future<List<T>> list() async {
    final q = ref().orderBy(sortField, descending: sortDirDesc);
    final snap = await q.get();
    return snap.docs.map(fromDoc).toList();
  }

  /// Obtiene un documento por su `id`.
  Future<T?> get(String id) async {
    final snap = await docRef(id).get();
    if (!snap.exists) return null;
    return fromDoc(snap);
  }

  /// Crea un documento y retorna el `id` asignado.
  Future<String> add(T data) async {
    final created = await ref().add(toMap(data));
    return created.id;
  }

  /// Actualiza (mezcla) los campos pasados. `data` debe ser parcial.
  Future<void> update(String id, Map<String, Object?> data) async {
    await docRef(id).update(data);
  }

  /// Elimina el documento.
  Future<void> remove(String id) async {
    await docRef(id).delete();
  }
}
