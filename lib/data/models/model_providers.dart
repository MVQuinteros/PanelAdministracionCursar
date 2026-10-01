import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_models.dart';
import 'usuario_model.dart';

typedef Doc = Map<String, Object?>;

/// Cada modelo es un provider simple; se sobreescriben con `overrideWith` en
/// `main()` para poder inyectar dobles en los tests.
final usuarioModelProvider = Provider<UsuarioModel>(
  (ref) => UsuarioModel(),
);

final ofertaModelProvider = Provider<OfertaModel>(
  (ref) => OfertaModel(),
);

final institucionModelProvider = Provider<InstitucionModel>(
  (ref) => InstitucionModel(),
);

final tagModelProvider = Provider<TagModel>((ref) => TagModel());

final avisoModelProvider = Provider<AvisoModel>((ref) => AvisoModel());

final soporteModelProvider = Provider<SoporteModel>(
  (ref) => SoporteModel(),
);

final testResultadoModelProvider = Provider<TestResultadoModel>(
  (ref) => TestResultadoModel(),
);

/// Shortcut a la instancia de Firestore (usada por el dashboard).
final firestoreInstanceProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
