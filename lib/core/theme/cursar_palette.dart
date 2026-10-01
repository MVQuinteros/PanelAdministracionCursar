import 'package:flutter/material.dart';

/// Tokens de color del panel CURSAR.
///
/// Espejo 1:1 de las variables CSS de `css/styles.css` del panel original
/// (Vanilla JS), para que el port se vea idéntico en ambos temas.
///
/// - Tema oscuro  → "GitHub Dark"  (paleta base #0E1117 / #161B22 / #30363D)
/// - Tema claro   → "celeste y blanco" (paleta #FDFDFF / #FFFFFF / #E0E0E0)
@immutable
class CursarPalette extends ThemeExtension<CursarPalette> {
  const CursarPalette({
    required this.bgMain,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgInput,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentHover,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.purple,
  });

  final Color bgMain;
  final Color bgSurface;
  final Color bgElevated;
  final Color bgInput;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentHover;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color purple;

  /// Paleta oscura (valor por defecto del CSS original).
  static const dark = CursarPalette(
    bgMain: Color(0xFF0E1117),
    bgSurface: Color(0xFF161B22),
    bgElevated: Color(0xFF1C2128),
    bgInput: Color(0xFF0E1117),
    borderSubtle: Color(0xFF30363D),
    borderStrong: Color(0xFF444C56),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF8B949E),
    textMuted: Color(0xFF6E7681),
    accent: Color(0xFF007BFF),
    accentHover: Color(0xFF1E88E5),
    accentSoft: Color(0x24007BFF),
    success: Color(0xFF2EA043),
    successSoft: Color(0x242EA043),
    warning: Color(0xFFD29922),
    warningSoft: Color(0x24D29922),
    danger: Color(0xFFE53935),
    dangerSoft: Color(0x24E53935),
    purple: Color(0xFF9C27B0),
  );

  /// Paleta clara de marca (celeste y blanco), identitaria de la app móvil.
  static const light = CursarPalette(
    bgMain: Color(0xFFFDFDFF),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFF7F9FD),
    bgInput: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE0E0E0),
    borderStrong: Color(0xFFC4CBD5),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF98A2B3),
    accent: Color(0xFF1E88E5),
    accentHover: Color(0xFF1976D2),
    accentSoft: Color(0x1A1E88E5),
    success: Color(0xFF2E9E5B),
    successSoft: Color(0x1F2E9E5B),
    warning: Color(0xFFB5861F),
    warningSoft: Color(0x1FB5861F),
    danger: Color(0xFFD92D20),
    dangerSoft: Color(0x1AD92D20),
    purple: Color(0xFF7C3AED),
  );

  /// Color de fondo de la banda superior en modo claro: la imagen de marca
  /// velada con un gradiente, como el `background` compuesto del CSS.
  static const lightTopbarOverlay = Color(0xD9EFF6FF);

  /// Verde suave para `.banner--info` en tema oscuro (`#9DC6F5`).
  static const darkInfoBanner = Color(0xFF9DC6F5);

  /// Amarillo suave para `.banner--warning` en tema oscuro (`#E8C877`).
  static const darkWarningBanner = Color(0xFFE8C877);

  /// Rojo suave para `.auth-error` en tema oscuro (`#FFA29F`).
  static const darkAuthError = Color(0xFFFFA29F);

  @override
  CursarPalette copyWith({
    Color? bgMain,
    Color? bgSurface,
    Color? bgElevated,
    Color? bgInput,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentHover,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? purple,
  }) {
    return CursarPalette(
      bgMain: bgMain ?? this.bgMain,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      bgInput: bgInput ?? this.bgInput,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      purple: purple ?? this.purple,
    );
  }

  @override
  CursarPalette lerp(ThemeExtension<CursarPalette>? other, double t) {
    if (other is! CursarPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return CursarPalette(
      bgMain: c(bgMain, other.bgMain),
      bgSurface: c(bgSurface, other.bgSurface),
      bgElevated: c(bgElevated, other.bgElevated),
      bgInput: c(bgInput, other.bgInput),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      accentHover: c(accentHover, other.accentHover),
      accentSoft: c(accentSoft, other.accentSoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      purple: c(purple, other.purple),
    );
  }
}

/// Acceso corto a la paleta desde cualquier `BuildContext`.
extension CursarThemeX on BuildContext {
  CursarPalette get palette => Theme.of(this).extension<CursarPalette>()!;

  TextTheme get texts => Theme.of(this).textTheme;
}
