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
  List<Fotografia> _itemsUsuarioBuscado =
      []; // Lista para almacenar las fotos de un usuario buscado

  List<Fotografia> get items {
    return [..._items];
  }

  // Getter para acceder a las fotos del usuario
  List<Fotografia> get misItems {
    return [..._misItems];
  }

  // Getter para acceder a las fotos del usuario buscado
  List<Fotografia> get itemsUsuarioBuscado {
    return [..._itemsUsuarioBuscado];
  }

  // Método para buscar una foto por ID en TODAS las listas locales
  Fotografia? obtenerFotoPorId(int id) {
    // 1. Buscar en Items generales (Feed)
    try {
      return _items.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // No encontrada
    }

    // 2. Buscar en Mis Fotos
    try {
      return _misItems.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // No encontrada
    }

    // 3. Buscar en Fotos de Usuario Buscado
    try {
      return _itemsUsuarioBuscado.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // No encontrada
    }

    return null;
  }

  // ********** Métodos Auxiliares ********** //

  // Método auxiliar para obtener el token guardado en SharedPreferences
  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['token'];
  }
  // ********** FIN Métodos Auxiliares ********** //

  // ********** API: Carga de Fotos ********** //
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
  Future<void> obtenerFotosUsuario(int userId) async {
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

        _itemsUsuarioBuscado = photosList
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

  // ********** API: Búsqueda de Usuario por Nombre ********** //
  Future<int?> buscarIdUsuarioPorNombre(String name) async {
    final url = Uri.parse('$_baseUrl/users/search?query=$name');
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
  // ********** API: Likes ********** //
  // Funcion para alternar los likes
  Future<void> alternarLike(int id) async {
    // Helper para actualizar una lista especifica
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

    // Buscamos la foto original para saber el estado actual (usamos _items como referencia principal, o cualquiera)
    // Necesitamos saber si estaba likeada para la llamada a la API.
    // Asumimos que todas las listas están sincronizadas en cuanto a "likedByUser".
    bool isLikedOriginal = false;
    // Intentamos buscar en _items primero
    var index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      isLikedOriginal = _items[index].likedByUser;
    } else {
      // Si no está en _items, buscamos en _misItems
      index = _misItems.indexWhere((item) => item.id == id);
      if (index >= 0) {
        isLikedOriginal = _misItems[index].likedByUser;
      } else {
        // Si no, en _itemsUsuarioBuscado
        index = _itemsUsuarioBuscado.indexWhere((item) => item.id == id);
        if (index >= 0) {
          isLikedOriginal = _itemsUsuarioBuscado[index].likedByUser;
        } else {
          // Si no está en ninguna, no hacemos nada
          return;
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

    // Enviamos las peticiones al servidor
    try {
      final response = isLikedOriginal
          ? await http.delete(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
          : await http.post(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );

      if (response.statusCode >= 400) {
        // Revertir cambios si falla (Rollback)
        // Simplemente volvemos a llamar a actualizarLista, que invierte el estado
        actualizarLista(_items);
        actualizarLista(_misItems);
        actualizarLista(_itemsUsuarioBuscado);
        notifyListeners();
        print('Error al dar like: ${response.statusCode}');
      }
    } catch (error) {
      // Revertir cambios si hay excepción
      actualizarLista(_items);
      actualizarLista(_misItems);
      actualizarLista(_itemsUsuarioBuscado);
      notifyListeners();
      rethrow;
    }
  }
  // ********** FIN API: Likes ********** //

  // ********** Gestión Local de Comentarios ********** //
  // Se llaman desde la pantalla de detalle para actualizar la lista principal

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

  // ********** FIN Gestión Local de Comentarios ********** //

  // ************ API: Crear Fotografía ************ //

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
      throw Exception('No authentication token found');
    }

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      ..fields['titulo'] = titulo
      ..fields['descripcion'] = descripcion;

    // Campos opcionales
    if (latitud != null) request.fields['latitud'] = latitud.toString();
    if (longitud != null) request.fields['longitud'] = longitud.toString();
    if (iso != null) request.fields['ISO'] = iso.toString();
    if (velocidadObturacion != null) {
      request.fields['velocidad_obturacion'] = velocidadObturacion;
    }
    if (apertura != null) request.fields['apertura'] = apertura.toString();

    // Archivo de imagen
    // Asume que la extension es simple o por defecto jpg/jpeg.
    // Idealmente deberiamos verificar el mime type.
    // pero por ahora confiamos en la extension del archivo.
    request.files.add(
      await http.MultipartFile.fromPath(
        'direccion_imagen', // Cambiado de 'imagen' para coincidir con validacion del backend
        image.path,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Exito
        // Podriamos añadir la foto a _items localmente para evitar recargar
        // pero obtenerFotos() es más seguro para asegurar el estado del servidor (URLs, etc).
        // Por ahora recargamos todo.
        await obtenerFotos();
      } else {
        print('Error al crear foto: ${response.body}');
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
      print('Excepcion al crear foto: $error');
      rethrow;
    }
  }

  // ********** FIN API: Crear Fotografía ********** //
}
