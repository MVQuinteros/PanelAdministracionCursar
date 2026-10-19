/// Apertura del cliente de correo con un `mailto:`.
///
/// `dart.library.js_interop` es la condición que Flutter usa para distinguir
/// compilaciones web de las de VM (tests, tooling). En web delega en
/// `open_mailto_web.dart` (`<a href="mailto:…">` + click); en el resto es un
/// no-op, para que el diálogo del prompt se pueda testear en la VM.
///
/// Mismo enfoque que `download_csv.dart`.
library;

export 'open_mailto_stub.dart'
    if (dart.library.js_interop) 'open_mailto_web.dart';
