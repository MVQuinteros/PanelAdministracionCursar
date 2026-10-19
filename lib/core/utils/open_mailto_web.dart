import 'package:web/web.dart' as web;

/// Abre el cliente de correo del admin con el `mailto:` recibido.
///
/// Igual que `csv_web.dart` con la descarga: se crea el `<a>`, se clickea
/// dentro del gesto del usuario y se lo saca del DOM. No se usa
/// `window.open` para no depender del bloqueo de popups.
void openMailto(String uri) {
  final body = web.document.body;
  if (body == null) return;

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = uri;
  body.appendChild(anchor);
  anchor.click();
  body.removeChild(anchor);
}
