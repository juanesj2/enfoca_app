import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Servicio para gestionar el tema de la aplicación
class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themePrefKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeService() {
    _loadFromPrefs();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePrefKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _isDarkMode);
  }
}
