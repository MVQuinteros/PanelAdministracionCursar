/// Apertura de un link externo en una pestaña nueva.
///
/// `dart.library.js_interop` es la condición que Flutter usa para distinguir
/// compilaciones web de las de VM (tests, tooling). En web delega en
/// `open_url_web.dart` (`window.open` con `noopener`); en el resto es un no-op,
/// para que las celdas de la tabla y el formulario se puedan testear en la VM.
///
/// Mismo enfoque que `open_mailto.dart` y `download_csv.dart`.
library;

export 'open_url_stub.dart' if (dart.library.js_interop) 'open_url_web.dart';
