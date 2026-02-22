import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// SERVICIO DE TEMA (THEME SERVICE)
// ==========================================
// Esta clase extiende ChangeNotifier para permitir que los widgets de la
// aplicación escuchen los cambios de tema y se reconstruyan reactivamente.
class ThemeService extends ChangeNotifier {
  // Variable privada que almacena el estado actual del tema (Claro u Oscuro)
  bool _isDarkMode = false;

  // Clave estática utilizada para guardar y leer la preferencia en el almacenamiento local del dispositivo
  static const String _themePrefKey = 'isDarkMode';

  // Getter público para consultar si el modo oscuro está activado
  bool get isDarkMode => _isDarkMode;

  // Getter que devuelve el ThemeMode de Flutter correspondiente al estado actual.
  // Será ThemeMode.dark si es true, o ThemeMode.light si es false.
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Constructor del servicio. Al instanciarse, inmediatamente carga
  // la preferencia guardada anteriormente en el dispositivo.
  ThemeService() {
    _loadFromPrefs();
  }

  // ==========================================
  // CONMUTADOR DE TEMA
  // ==========================================
  // Cambia el estado del tema de Claro a Oscuro o viceversa.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode; // Invierte el valor booleano
    _saveToPrefs(); // Guarda permanentemente en el disco del teléfono
    notifyListeners(); // Avisa a toda la app para que aplique los nuevos colores
  }

  // ==========================================
  // CARGA Y GUARDADO EN MEMORIA (SHARED PREFERENCES)
  // ==========================================

  // Lee el estado guardado en el dispositivo.
  // Si no hay ninguno guardado (primera vez), establece el modo claro por defecto (false).
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePrefKey) ?? false;
    notifyListeners(); // Notifica a la UI tras cargar el estado real del disco
  }

  // Guarda la preferencia de tema actual en la memoria del dispositivo.
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _isDarkMode);
  }
}
