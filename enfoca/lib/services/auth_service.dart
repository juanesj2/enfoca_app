import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

// ==========================================
// SERVICIO DE AUTENTICACIÓN Y SEGURIDAD (AUTH)
// ==========================================
// Este Provider es el corazón de la aplicación. Mantiene en todo momento
// la respuesta a la pregunta: "¿Quién soy y estoy logueado?".
// Maneja peticiones de Login, Registro, y provee funciones de Administrador.

class AuthService with ChangeNotifier {
  // ==========================================
  // ENRUTAMIENTO BASE
  // ==========================================
  // Ubicación de nuestro servidor backend en Internet.
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // ==========================================
  // ESTADO INTERNO DEL SISTEMA (STATE)
  // ==========================================
  // Guión bajo '_' indica que son variables estrictamente privadas.
  // Solo la propia clase AuthService puede escribir en ellas.
  String? _token; // El "Pase VIP" cifrado que nos da Laravel (JWT)
  User?
  _user; // Toda la información pública del usuario (Nombre, Email, Foto...)

  // ==========================================
  // EXPOSICIÓN CONTROLADA DE DATOS (GETTERS)
  // ==========================================

  // Un "booleano calculado" que devuelve Verdadero si tenemos una llave en el bolsillo.
  // Se usa para decidir rápidamente si enseñar la pantalla Login o el Home.
  bool get estaAutenticado => _token != null;

  // Devolvemos versiones de solo lectura del token y usuario
  String? get token => _token;
  User? get usuario => _user;

  // ==========================================
  // MÉTODOS PÚBLICOS DE AUTENTICACIÓN
  // ==========================================

  // Iniciar sesión (Llamamos a una función genérica privada para ahorrar código)
  Future<void> iniciarSesion(String email, String password) async {
    return _autenticar(email, password, 'login');
  }

  // Registrar un nuevo integrante humano en la base de datos
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
          'Accept':
              'application/json', // Laravel, por favor escupe errores en JSON, no en HTML puro.
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
        // Guardamos el token que Laravel nos ha regalado de por vida (o hasta que expire)
        _token = responseData['access_token'];

        // Magia: Con la llave en mano, forzamos una segunda petición automática
        // para descargar mi perfil completo antes de dibujar la Home.
        await _obtenerYGuardarDatosUsuario(_token!);

        // ¡Grito global! Se acaba de registrar alguien, todas las pantallas deben despertar.
        notifyListeners();
      } else {
        throw Exception(
          responseData['message'] ?? 'Error al registrarse en el Backend',
        );
      }
    } catch (error) {
      rethrow;
    }
  }

  // Cerrar Sesión (Destrucción manual de credenciales)
  Future<void> cerrarSesion() async {
    // 1. Matamos los datos en la Memoria RAM Volátil (Dart)
    _token = null;
    _user = null;

    // 2. Matamos los datos en la Memoria ROM Persistente (Disco Duro Móvil)
    // Para que si apagan el móvil y lo encienden, no recuerde el inicio de sesión.
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');

    // 3. Avisamos al MaterialApp. Al notar que ya no hay token,
    // su IF-Ternario interno nos echará a patadas hacia la pantalla de Login automáticamente.
    notifyListeners();
  }

  // ==========================================
  // MÉTODOS DE ADMINISTRADOR (Modo Dios)
  // ==========================================
  // Nota: Todas estas rutas están protegidas en Laravel. Si un usuario con Rol='user'
  // llama a esto, Laravel devolverá error 403 Forbidden.

  // Obtener todos los usuarios del sistema (Para volcarlo en el DataTable)
  Future<List<User>> obtenerUsuarios() async {
    final url = Uri.parse('$_baseUrl/admin/usuarios');
    final token = await _obtenerToken();

    // Redundancia de seguridad frontend
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

        // Transformar diccionario JSON a molde de clase Dart 'User'
        return usersList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Error catastrófico al solicitar la lista de usuarios');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Permite escalar privilegios (Hacer a alguien Admin) o castigarlo (Veto Temporal/Permanente)
  Future<void> editarUsuario(
    int id,
    String rol,
    bool vetado, {
    String? fechaVeto, // Opcional, si es nulo => Veto infinito
  }) async {
    // Endpoint RESTFUL clásico: /admin/usuarios/[id] con verbo PUT/PATCH
    final url = Uri.parse('$_baseUrl/admin/usuarios/$id');
    final token = await _obtenerToken();

    if (token == null) throw Exception('No autenticado');

    try {
      // Método HTTP PUT para modificación directa y pesada de recursos
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

      // Programación Defensiva: Solo consideramos éxito rotundo al 200 OK
      if (response.statusCode != 200) {
        throw Exception('El servidor rechazó la actualización del usuario');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Eliminar a un usuario por completo (Soft Delete o Hard Delete según como esté hecho Laravel)
  Future<void> eliminarUsuario(int id) async {
    final url = Uri.parse('$_baseUrl/admin/usuarios/$id');
    final token = await _obtenerToken();

    if (token == null) throw Exception('No autenticado');

    try {
      // Usamos el verbo destructor nativo HTTP DELETE
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // 200 OK o 204 No Content (Ambos son éxitos para un barrido)
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Fallo crítico al aniquilar los registros del usuario');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // CARPINTERÍA Y FUNCIONES AUXILIARES PRIVADAS
  // ==========================================

  // Conector central de inicio de sesión que le inyecta la contraseña al endpoint deseado
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
        // Descargar ficha centralizada
        await _obtenerYGuardarDatosUsuario(_token!);
        notifyListeners(); // Todo ha ido bien, pasamos a la pantalla siguiente
      } else {
        // Capturar mensaje del backend (Ej: "Las contraseñas no coinciden") y propagarlo a un PopUp
        throw Exception(
          responseData['message'] ??
              'Fallo de credenciales en el inicio de sesión',
        );
      }
    } catch (error) {
      rethrow;
    }
  }

  // Después del login, Laravel solo nos da "La llave".
  // Pero necesitamos saber quién somos (Nombre para pintar en la interfaz, Rol para las pantallas ocultas Admin).
  // Esta función pide el DNI al backend y lo cachea en el disco duro.
  Future<void> _obtenerYGuardarDatosUsuario(String token) async {
    final url = Uri.parse(
      '$_baseUrl/usuario',
    ); // Ruta estándar OAuth/Sanctum de Laravel
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Abro la puerta
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userJson = data['data'];

        // Empaquetamos la respuesta de internet en un Objeto fuerte e inmutable de Dart
        _user = User.fromJson(userJson);

        // PERSISTENCIA (SharedPreferences)
        // Convertimos un Mini-Resumen del jugador a Texto Plano y lo metemos
        // a presión física dentro del Hardware del dispositivo. Así si la app se mata, sobrevive.
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
      print('Error profundo intentando recuperar ficha de info personal: $e');

      // Fallback: Si no podemos cargar la info, pero sí tenemos Token, guardamos el Token
      // para que el usuario al menos pase del panel de Control y no se quede atascado en Login.
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userData', json.encode({'token': _token}));
    }
  }

  // Intermediario inteligente:
  // Si tenemos el token en RAM (app encendida), nos lo da al instante (caché rápida).
  // Si no está en RAM (ej: La app se acaba de ejecutar fría), lo lee del disco duro.
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
