/// Sello del build publicado.
///
/// Lo inyecta el workflow de Pages (`--dart-define=BUILD_SHA=${{ github.sha }}`)
/// y se muestra chiquito al pie del menú lateral. Sirve para cortar la duda
/// recurrente de "no veo los cambios": GitHub Pages cachea 10 minutos, así que
/// puede estar sirviendo el build anterior, y mirar el hash es la forma rápida
/// de saber cuál está viendo cada uno.
const String kBuildSha = String.fromEnvironment('BUILD_SHA');

/// Etiqueta corta del build actual; `build local` en los builds de desarrollo
/// (hechos con `flutter run`, que no pasan `--dart-define`).
String get buildLabel {
  if (kBuildSha.isEmpty) return 'build local';
  final short = kBuildSha.length > 7 ? kBuildSha.substring(0, 7) : kBuildSha;
  return 'build $short';
}
