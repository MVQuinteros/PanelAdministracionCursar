import 'package:cursar_admin_flutter/core/utils/export_csv.dart';
import 'package:cursar_admin_flutter/core/utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fmt.toDate', () {
    test('normaliza DateTime, Timestamp e ISO', () {
      final date = DateTime(2024, 3, 15, 10, 30);
      expect(Fmt.toDate(date), date);
      expect(
        Fmt.toDate(Timestamp.fromDate(date)),
        isA<DateTime>().having((d) => d.year, 'year', 2024),
      );
      expect(Fmt.toDate('2024-03-15T00:00:00.000Z'), isNotNull);
    });

    test('devuelve null para valores no fecha', () {
      expect(Fmt.toDate(null), isNull);
      expect(Fmt.toDate('no es una fecha'), isNull);
      expect(Fmt.toDate(<String>[]), isNull);
    });
  });

  group('Fmt.display', () {
    test('normaliza nulos, listas y GeoPoint', () {
      expect(Fmt.display(null), '—');
      expect(Fmt.display(''), '—');
      expect(Fmt.display(<String>['Técnico', 'Administración']), 'Técnico, Administración');
      expect(
        Fmt.display(const GeoPoint(-34.6, -58.4)),
        contains('-34.6'),
      );
    });
  });

  group('buildCsv', () {
    test('join con ";" y entrecomilla solo cuando hace falta', () {
      final csv = buildCsv(
        filename: 'usuarios',
        columns: <CsvColumn>[
          CsvColumn(label: 'Email', export: (row) => '${row['email']}'),
          CsvColumn(label: 'Rol', export: (row) => '${row['rol']}'),
        ],
        rows: <Map<String, Object?>>[
          <String, Object?>{'email': 'a@b.com', 'rol': 'admin'},
          <String, Object?>{'email': 'c@d.com', 'rol': 'apoyo; tecnico'},
        ],
      );

      // Excel usa CRLF como separador de registros.
      final lines = csv.split('\r\n');
      expect(lines[0], 'Email;Rol');
      expect(lines[1], 'a@b.com;admin');
      // El `;` interno obliga a entrecomillar el campo.
      expect(lines[2], 'c@d.com;"apoyo; tecnico"');
    });
  });
}
