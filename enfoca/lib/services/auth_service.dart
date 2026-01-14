import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  // Configuración de la URL Base de la API
  // Si usas Windows/Web, usa 127.0.0.1 (o la URL real)
  // Si usas Emulador Android, usa 10.0.2.2
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // ********** Variables de Estado ********** //
  String? _token; // Token JWT para peticiones autenticadas
  User? _user; // Objeto de usuario actual
  // ********** FIN Variables de Estado ********** //

  // Getters para acceder al estado desde fuera
  bool get isAuth => _token != null;
  String? get token => _token;
  User? get user => _user;

  // ********** Metodos Publicos de Autenticacion ********** //

  // Iniciar sesion
  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'login');
  }

  // Registrar nuevo usuario
  Future<void> register(
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
        // Inmediatamente despues del registro, obtenemos y guardamos los datos del usuario
        await _fetchAndStoreUserData(_token!);
        notifyListeners(); // Notificamos a la UI que el estado ha cambiado
      } else {
        throw Exception(responseData['message'] ?? 'Error al registrarse');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Cerrar sesion
  Future<void> logout() async {
    _token = null;
    _user = null;
    // Limpiamos datos persistidos
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    notifyListeners();
  }
  // ********** FIN Metodos Publicos ********** //

  // ********** Metodos Privados y Auxiliares ********** //

  // Metodo generico para login (podria reutilizarse para otros tipos de auth)
  Future<void> _authenticate(
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
        // Obtenemos los datos del usuario para evitar llamadas innecesarias despues
        await _fetchAndStoreUserData(_token!);
        notifyListeners();
      } else {
        throw Exception(responseData['message'] ?? 'Error al iniciar sesión');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtiene los datos del usuario (/api/user) y los guarda localmente
  Future<void> _fetchAndStoreUserData(String token) async {
    final url = Uri.parse('$_baseUrl/user');
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

        // Guardamos todo en SharedPreferences para persistencia entre reinicios
        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': _token,
          'userId': _user!.id,
          'userName': _user!.name,
          'userEmail': _user!.email,
        });
        prefs.setString('userData', userData);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Si falla la carga de usuario, al menos guardamos el token para mantener sesion
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userData', json.encode({'token': _token}));
    }
  }

  // ********** FIN Metodos Privados ********** //
}
