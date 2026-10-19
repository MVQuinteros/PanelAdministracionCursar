/// Armado del `mailto:` que abre el botón "Enviar por mail".
///
/// No se usa `Uri(queryParameters:)`: ese constructor codifica los espacios
/// como `+`, y en un `mailto:` varios clientes de correo muestran el `+`
/// literal en lugar de un espacio. Acá se codifica con `Uri.encodeComponent`
/// (espacios → `%20`), que es lo que aceptan Gmail, Outlook y compañía.
library;

/// Devuelve el `mailto:` con [subject] y [body] ya codificados.
///
/// [body] admite saltos de línea (`\n` → `%0A`); el texto y la firma los
/// arma quien llama.
String buildMailtoUri({
  required String to,
  required String subject,
  required String body,
}) {
  final query = <String>[
    'subject=${Uri.encodeComponent(subject)}',
    'body=${Uri.encodeComponent(body)}',
  ].join('&');
  return 'mailto:$to?$query';
}
