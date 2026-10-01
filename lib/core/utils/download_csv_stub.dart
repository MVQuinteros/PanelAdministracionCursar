/// Implementación de [downloadCsv] para compilaciones que no son web.
///
/// Existe para que `buildCsv` (que es lógica pura) se pueda ejecutar en tests
/// de VM. En web gana `csv_web.dart` gracias al export condicional de
/// `download_csv.dart`.
void downloadCsv({required String filename, required String csv}) {}
