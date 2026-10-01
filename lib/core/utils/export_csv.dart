import 'download_csv.dart';
import 'formatters.dart';

/// Exportación a CSV compatible con Excel en español.
///
/// Espejo de `js/utils/exportCSV.js`: separador `;`, UTF-8 con BOM, y las
/// celdas se escapan cuando contienen `"`, `;`, salto de línea o `\r`.
///
/// Devuelve el CSV armado y además dispara la descarga (no-op fuera de web).
String buildCsv({
  required String filename,
  required List<CsvColumn> columns,
  required List<Map<String, Object?>> rows,
}) {
  final header = columns.map((c) => _cell(c.label)).join(';');
  final lines = <String>[
    for (final row in rows) columns.map((c) => _cell(c.export(row))).join(';'),
  ];
  final csv = [header, ...lines].join('\r\n');
  downloadCsv(filename: filename, csv: csv);
  return csv;
}

/// Una columna exportable del CRUD.
class CsvColumn {
  const CsvColumn({required this.label, required this.export});

  final String label;
  final String Function(Map<String, Object?> row) export;
}

String _cell(Object? value) {
  final text = value?.toString() ?? '';
  if (RegExp(r'[";\n\r]').hasMatch(text)) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// Columna de exportación a partir de una clave simple del registro.
CsvColumn csvColumn(String key, String label) {
  return CsvColumn(label: label, export: (row) => Fmt.display(row[key]));
}
