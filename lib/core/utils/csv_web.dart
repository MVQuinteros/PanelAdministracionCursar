import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Descarga un CSV en el navegador.
///
/// Espejo de `js/utils/exportCSV.js`: UTF-8 **con BOM** y separador `;`
/// para que Excel (es-AR) lo abra bien.
void downloadCsv({required String filename, required String csv}) {
  // BOM UTF-8 para que Excel detecte la codificación.
  final bytes = Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = '$filename.csv';
  anchor.style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}
