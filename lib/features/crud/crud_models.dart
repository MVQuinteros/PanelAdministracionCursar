import '../../data/models/catalog_models.dart';
import '../../data/models/usuario_model.dart';

/// Escrituras de un módulo, desacopladas del modelo de Firestore.
///
/// El [CrudPage] no sabe si el módulo tiene joins, timestamps o reglas
/// propias: solo llama a [save] y a [remove]. Cada implementación traduce a la
/// colección correspondiente.
abstract interface class CrudWritable {
  /// Crea ([id] == null) o actualiza ([id] != null) un registro.
  Future<void> save(String? id, Map<String, Object?> values);

  Future<void> remove(String id);
}

/// Usuarios: el alta la hace la app móvil, así que acá solo se actualiza.
class _UsuarioCrud implements CrudWritable {
  const _UsuarioCrud();

  @override
  Future<void> save(String? id, Map<String, Object?> values) async {
    if (id == null) {
      throw UnsupportedError('El alta de usuarios se hace desde la app móvil.');
    }
    await UsuarioModel().update(id, values);
  }

  @override
  Future<void> remove(String id) => UsuarioModel().remove(id);
}

class _OfertaCrud implements CrudWritable {
  const _OfertaCrud();

  @override
  Future<void> save(String? id, Map<String, Object?> values) async {
    // El `createdAt` lo agrega `CrudPage` según `autoTimestamp`.
    if (id == null) {
      await OfertaModel().add(values);
    } else {
      await OfertaModel().update(id, values);
    }
  }

  @override
  Future<void> remove(String id) => OfertaModel().remove(id);
}

class _InstitucionCrud implements CrudWritable {
  const _InstitucionCrud();

  @override
  Future<void> save(String? id, Map<String, Object?> values) async {
    if (id == null) {
      await InstitucionModel().add(values);
    } else {
      await InstitucionModel().update(id, values);
    }
  }

  @override
  Future<void> remove(String id) => InstitucionModel().remove(id);
}

class _TagCrud implements CrudWritable {
  const _TagCrud();

  @override
  Future<void> save(String? id, Map<String, Object?> values) async {
    if (id == null) {
      await TagModel().add(values);
    } else {
      await TagModel().update(id, values);
    }
  }

  @override
  Future<void> remove(String id) => TagModel().remove(id);
}

class _AvisoCrud implements CrudWritable {
  const _AvisoCrud();

  @override
  Future<void> save(String? id, Map<String, Object?> values) async {
    if (id == null) {
      // `AvisoModel.add` ya instala el `publicado` server timestamp.
      await AvisoModel().add(values);
    } else {
      await AvisoModel().update(id, values);
    }
  }

  @override
  Future<void> remove(String id) => AvisoModel().remove(id);
}

class _SoporteCrud implements CrudWritable {
  const _SoporteCrud();

  @override
  Future<void> save(String? id, Map<String, Object?> values) async {
    if (id == null) {
      throw UnsupportedError('Los reportes los crea la app móvil.');
    }
    await SoporteModel().update(id, values);
  }

  @override
  Future<void> remove(String id) => SoporteModel().remove(id);
}

class _TestCrud implements CrudWritable {
  const _TestCrud();

  @override
  Future<void> save(String? id, Map<String, Object?> values) async {
    throw UnsupportedError('El módulo de test es de solo lectura.');
  }

  @override
  Future<void> remove(String id) => TestResultadoModel().remove(id);
}

/// Resuelve el modelo de escritura según el título del módulo.
CrudWritable crudWritableOf(String title) => switch (title) {
  'Usuarios' => const _UsuarioCrud(),
  'Ofertas' => const _OfertaCrud(),
  'Instituciones' => const _InstitucionCrud(),
  'Tags' => const _TagCrud(),
  'Avisos' => const _AvisoCrud(),
  'Soporte' => const _SoporteCrud(),
  'Test vocacional' => const _TestCrud(),
  _ => throw ArgumentError('Módulo CRUD sin modelo de escritura: $title'),
};
