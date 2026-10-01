import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cursar_palette.dart';

/// Radios, tipografía y espaciados tomados de `css/styles.css`.
abstract final class AppTokens {
  static const double radius = 12;
  static const double radiusSm = 8;
  static const double radiusLg = 14;
  static const double sidebarWidth = 248;
  static const double topbarHeight = 62;
  static const double contentPadding = 24;
  static const double contentPaddingMobile = 16;
  static const double breakpointMobile = 900;
  static const double tableMaxHeight = 560;

  /// Familia tipográfica del CSS: "Segoe UI", -apple-system, …, sans-serif.
  static const List<String> fontFamilyFallback = <String>[
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  /// Claves de tamano de `TextTheme` (no usamos `google_fonts` para no
  /// agregar una descarga de red: el CSS usaba la pila de sistema).
  static const double xs = 11;
  static const double sm = 12;
  static const double sm2 = 12.5;
  static const double md = 13;
  static const double md2 = 13.5;
  static const double lg = 14;
  static const double xl = 15;
  static const double xxl = 16;
  static const double statValue = 26;
  static const double authTitle = 19;
}

/// Construye los dos `ThemeData` del panel, en línea con los estilos del CSS.
abstract final class AppTheme {
  static ThemeData dark() => _build(CursarPalette.dark, Brightness.dark);

  static ThemeData light() => _build(CursarPalette.light, Brightness.light);

  static ThemeData _build(CursarPalette p, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: Colors.white,
          surface: p.bgSurface,
          onSurface: p.textPrimary,
          error: p.danger,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bgMain,
      splashFactory: InkSparkle.splashFactory,
      fontFamilyFallback: AppTokens.fontFamilyFallback,
      extensions: <ThemeExtension<dynamic>>[p],
    );

    return base.copyWith(
      dividerTheme: DividerThemeData(
        color: p.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: p.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: BorderSide(color: p.borderSubtle),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bgSurface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: AppTokens.xxl,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bgInput,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        hintStyle: TextStyle(color: p.textMuted, fontSize: AppTokens.md2),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: AppTokens.md2),
        floatingLabelStyle: TextStyle(
          color: p.accent,
          fontSize: AppTokens.md2,
        ),
        helperStyle: TextStyle(color: p.textMuted, fontSize: AppTokens.xs),
        helperMaxLines: 2,
        errorStyle: TextStyle(color: p.danger, fontSize: AppTokens.xs),
        border: _inputBorder(p.borderSubtle),
        enabledBorder: _inputBorder(p.borderSubtle),
        focusedBorder: _inputBorder(p.accent, width: 1.4),
        errorBorder: _inputBorder(p.danger),
        focusedErrorBorder: _inputBorder(p.danger, width: 1.4),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: const TextStyle(
            fontSize: AppTokens.md2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.borderStrong),
          textStyle: const TextStyle(
            fontSize: AppTokens.md2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: AppTokens.md2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.bgSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: BorderSide(color: p.borderSubtle),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        width: AppTokens.sidebarWidth,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.bgElevated,
        contentTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: AppTokens.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          side: BorderSide(color: p.borderStrong),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.bgElevated,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(color: p.borderStrong),
        ),
        textStyle: TextStyle(color: p.textPrimary, fontSize: AppTokens.sm),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.borderSubtle,
        circularTrackColor: p.borderSubtle,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.borderStrong),
        trackColor: WidgetStatePropertyAll(Colors.transparent),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(999),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
