import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilidades puras: formato de fechas, valores y texto.
///
/// Espejo de `js/utils/helpers.js` del panel original. Ya no hace falta `esc()`
/// porque Flutter no interpreta HTML, pero se conserva `toDate` (normaliza
/// `Timestamp` de Firestore, `DateTime` e ISO) y el resto de los formatters.
abstract final class Fmt {
  /// Normaliza cualquier valor tipo fecha a [DateTime] en hora local.
  static DateTime? toDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    // Timestamp de cloud_firestore.
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `dd/mm/yyyy` (locale es-AR del JS). Devuelve `—` si viene vacía.
  static String date(Object? value) {
    final d = toDate(value);
    if (d == null) return '—';
    return '${_two(d.day)}/${_two(d.month)}/${d.year}';
  }

  /// `dd/mm/yyyy hh:mm` (locale es-AR del JS).
  static String dateTime(Object? value) {
    final d = toDate(value);
    if (d == null) return '—';
    return '${_two(d.day)}/${_two(d.month)}/${d.year} '
        '${_two(d.hour)}:${_two(d.minute)}';
  }

  /// Texto seguro para mostrar en una celda de tabla.
  static String display(Object? value) {
    if (value == null || value == '') return '—';
    if (value is bool) return value ? 'Sí' : 'No';
    if (value is List) return value.join(', ');
    if (value is Timestamp) return date(value);
    if (value is GeoPoint) {
      return '${value.latitude.toStringAsFixed(4)}, '
          '${value.longitude.toStringAsFixed(4)}';
    }
    if (value is DateTime) return date(value);
    return value.toString();
  }

  /// Entero con separador de miles es-AR (`1.234`).
  static String number(num? n) {
    final v = (n ?? 0).toDouble();
    final s = v == v.roundToDouble() && v.abs() < 1e15
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
    final neg = s.startsWith('-');
    final digits = neg ? s.substring(1) : s;
    final parts = <String>[];
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      parts.add(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) parts.add('.');
    }
    return (neg ? '-' : '') + parts.join();
  }

  /// Iniciales para el avatar del admin (máx. 2 letras).
  static String initials(String? nombre, String? apellido) {
    final n = (nombre == null || nombre.isEmpty) ? '' : nombre[0];
    final a = (apellido == null || apellido.isEmpty) ? '' : apellido[0];
    final out = '$n$a'.toUpperCase();
    return out.isEmpty ? '?' : out;
  }
}
