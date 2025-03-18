import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String THEME_KEY = 'theme_preference';
  static const String SYSTEM_THEME = 'system';
  static const String LIGHT_THEME = 'light';
  static const String DARK_THEME = 'dark';

  String _themePreference = SYSTEM_THEME;

  String get themePreference => _themePreference;

  ThemeMode get themeMode {
    switch (_themePreference) {
      case LIGHT_THEME:
        return ThemeMode.light;
      case DARK_THEME:
        return ThemeMode.dark;
      case SYSTEM_THEME:
      default:
        return ThemeMode.system;
    }
  }

  ThemeProvider() {
    _loadThemePreference();
  }

  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(THEME_KEY);
    if (savedTheme != null) {
      _themePreference = savedTheme;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(String theme) async {
    if (_themePreference != theme) {
      _themePreference = theme;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(THEME_KEY, theme);
    }
  }
}
