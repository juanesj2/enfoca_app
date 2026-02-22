import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

// ==========================================
// SERVICIO DE AUTENTICACIÓN
// ==========================================

class AuthService with ChangeNotifier {
  // Configuración de la URL Base de la API
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // ==========================================
  // ESTADO (STATE)
  // ==========================================

  String? _token; // Token JWT para peticiones autenticadas
  User? _user; // Objeto de usuario actual

  // ==========================================
  // GETTERS
  // ==========================================

  // Verifica si hay un usuario autenticado (si tenemos token)
  bool get estaAutenticado => _token != null;

  // Obtiene el token actual
  String? get token => _token;

  // Obtiene el usuario actual
  User? get usuario => _user;

  // ==========================================
  // MÉTODOS PÚBLICOS DE AUTENTICACIÓN
  // ==========================================

  // Iniciar sesión con email y contraseña
  Future<void> iniciarSesion(String email, String password) async {
    return _autenticar(email, password, 'login');
  }

  // Registrar nuevo usuario
  Future<void> registrarse(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _token = responseData['access_token'];
        // Inmediatamente después del registro, obtenemos y guardamos los datos del usuario
        await _obtenerYGuardarDatosUsuario(_token!);
        notifyListeners(); // Notificamos a la UI que el estado ha cambiado
      } else {
        throw Exception(responseData['message'] ?? 'Error al registrarse');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    _token = null;
    _user = null;
    // Limpiamos datos persistidos en el dispositivo
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    notifyListeners();
  }

  // ==========================================
  // GESTIÓN DE USUARIOS (ADMIN)
  // ==========================================

  // Obtener todos los usuarios
  Future<List<User>> obtenerUsuarios() async {
    final url = Uri.parse('$_baseUrl/admin/usuarios');
    final token = await _obtenerToken();

    if (token == null) throw Exception('No autenticado');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> usersList = data['data'];
        return usersList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Editar usuario (Rol y Veto y Fecha Veto)
  Future<void> editarUsuario(
    int id,
    String rol,
    bool vetado, {
    String? fechaVeto,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/usuarios/$id');
    final token = await _obtenerToken();

    if (token == null) throw Exception('No autenticado');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'rol': rol,
          'vetado': vetado,
          'fecha_veto': fechaVeto,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar usuario');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Eliminar usuario
  Future<void> eliminarUsuario(int id) async {
    final url = Uri.parse('$_baseUrl/admin/usuarios/$id');
    final token = await _obtenerToken();

    if (token == null) throw Exception('No autenticado');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar usuario');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // MÉTODOS PRIVADOS Y AUXILIARES
  // ==========================================

  // Método genérico para login (podría reutilizarse para otros tipos de auth)
  Future<void> _autenticar(
    String email,
    String password,
    String urlSegment,
  ) async {
    final url = Uri.parse('$_baseUrl/$urlSegment');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = responseData['access_token'];
        // Obtenemos los datos del usuario para evitar llamadas innecesarias después
        await _obtenerYGuardarDatosUsuario(_token!);
        notifyListeners();
      } else {
        throw Exception(responseData['message'] ?? 'Error al iniciar sesión');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtiene los datos del usuario (/api/user) y los guarda localmente
  Future<void> _obtenerYGuardarDatosUsuario(String token) async {
    final url = Uri.parse('$_baseUrl/usuario');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userJson = data['data']; // La API devuelve { data: { ... } }
        _user = User.fromJson(userJson);

        // Guardamos todo en SharedPreferences para persistencia entre reinicios de la app
        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': _token,
          'userId': _user!.id,
          'userName': _user!.name,
          'userEmail': _user!.email,
          'userRol': _user!.rol, // Guardamos el rol también
        });
        prefs.setString('userData', userData);
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      // Si falla la carga de usuario, al menos guardamos el token para mantener sesión
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userData', json.encode({'token': _token}));
    }
  }

  // Helper para obtener el token (necesario para las peticiones de admin)
  Future<String?> _obtenerToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return null;
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    _token = extractedUserData['token'];
    return _token;
  }
}
