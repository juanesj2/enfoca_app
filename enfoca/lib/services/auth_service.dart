import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

// Servicio de autenticación
class AuthService with ChangeNotifier {
  // URL base de la API
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // Variables privadas para el token y el usuario
  String? _token;
  User? _user;

  // Getters para saber si estamos autenticados y obtener datos
  bool get estaAutenticado => _token != null;
  String? get token => _token;
  User? get usuario => _user;

  // Iniciar sesión
  Future<void> iniciarSesion(String email, String password) async {
    return _autenticar(email, password, 'login');
  }

  // Registro de nuevo usuario
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
        // Después de registrarse, pedimos los datos del usuario
        await _obtenerYGuardarDatosUsuario(_token!);
        notifyListeners();
      } else {
        throw Exception(responseData['message'] ?? 'Error al registrarse');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Cerrar sesión y borrar datos guardados
  Future<void> cerrarSesion() async {
    _token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');

    notifyListeners();
  }

  // MÉTODOS DE ADMIN

  // Obtener lista de todos los usuarios (solo para admins)
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

  // Editar datos de un usuario (rol, veto)
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

  // MÉTODOS PRIVADOS

  // Función genérica para autenticar (login)
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
        await _obtenerYGuardarDatosUsuario(_token!);
        notifyListeners();
      } else {
        throw Exception(responseData['message'] ?? 'Error de autenticación');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtiene los datos del perfil y los guarda en SharedPreferences
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
        final userJson = data['data'];

        _user = User.fromJson(userJson);

        // Guardamos los datos para que persistan si se cierra la app
        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': _token,
          'userId': _user!.id,
          'userName': _user!.name,
          'userEmail': _user!.email,
          'userRol': _user!.rol,
        });
        prefs.setString('userData', userData);
      }
    } catch (e) {
      print('Error al guardar datos de usuario: $e');

      // Si falla, al menos guardamos el token
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userData', json.encode({'token': _token}));
    }
  }

  // Recupera el token de RAM o de disco
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
