import 'csv_stub.dart' if (dart.library.js_interop) 'csv_web.dart' as impl;

/// Descarga un CSV en el navegador.
///
/// En web usa Blob + `<a download>` (mismo mecanismo que el panel original).
/// En la VM (tests) resuelve al stub no-op para que `flutter test` compile.
void downloadCsv({required String filename, required String csv}) {
  impl.downloadCsv(filename: filename, csv: csv);
}
