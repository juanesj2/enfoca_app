import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fotografia.dart';
import '../models/user.dart';

// ==========================================
// SERVICIO DE FOTOGRAFÍAS
// ==========================================

class PhotoService with ChangeNotifier {
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // ==========================================
  // ESTADO (STATE)
  // ==========================================

  List<Fotografia> _items = []; // Todas las fotos (Feed)
  List<Fotografia> _misItems = []; // Fotos del usuario autenticado
  List<Fotografia> _itemsUsuarioBuscado =
      []; // Fotos de un usuario específico buscado

  // ==========================================
  // GETTERS
  // ==========================================

  // Acceso a la lista principal de fotos
  List<Fotografia> get items {
    return [..._items];
  }

  // Acceso a las fotos del usuario actual
  List<Fotografia> get misItems {
    return [..._misItems];
  }

  // Acceso a las fotos del usuario buscado
  List<Fotografia> get itemsUsuarioBuscado {
    return [..._itemsUsuarioBuscado];
  }

  // ==========================================
  // MÉTODOS DE BÚSQUEDA LOCAL
  // ==========================================

  // Busca una foto por ID en TODAS las listas locales disponibles
  Fotografia? obtenerFotoPorId(int id) {
    // 1. Buscar en Items generales (Feed)
    try {
      return _items.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // No encontrada en _items
    }

    // 2. Buscar en Mis Fotos
    try {
      return _misItems.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // No encontrada en _misItems
    }

    // 3. Buscar en Fotos de Usuario Buscado
    try {
      return _itemsUsuarioBuscado.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // No encontrada en _itemsUsuarioBuscado
    }

    return null;
  }

  // ==========================================
  // MÉTODOS DE API: LECTURA
  // ==========================================

  // Carga todas las fotos (Feed principal)
  Future<void> obtenerFotos() async {
    final url = Uri.parse('$_baseUrl/fotografias');
    final token = await _obtenerToken();

    if (token == null) {
      throw Exception('No hay token, usuario no autenticado');
    }

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
        // La API devuelve un objeto con "data": [...]
        final List<dynamic> photosList = data['data'];

        _items = photosList.map((json) => Fotografia.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar fotos');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtiene únicamente las fotos subidas por el usuario logueado
  Future<void> obtenerMisFotos() async {
    final url = Uri.parse('$_baseUrl/mis-fotos');
    final token = await _obtenerToken();

    if (token == null) {
      throw Exception('No hay token, usuario no autenticado');
    }

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
        final List<dynamic> photosList = data['data'];

        final userName = await _obtenerNombreUsuario() ?? 'Usuario';

        _misItems = photosList.map((json) {
          final foto = Fotografia.fromJson(json);
          // Si la foto viene con nombre genérico "Usuario", asignamos el nombre real
          if (foto.userName == 'Usuario') {
            return foto.copyWith(userName: userName);
          }
          return foto;
        }).toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar mis fotos');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtiene las fotos de un usuario específico por su ID
  Future<void> obtenerFotosUsuario(int userId, {String? forcedUserName}) async {
    final url = Uri.parse('$_baseUrl/fotografias-usuario/$userId');
    final token = await _obtenerToken();

    if (token == null) {
      throw Exception('No hay token, usuario no autenticado');
    }

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
        final List<dynamic> photosList = data['data'];

        _itemsUsuarioBuscado = photosList.map((json) {
          final foto = Fotografia.fromJson(json);
          if (forcedUserName != null && foto.userName == 'Usuario') {
            return foto.copyWith(userName: forcedUserName);
          }
          return foto;
        }).toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar fotos del usuario');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtiene una foto especifica directamente desde la API usando su ID
  Future<Fotografia?> obtenerFotoPorIdApi(int fotoId) async {
    final url = Uri.parse('$_baseUrl/fotografias/$fotoId');
    final token = await _obtenerToken();

    // Podemos intentar buscarla publicamente si no hay token,
    // pero idealmente enviamos el token si existe.
    final headers = {'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Fotografia.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Busca un usuario por nombre
  Future<User?> buscarUsuarioPorNombre(String name) async {
    final url = Uri.parse('$_baseUrl/usuarios/buscar?query=$name');
    final token = await _obtenerToken();

    if (token == null) {
      throw Exception('No hay token, usuario no autenticado');
    }

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
        final List<dynamic> usersData = data['data'];

        if (usersData.isNotEmpty) {
          // Devolvemos el primer usuario encontrado
          return User.fromJson(usersData[0]);
        }
        return null; // No se encontró usuario
      } else {
        throw Exception('Error al buscar usuario');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Búsqueda avanzada de fotos (por usuario, texto, iso, etc)
  Future<void> buscarFotosAvanzado(String tipoBusqueda, String query) async {
    // tipoBusqueda puede ser: 'usuario', 'texto', 'iso', 'fecha'
    final url = Uri.parse('$_baseUrl/fotografias/buscar?$tipoBusqueda=$query');
    final token = await _obtenerToken();

    if (token == null) throw Exception('No hay token');

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
        final List<dynamic> photosList = data['data'];

        _itemsUsuarioBuscado = photosList
            .map((json) => Fotografia.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Error en búsqueda avanzada');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // MÉTODOS DE API: CREACIÓN (POST)
  // ==========================================

  // Sube una nueva fotografía
  Future<void> crearFoto(
    File image,
    String titulo,
    String descripcion, {
    double? latitud,
    double? longitud,
    int? iso,
    String? velocidadObturacion,
    double? apertura,
  }) async {
    final url = Uri.parse('$_baseUrl/fotografias');
    final token = await _obtenerToken();

    if (token == null) {
      throw Exception('No se encontró token de autenticación');
    }

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      ..fields['titulo'] = titulo
      ..fields['descripcion'] = descripcion;

    // Campos opcionales (Metadatos y ubicación)
    if (latitud != null) request.fields['latitud'] = latitud.toString();
    if (longitud != null) request.fields['longitud'] = longitud.toString();
    if (iso != null) request.fields['ISO'] = iso.toString();
    if (velocidadObturacion != null) {
      request.fields['velocidad_obturacion'] = velocidadObturacion;
    }
    if (apertura != null) request.fields['apertura'] = apertura.toString();

    // Archivo de imagen
    request.files.add(
      await http.MultipartFile.fromPath(
        'direccion_imagen', // Nombre del campo esperado por el backend
        image.path,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Éxito: Recargamos las fotos para mostrar la nueva
        await obtenerFotos();
      } else {
        print('Error al crear foto: ${response.body}');

        // Intentamos decodificar el mensaje de error
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final body = json.decode(response.body);
          if (body['message'] != null) {
            errorMsg += ': ${body['message']}';
          } else {
            errorMsg += ': ${response.body}';
          }
        } catch (_) {
          errorMsg += ': ${response.body}';
        }
        throw Exception(errorMsg);
      }
    } catch (error) {
      print('Excepción al crear foto: $error');
      rethrow;
    }
  }

  // ==========================================
  // MÉTODOS DE API: INTERACCIÓN (LIKES)
  // ==========================================

  // Alterna el like de una foto (dar/quitar like)
  Future<void> alternarLike(int id) async {
    // Helper para actualizar una lista local específica (Optimistic UI Update)
    void actualizarLista(List<Fotografia> lista) {
      final index = lista.indexWhere((item) => item.id == id);
      if (index >= 0) {
        final oldPhoto = lista[index];
        final isLiked = oldPhoto.likedByUser;
        final newCount = isLiked
            ? (oldPhoto.likesCount > 0 ? oldPhoto.likesCount - 1 : 0)
            : oldPhoto.likesCount + 1;

        lista[index] = oldPhoto.copyWith(
          likedByUser: !isLiked,
          likesCount: newCount,
        );
      }
    }

    // Buscamos el estado original para enviarlo al servidor
    bool isLikedOriginal = false;
    var index = _items.indexWhere((item) => item.id == id);

    if (index >= 0) {
      isLikedOriginal = _items[index].likedByUser;
    } else {
      index = _misItems.indexWhere((item) => item.id == id);
      if (index >= 0) {
        isLikedOriginal = _misItems[index].likedByUser;
      } else {
        index = _itemsUsuarioBuscado.indexWhere((item) => item.id == id);
        if (index >= 0) {
          isLikedOriginal = _itemsUsuarioBuscado[index].likedByUser;
        } else {
          return; // No se encontró la foto
        }
      }
    }

    // Actualizamos optimísticamente TODAS las listas
    actualizarLista(_items);
    actualizarLista(_misItems);
    actualizarLista(_itemsUsuarioBuscado);

    notifyListeners();

    final url = Uri.parse('$_baseUrl/fotografias/$id/like');
    final token = await _obtenerToken();

    // Enviamos petición al servidor
    try {
      final response = isLikedOriginal
          ? await http.delete(
              // Si ya tenía like, lo quitamos (DELETE)
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
          : await http.post(
              // Si no tenía like, lo damos (POST)
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );

      if (response.statusCode >= 400) {
        // Rollback: Revertir cambios si falla la petición
        actualizarLista(_items);
        actualizarLista(_misItems);
        actualizarLista(_itemsUsuarioBuscado);
        notifyListeners();
        print('Error al dar like: ${response.statusCode}');
      }
    } catch (error) {
      // Rollback por excepción
      actualizarLista(_items);
      actualizarLista(_misItems);
      actualizarLista(_itemsUsuarioBuscado);
      notifyListeners();
      rethrow;
    }
  }

  // ==========================================
  // GESTIÓN LOCAL DE COMENTARIOS
  // ==========================================

  // Se usan para actualizar los contadores en las listas tras añadir/borrar comentarios en detalle

  void notificarComentarioAnadido(int photoId) {
    void actualizar(List<Fotografia> lista) {
      final index = lista.indexWhere((item) => item.id == photoId);
      if (index >= 0) {
        final oldPhoto = lista[index];
        lista[index] = oldPhoto.copyWith(
          comentariosCount: oldPhoto.comentariosCount + 1,
          comentadoPorUsuario: true,
        );
      }
    }

    actualizar(_items);
    actualizar(_misItems);
    actualizar(_itemsUsuarioBuscado);
    notifyListeners();
  }

  void notificarComentarioEliminado(int photoId, bool stillHasComments) {
    void actualizar(List<Fotografia> lista) {
      final index = lista.indexWhere((item) => item.id == photoId);
      if (index >= 0) {
        final oldPhoto = lista[index];
        lista[index] = oldPhoto.copyWith(
          comentariosCount: oldPhoto.comentariosCount > 0
              ? oldPhoto.comentariosCount - 1
              : 0,
          comentadoPorUsuario: stillHasComments,
        );
      }
    }

    actualizar(_items);
    actualizar(_misItems);
    actualizar(_itemsUsuarioBuscado);
    notifyListeners();
  }

  // ==========================================
  // GESTIÓN DE FOTOGRAFÍAS (ADMIN)
  // ==========================================

  // Obtener TODAS las fotos (incluidas vetadas) para admin
  Future<void> obtenerFotosAdmin() async {
    final url = Uri.parse('$_baseUrl/admin/fotografias');
    final token = await _obtenerToken();

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
        final List<dynamic> photosList = data['data'];
        _items = photosList.map((json) => Fotografia.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar fotos de admin');
      }
    } catch (error) {
      // Fallback
      print(error);
      rethrow;
    }
  }

  // Eliminar fotografía (Admin)
  Future<void> eliminarFoto(int id) async {
    final url = Uri.parse('$_baseUrl/fotografias/$id');
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        _items.removeWhere((item) => item.id == id);
        _misItems.removeWhere((item) => item.id == id);
        notifyListeners();
      } else {
        throw Exception('Error al eliminar fotografía');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Editar fotografía (Título, descripción y veto)
  Future<void> editarFoto(
    int id,
    String titulo,
    String descripcion,
    bool vetada,
  ) async {
    final url = Uri.parse('$_baseUrl/fotografias/$id');
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
          'titulo': titulo,
          'descripcion': descripcion,
          'vetada': vetada,
        }),
      );

      if (response.statusCode == 200) {
        await obtenerFotos(); // Recargar lista para ver cambios
      } else {
        throw Exception('Error al editar fotografía');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // GESTIÓN DE REPORTES (ADMIN)
  // ==========================================

  // Enviar reporte de fotografía
  Future<void> reportarFoto(int fotoId, String motivo) async {
    final url = Uri.parse('$_baseUrl/reportes');
    final token = await _obtenerToken();

    if (token == null) throw Exception('No autenticado');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'foto_id': fotoId, 'motivo': motivo}),
      );

      if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw errorData['error'] ??
            'Ya has reportado esta fotografía previamente.';
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw 'Error al procesar la solicitud.';
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtener reportes
  Future<List<dynamic>> obtenerReportes() async {
    final url = Uri.parse('$_baseUrl/admin/reportes'); // Endpoint correcto
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
        return data['data']; // Asumiendo que devuelve lista de reportes
      } else {
        // Si el endpoint no existe aún, simulamos datos vacíos para no romper la UI
        // throw Exception('Error al obtener reportes');
        return [];
      }
    } catch (error) {
      return []; // Fallback seguro
    }
  }

  // Eliminar reportes de una foto (indultar)
  Future<void> eliminarReportes(int fotoId) async {
    final url = Uri.parse('$_baseUrl/admin/reportes/$fotoId');
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

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar reportes');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ==========================================

  // Obtiene el token guardado en SharedPreferences
  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['token'];
  }

  // Obtiene el nombre de usuario guardado
  Future<String?> _obtenerNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['userName'];
  }
}
