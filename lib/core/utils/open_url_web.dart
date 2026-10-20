import 'package:web/web.dart' as web;

/// Abre [url] en una pestaña nueva.
///
/// Se usa `window.open` con `noopener` (y `noreferrer`): el panel no necesita
/// acceso a la ventana abierta y así el sitio destino no puede manipular esta.
/// A diferencia del `mailto:`, un link de verificación sí va a una pestaña
/// nueva: el admin consulta el padrón sin perder el panel.
void openUrl(String url) {
  if (url.isEmpty) return;
  web.window.open(url, '_blank', 'noopener,noreferrer');
}
