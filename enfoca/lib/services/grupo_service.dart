import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grupo.dart';

class GrupoService with ChangeNotifier {
  // Ajustamos la URL a la que usa AuthService para evitar inconsistencias
  final String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  List<Grupo> _misGrupos = [];
  List<Grupo> get misGrupos => [..._misGrupos];

  String lastDebugInfo = 'Cargando...';

  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return null;
    final extractedUserData = json.decode(prefs.getString('userData')!);
    return extractedUserData['token'] as String?;
  }

  // Obtener la IP base de la API asumiendo la misma de otros servicios
  void setBaseUrl(String url) {
    // Método auxiliar por si necesitas inyectar la URL
  }

  // ============== OBTENER MIS GRUPOS ==============
  Future<void> obtenerMisGrupos() async {
    final token = await _obtenerToken();
    if (token == null) {
      lastDebugInfo = 'DEBUG: EL TOKEN DE SESIÓN ES NULL';
      print(lastDebugInfo);
      return;
    }

    final url = Uri.parse('$_baseUrl/grupos/mis-grupos');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      lastDebugInfo =
          'HTTP ${response.statusCode}\nBody: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}';
      print(lastDebugInfo);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gruposJson = data['data'];

        _misGrupos = gruposJson.map((json) {
          try {
            return Grupo.fromJson(json);
          } catch (e) {
            print('DEBUG GRUPO PARSE ERROR: $e');
            return Grupo(
              id: 0,
              nombre: 'Error',
              codigoInvitacion: '',
              creadoPor: 0,
              usuarios: [],
              createdAt: DateTime.now(),
            );
          }
        }).toList();

        notifyListeners();
      } else {
        print('DEBUG OBTENER MIS GRUPOS ERROR HTTP');
        throw Exception('Error al cargar mis grupos');
      }
    } catch (e) {
      print('DEBUG OBTENER MIS GRUPOS EXCEPTION: $e');
      rethrow;
    }
  }

  // ============== CREAR GRUPO ==============
  Future<void> crearGrupo(String nombre, String descripcion) async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/grupos');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'nombre': nombre, 'descripcion': descripcion}),
      );

      print('RESPONSE STATUS CREAR GRUPO: ${response.statusCode}');
      print('RESPONSE BODY CREAR GRUPO: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // En lugar de hacer una nueva petición ciega, parseamos
        // final data = json.decode(response.body); // podriamos comprobar errores web.
        await obtenerMisGrupos(); // Recargar la lista
      } else {
        throw Exception(
          'Error al crear el grupo: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('EXCEPCIÓN EN CREAR GRUPO: $e');
      rethrow;
    }
  }

  // ============== UNIRSE A GRUPO ==============
  Future<void> unirseGrupo(String codigo) async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/grupos/unirse');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'codigo_invitacion': codigo}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        await obtenerMisGrupos(); // Recargar tras unirse
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Código inválido o error del servidor',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============== SALIR DE GRUPO ==============
  Future<void> salirGrupo(int id) async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/grupos/$id/salir');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _misGrupos.removeWhere((g) => g.id == id);
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al salir del grupo');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============== BORRAR GRUPO (Solo Admin) ==============
  Future<void> borrarGrupo(int id) async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/grupos/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _misGrupos.removeWhere((g) => g.id == id);
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar el grupo');
      }
    } catch (e) {
      rethrow;
    }
  }
}
