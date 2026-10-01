import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog_models.dart';
import '../../data/models/model_providers.dart';

typedef Doc = Map<String, Object?>;

/// Datos agregados del dashboard.
///
/// Equivale a `dashboardController.js`: lee las seis colecciones en paralelo y
/// arma los contadores y las series de los cuatro gráficos. Cada lectura es
/// "segura": si una colección falla por permisos, el módulo sigue funcionando
/// con el resto (mismo `safeList()` del original).
class DashboardData {
  const DashboardData({
    this.usuarios = const <Doc>[],
    this.ofertas = const <Doc>[],
    this.instituciones = const <Doc>[],
    this.tags = const <Doc>[],
    this.avisos = const <Doc>[],
    this.soporte = const <Doc>[],
    this.resultados = const <Doc>[],
  });

  final List<Doc> usuarios;
  final List<Doc> ofertas;
  final List<Doc> instituciones;
  final List<Doc> tags;
  final List<Doc> avisos;
  final List<Doc> soporte;
  final List<Doc> resultados;

  static Future<DashboardData> load(Ref ref) async {
    // Las siete lecturas salen en paralelo, igual que el `Promise.all` del
    // original; cada una es "segura" para que una colección sin permiso no
    // rompa el dashboard.
    final (
      List<Doc> usuarios,
      List<Doc> ofertas,
      List<Doc> instituciones,
      List<Doc> tags,
      List<Doc> avisos,
      List<Doc> soporte,
      List<Doc> resultados,
    ) = await (
      _safe(() => ref.read(usuarioModelProvider).list()),
      _safe(() => ref.read(ofertaModelProvider).list()),
      _safe(() => ref.read(institucionModelProvider).list()),
      _safe(() => ref.read(tagModelProvider).list()),
      _safe(() => ref.read(avisoModelProvider).list()),
      _safe(() => ref.read(soporteModelProvider).list()),
      _safe(_loadResultados),
    ).wait;

    return DashboardData(
      usuarios: usuarios,
      ofertas: ofertas,
      instituciones: instituciones,
      tags: tags,
      avisos: avisos,
      soporte: soporte,
      resultados: resultados,
    );
  }

  /// Resultados del test: subcolección anidada, sin modelo de dominio.
  static Future<List<Doc>> _loadResultados() async {
    final snap = await FirebaseFirestore.instance
        .collection(TestResultadoModel.collectionPath)
        .get();
    return snap.docs
        .map((d) => <String, Object?>{'id': d.id, ...d.data()})
        .toList();
  }

  static Future<List<Doc>> _safe(Future<List<Doc>> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return const <Doc>[];
    }
  }

  int get ofertasAprobadas => ofertas.where((o) => o['aprobada'] == true).length;

  int get ofertasPendientes => ofertas.length - ofertasAprobadas;

  int get institucionesAprobadas =>
      instituciones.where((i) => i['estado'] == 'aprobada').length;

  int get institucionesPendientes =>
      instituciones.where((i) => i['estado'] == 'pendiente').length;

  int get institucionesRechazadas =>
      instituciones.length - institucionesAprobadas - institucionesPendientes;

  int get admins => usuarios.where((u) => u['rol'] == 'admin').length;

  int get soportePendiente =>
      soporte.where((s) => s['estado'] != 'resuelto').length;

  /// Subtítulo de la card de instituciones: omite los contadores en cero,
  /// igual que el original.
  String get institucionesSub {
    final parts = <String>['$institucionesAprobadas aprobadas'];
    if (institucionesPendientes > 0) {
      parts.add('$institucionesPendientes pendientes');
    }
    if (institucionesRechazadas > 0) {
      parts.add('$institucionesRechazadas rechazadas');
    }
    return parts.join(' · ');
  }
}

final dashboardProvider = FutureProvider<DashboardData>(
  (ref) => DashboardData.load(ref),
);

/// Cuenta ocurrencias por clave, con `(sin dato)` para los vacíos.
///
/// Espejo de `countBy()` del controlador original.
Map<String, int> countBy(List<Doc> rows, String key) {
  final acc = <String, int>{};
  for (final row in rows) {
    final value = row[key];
    final k = (value == null || '$value'.isEmpty) ? '(sin dato)' : '$value';
    acc[k] = (acc[k] ?? 0) + 1;
  }
  return acc;
}

/// Ordena por cantidad descendente, como `sortedEntries()`.
Map<String, int> sortedCounts(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return <String, int>{for (final e in entries) e.key: e.value};
}
