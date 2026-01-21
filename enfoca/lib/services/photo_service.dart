import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fotografia.dart';

class PhotoService with ChangeNotifier {
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  List<Fotografia> _items = [];
  List<Fotografia> _misItems =
      []; // Lista para almacenar las fotos del usuario autenticado
  List<Fotografia> _searchedUserItems =
      []; // Lista para almacenar las fotos de un usuario buscado

  List<Fotografia> get items {
    return [..._items];
  }

  // Getter para acceder a las fotos del usuario
  List<Fotografia> get misItems {
    return [..._misItems];
  }

  // Getter para acceder a las fotos del usuario buscado
  List<Fotografia> get searchedUserItems {
    return [..._searchedUserItems];
  }

  // ********** Metodos Auxiliares ********** //

  // Método auxiliar para obtener el token guardado en SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['token'];
  }
  // ********** FIN Metodos Auxiliares ********** //

  // ********** API: Carga de Fotos ********** //
  Future<void> fetchPhotos() async {
    final url = Uri.parse('$_baseUrl/fotografias');
    final token = await _getToken();

    if (token == null) {
      throw Exception('No hay token, usuario no autenticado');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Aquí es donde usamos el token
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
  // ********** FIN API: Carga de Fotos ********** //

  // ********** API: Carga de Mis Fotos ********** //
  // Obtiene únicamente las fotos subidas por el usuario logueado
  Future<void> fetchMisFotos() async {
    final url = Uri.parse('$_baseUrl/mis-fotos');
    final token = await _getToken();

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
        // La estructura es: { data: [...] }
        final List<dynamic> photosList = data['data'];

        _misItems = photosList
            .map((json) => Fotografia.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar mis fotos');
      }
    } catch (error) {
      rethrow;
    }
  }
  // ********** FIN API: Carga de Mis Fotos ********** //

  // ********** API: Carga de Fotos de Usuario Buscado ********** //
  Future<void> fetchUserPhotos(int userId) async {
    final url = Uri.parse('$_baseUrl/fotografias-usuario/$userId');
    final token = await _getToken();

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

        _searchedUserItems = photosList
            .map((json) => Fotografia.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar fotos del usuario');
      }
    } catch (error) {
      rethrow;
    }
  }
  // ********** FIN API: Carga de Fotos de Usuario Buscado ********** //

  // ********** API: Busqueda de Usuario por Nombre ********** //
  Future<int?> searchUserIdByName(String name) async {
    final url = Uri.parse('$_baseUrl/users/search?query=$name');
    final token = await _getToken();

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
        final List<dynamic> users =
            data['data']; // Resource collection wraps in data

        if (users.isNotEmpty) {
          // Devolvemos el ID del primer usuario encontrado
          return users[0]['id'];
        }
        return null;
      } else {
        throw Exception('Error al buscar usuario');
      }
    } catch (error) {
      rethrow;
    }
  }
  // ********** FIN API: Busqueda de Usuario por Nombre ********** //

  // ********** API: Likes ********** //
  // Funcion para alternar los likes
  Future<void> toggleLike(int id) async {
    // usamos una funcion asincrona para no colgar la app
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final oldPhoto = _items[index];
    // Comprobamos si le hemos dado like a la foto
    final isLiked = oldPhoto.likedByUser;
    // Evitamos likes negativos actualizando localmente (Optimistic UI)
    final newCount = isLiked
        ? (oldPhoto.likesCount > 0 ? oldPhoto.likesCount - 1 : 0)
        : oldPhoto.likesCount + 1;

    _items[index] = oldPhoto.copyWith(
      likedByUser: !isLiked,
      likesCount: newCount,
    );
    notifyListeners();

    final url = Uri.parse('$_baseUrl/fotografias/$id/like');
    final token = await _getToken();

    // Enviamos las peticiones al servidor
    try {
      // Comprobamos si le hemos dado like
      final response = isLiked
          // Si la foto tiene nuestro like en metodo que le ponemos es el delete
          ? await http.delete(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
          // Si No tiene nuestro like el metodo que tendra es un post
          : await http.post(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );

      if (response.statusCode >= 400) {
        // Revertir cambios si falla (Rollback)
        _items[index] = oldPhoto;
        notifyListeners();
        // Opcional: lanzar error o mostrar mensaje
        print('Error al dar like: ${response.statusCode}');
      }
    } catch (error) {
      // Revertir cambios si hay excepción
      _items[index] = oldPhoto;
      notifyListeners();
      rethrow;
    }
  }
  // ********** FIN API: Likes ********** //

  // ********** Gestion Local de Comentarios ********** //
  // Se llaman desde la pantalla de detalle para actualizar la lista principal

  void notifyCommentAdded(int photoId) {
    final index = _items.indexWhere((item) => item.id == photoId);
    if (index < 0) return;

    final oldPhoto = _items[index];
    _items[index] = oldPhoto.copyWith(
      comentariosCount: oldPhoto.comentariosCount + 1,
      comentadoPorUsuario: true, // Asumimos que si has comentado, ahora es true
    );
    notifyListeners();
  }

  void notifyCommentDeleted(int photoId, bool stillHasComments) {
    final index = _items.indexWhere((item) => item.id == photoId);
    if (index < 0) return;

    final oldPhoto = _items[index];
    _items[index] = oldPhoto.copyWith(
      comentariosCount: oldPhoto.comentariosCount > 0
          ? oldPhoto.comentariosCount - 1
          : 0,
      comentadoPorUsuario:
          stillHasComments, // Actualizamos basándonos en si quedan comentarios
    );
    notifyListeners();
  }

  // ********** FIN Gestion Local de Comentarios ********** //

  // ************ API: Crear Fotografia ************ //

  Future<void> createPhoto(
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
    final token = await _getToken();

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      ..fields['titulo'] = titulo
      ..fields['descripcion'] = descripcion;

    // Optional fields
    if (latitud != null) request.fields['latitud'] = latitud.toString();
    if (longitud != null) request.fields['longitud'] = longitud.toString();
    if (iso != null) request.fields['ISO'] = iso.toString();
    if (velocidadObturacion != null) {
      request.fields['velocidad_obturacion'] = velocidadObturacion;
    }
    if (apertura != null) request.fields['apertura'] = apertura.toString();

    // Image file
    // Assumes simple filename based extension or jpeg default.
    // Ideally we verify extension or use a mime library,
    // but for now we trust the file extension or default to jpg.
    request.files.add(
      await http.MultipartFile.fromPath(
        'direccion_imagen', // Changed from 'imagen' to match backend validation error "The direccion imagen field is required"
        image.path,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        // final responseData = json.decode(response.body);
        // We could add the new photo to _items local list directly to avoid a refetch
        // but fetchPhotos() is safer to get the exact server state including URL.
        // Let's just notify and rely on pull-to-refresh or logic to refetch.
        await fetchPhotos();
      } else {
        print('Error creating photo: ${response.body}');
        // Intentamos decodificar el error si es JSON
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
      print('Exception creating photo: $error');
      rethrow;
    }
  }

  // ********** FIN API: Crear Fotografia ********** //
}
