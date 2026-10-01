/// Descarga de archivos en el navegador, resuelta por plataforma.
///
/// `dart.library.js_interop` es la condición que Flutter usa para distinguir
/// compilaciones web de las de VM (tests, tooling). En web delega en
/// `csv_web.dart` (Blob + `<a download>`); en el resto es un no-op, para que
/// la lógica pura de `buildCsv` se pueda testear en la VM.
///
library;
export 'download_csv_stub.dart'
    if (dart.library.js_interop) 'csv_web.dart';
