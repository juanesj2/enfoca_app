import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grupo.dart';

// Servicio para gestionar los grupos
class GrupoService with ChangeNotifier {
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

  void setBaseUrl(String url) {}

  Future<void> obtenerMisGrupos() async {
    final token = await _obtenerToken();
    if (token == null) {
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gruposJson = data['data'];

        _misGrupos = gruposJson.map((json) {
          try {
            return Grupo.fromJson(json);
          } catch (e) {
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
        throw Exception('Error al cargar grupos');
      }
    } catch (e) {
      rethrow;
    }
  }

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

      if (response.statusCode == 201 || response.statusCode == 200) {
        await obtenerMisGrupos();
      } else {
        throw Exception('Error al crear el grupo');
      }
    } catch (e) {
      rethrow;
    }
  }

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
        await obtenerMisGrupos();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error de servidor');
      }
    } catch (e) {
      rethrow;
    }
  }

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
        throw Exception(errorData['error'] ?? 'Error al salir');
      }
    } catch (e) {
      rethrow;
    }
  }

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
        throw Exception(errorData['error'] ?? 'Error al eliminar');
      }
    } catch (e) {
      rethrow;
    }
  }
}
