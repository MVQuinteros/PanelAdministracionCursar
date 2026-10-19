import 'package:cursar_admin_flutter/core/utils/mailto.dart';
import 'package:flutter_test/flutter_test.dart';

/// El `mailto:` del botón "Enviar por mail".
///
/// Lo que importa acá es la codificación: si los espacios salen como `+`
/// (lo que hace `Uri(queryParameters:)`), varios clientes de correo los
/// muestran literales y el mail sale con el texto roto.
void main() {
  group('buildMailtoUri', () {
    test('arma destinatario, asunto y cuerpo', () {
      expect(
        buildMailtoUri(to: 'ana@mail.com', subject: 'Hola', body: 'Texto'),
        'mailto:ana@mail.com?subject=Hola&body=Texto',
      );
    });

    test('codifica los espacios como %20, no como +', () {
      final uri = buildMailtoUri(
        to: 'ana@mail.com',
        subject: 'Respuesta a tu reporte',
        body: 'Una respuesta larga',
      );

      expect(uri, contains('subject=Respuesta%20a%20tu%20reporte'));
      expect(uri, contains('body=Una%20respuesta%20larga'));
      expect(uri, isNot(contains('+')));
    });

    test('codifica acentos, saltos de línea y símbolos', () {
      final uri = buildMailtoUri(
        to: 'ana@mail.com',
        subject: 'Año nuevo & más',
        body: 'Hola:\n¿cómo estás?\n\n— Equipo CURSAR',
      );

      expect(uri, contains('subject=A%C3%B1o%20nuevo%20%26%20m%C3%A1s'));
      expect(
        uri,
        contains(
          'body=Hola%3A%0A%C2%BFc%C3%B3mo%20est%C3%A1s%3F%0A%0A'
          '%E2%80%94%20Equipo%20CURSAR',
        ),
      );
    });

    test('soporta asunto vacío', () {
      expect(
        buildMailtoUri(to: 'ana@mail.com', subject: '', body: 'x'),
        'mailto:ana@mail.com?subject=&body=x',
      );
    });
  });
}
