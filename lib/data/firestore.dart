import 'package:cloud_firestore/cloud_firestore.dart';

/// Instancia única de Firestore compartida con la app móvil CURSAR.
///
/// El panel original tenía `js/models/db.js`; acá se cumple el mismo rol.
/// Los modelos usan `FirebaseFirestore.instance` directamente, igual que el
/// `db` del original.
FirebaseFirestore get db => FirebaseFirestore.instance;

/// Convierte un snapshot de [Query] a una lista de mapas con el `id` incluido
/// (mismo criterio que `snapshot.docs.map(d => ({ id: d.id, ...d.data() }))`).
List<Map<String, Object?>> toRows(QuerySnapshot<Map<String, Object?>> snapshot) {
  return snapshot.docs
      .map((doc) => <String, Object?>{'id': doc.id, ...doc.data()})
      .toList();
}
