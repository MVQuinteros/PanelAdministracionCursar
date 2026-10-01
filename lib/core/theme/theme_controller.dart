import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia de tema, persistida (el original usaba `localStorage`).
class ThemeModeController extends Notifier<ThemeMode> {
  ThemeModeController([this._initial = ThemeMode.light]);

  final ThemeMode _initial;

  /// Clave de almacenamiento; la misma que usaba `js/views/layout.js`.
  static const storageKey = 'cursar-theme';

  @override
  ThemeMode build() => _initial;

  Future<void> toggle() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        state == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {
      // Sin persistencia: el tema igual queda seteado en memoria.
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Lee la preferencia antes de arrancar, para no parpadear al primer render.
Future<ThemeMode> loadInitialTheme() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ThemeModeController.storageKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  } catch (_) {
    return ThemeMode.light;
  }
}
