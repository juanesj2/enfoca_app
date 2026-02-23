import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grupo.dart';

// ==========================================
// SERVICIO DE RED: GESTOR DE GRUPOS
// ==========================================
// Esta clase controla todas las comunicaciones mediante HTTP al servidor de Laravel
// que tengan que ver con la sala de Grupos Sociales. Hereda de ChangeNotifier
// para ser un "proveedor global" (Provider) en toda la aplicación.

class GrupoService with ChangeNotifier {
  // Ajustamos la URL a la que usa AuthService para evitar inconsistencias
  // Todos los "endpoints" (URLs de petición) colgarán de esta ruta raíz.
  final String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // ==========================================
  // ESTADO INTERNO DEL PROVIDER
  // ==========================================
  List<Grupo> _misGrupos =
      []; // Variable privada donde almacenamos los datos localmente
  List<Grupo> get misGrupos => [
    ..._misGrupos,
  ]; // Getter público y seguro (devuelve copia)

  // Variable de depuración para rastrear fallos en red si el servidor colapsa
  String lastDebugInfo = 'Cargando...';

  // ==========================================
  // GESTIÓN DE SEGURIDAD (TOKEN JWT)
  // ==========================================
  // Función asíncrona dedicada a sacar el token de la bóveda del móvil.
  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return null;

    // El objeto está serializado como texto en preferencias, lo parseamos
    final extractedUserData = json.decode(prefs.getString('userData')!);
    return extractedUserData['token'] as String?;
  }

  // Obtener la IP base de la API asumiendo la misma de otros servicios
  void setBaseUrl(String url) {
    // Método auxiliar por si se necesitase inyectar una URL de testing en un futuro
  }

  // ==========================================
  // OBTENER MIS GRUPOS (MÉTODO HTTP GET)
  // ==========================================
  // Pide al servidor la lista de grupos a los que pertenece el usuario actualmente logueado.
  Future<void> obtenerMisGrupos() async {
    final token = await _obtenerToken();
    if (token == null) {
      lastDebugInfo = 'DEBUG: EL TOKEN DE SESIÓN ES NULL';
      print(lastDebugInfo);
      return; // Abortamos la misión si no hay token (No estamos logueados)
    }

    final url = Uri.parse('$_baseUrl/grupos/mis-grupos');

    try {
      // Hacemos una llamada GET (modo solo lectura)
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Autenticación vital
          'Accept': 'application/json',
        },
      );

      lastDebugInfo =
          'HTTP ${response.statusCode}\nBody: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}';
      print(lastDebugInfo);

      // Si Laravel responde "200 OK", todo ha salido sobre ruedas.
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gruposJson = data['data'];

        // Repasamos el JSON y empaquetamos cada Grupo en nuestro Modelo Dart
        _misGrupos = gruposJson.map((json) {
          try {
            return Grupo.fromJson(json);
          } catch (e) {
            print('DEBUG GRUPO PARSE ERROR: $e');
            // Programación defensiva: Si falla 1 solo grupo en medio del bucle,
            // no hacemos crashear toda la app, sino que metemos un grupo "Error" falso.
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

        // Gritamos a los 4 vientos que el catálogo se refrescó.
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

  // ==========================================
  // CREAR GRUPO (MÉTODO HTTP POST)
  // ==========================================
  // Solicita la creación de un nuevo recurso en el Backend.
  Future<void> crearGrupo(String nombre, String descripcion) async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/grupos');

    try {
      // POST sirve para inyectar o envar información nueva.
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type':
              'application/json', // Prometemos mandar un JSON en el cuerpo del mensaje
        },
        // json.encode traduce nuestro mapa en un chorizo de texto puro
        body: json.encode({'nombre': nombre, 'descripcion': descripcion}),
      );

      print('RESPONSE STATUS CREAR GRUPO: ${response.statusCode}');
      print('RESPONSE BODY CREAR GRUPO: ${response.body}');

      // Si la BD guardó bien o se preparó (CÓDIGOS 200/201 Success)
      if (response.statusCode == 201 || response.statusCode == 200) {
        // En vez de parsear la respuesta estática, simplemente hacemos que el servidor
        // nos reenvíe la lista completa fresquita y actualizada.
        await obtenerMisGrupos();
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

  // ==========================================
  // UNIRSE A GRUPO (MÉTODO HTTP POST)
  // ==========================================
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
        await obtenerMisGrupos(); // Recargar el estado en la app si entramos con éxito
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

  // ==========================================
  // SALIR DE GRUPO (MÉTODO HTTP DELETE)
  // ==========================================
  Future<void> salirGrupo(int id) async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/grupos/$id/salir');

    try {
      // DELETE le dice expresamente al backend que intente destruir un recurso
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // En vez de recargar todo de la web (gasto de internet inútil),
        // borramos localmente el registro con removeWhere usando "Programación Optimista".
        _misGrupos.removeWhere((g) => g.id == id);
        notifyListeners(); // La interfaz borra visualmente el bloque casi en tiempo real.
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al salir del grupo');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // BORRAR GRUPO (MÉTODO HTTP DELETE - Solo Administrador)
  // ==========================================
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
        notifyListeners(); // Actualización optimista de memoria RAM
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar el grupo');
      }
    } catch (e) {
      rethrow;
    }
  }
}
