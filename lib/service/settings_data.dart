import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences that outlive a session.
///
/// Currently only the theme choice. Kept separate from TipData because it has
/// nothing to do with the bill and must load before the first frame paints, so
/// the app does not flash the wrong brightness.
class SettingsData with ChangeNotifier {
  static const String _themeKey = "theme_mode";

  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  SettingsData() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _loaded;

  static ThemeMode _decode(final String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(final ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = _decode(prefs.getString(_themeKey));
    } catch (error) {
      debugPrint('Could not read settings, using defaults: $error');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(final ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _encode(mode));
    } catch (error) {
      // The choice still applies for this session; only persistence failed.
      debugPrint('Could not persist theme choice: $error');
    }
  }
}
