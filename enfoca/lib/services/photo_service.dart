import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fotografia.dart';
import '../models/user.dart';

// Servicio de fotos
class PhotoService with ChangeNotifier {
  // URL base de la API
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // Listas para el feed, mis fotos y búsqueda
  List<Fotografia> _items = [];
  List<Fotografia> _misItems = [];
  List<Fotografia> _itemsUsuarioBuscado = [];

  // Getters para acceder a las listas
  List<Fotografia> get items => [..._items];
  List<Fotografia> get misItems => [..._misItems];
  List<Fotografia> get itemsUsuarioBuscado => [..._itemsUsuarioBuscado];

  // Busca una foto en las listas locales por su ID
  Fotografia? obtenerFotoPorId(int id) {
    try {
      return _items.firstWhere((photo) => photo.id == id);
    } catch (e) {}

    try {
      return _misItems.firstWhere((photo) => photo.id == id);
    } catch (e) {}

    try {
      return _itemsUsuarioBuscado.firstWhere((photo) => photo.id == id);
    } catch (e) {}

    return null;
  }

  // MÉTODOS DE RED (API)

  // Carga todas las fotos del feed
  Future<void> obtenerFotos() async {
    final url = Uri.parse('$_baseUrl/fotografias');
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

        _items = photosList.map((json) => Fotografia.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar fotos');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Carga solo mis fotos
  Future<void> obtenerMisFotos() async {
    final url = Uri.parse('$_baseUrl/mis-fotos');
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
        final userName = await _obtenerNombreUsuario() ?? 'Usuario';

        _misItems = photosList.map((json) {
          final foto = Fotografia.fromJson(json);
          if (foto.userName == 'Usuario') {
            return foto.copyWith(userName: userName);
          }
          return foto;
        }).toList();

        notifyListeners();
      } else {
        throw Exception('Error al obtener mis fotos');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Carga fotos de un usuario específico
  Future<void> obtenerFotosUsuario(int userId, {String? forcedUserName}) async {
    final url = Uri.parse('$_baseUrl/fotografias-usuario/$userId');
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
        throw Exception('Error al obtener fotos del usuario');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Obtiene una foto por ID directamente de la API
  Future<Fotografia?> obtenerFotoPorIdApi(int fotoId) async {
    final url = Uri.parse('$_baseUrl/fotografias/$fotoId');
    final token = await _obtenerToken();

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

  // BUSCADORES

  // Busca usuario por nombre
  Future<User?> buscarUsuarioPorNombre(String name) async {
    final url = Uri.parse('$_baseUrl/usuarios/buscar?query=$name');
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
        final List<dynamic> usersData = data['data'];

        if (usersData.isNotEmpty) {
          return User.fromJson(usersData[0]);
        }
        return null;
      } else {
        throw Exception('Error en la búsqueda');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Búsqueda de fotos con parámetros
  Future<void> buscarFotosAvanzado(String tipoBusqueda, String query) async {
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
        throw Exception('Error en la búsqueda avanzada');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Subir una nueva foto
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

    if (token == null) throw Exception('Token no encontrado');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      ..fields['titulo'] = titulo
      ..fields['descripcion'] = descripcion;

    if (latitud != null) request.fields['latitud'] = latitud.toString();
    if (longitud != null) request.fields['longitud'] = longitud.toString();
    if (iso != null) request.fields['ISO'] = iso.toString();
    if (velocidadObturacion != null) {
      request.fields['velocidad_obturacion'] = velocidadObturacion;
    }
    if (apertura != null) request.fields['apertura'] = apertura.toString();

    request.files.add(
      await http.MultipartFile.fromPath('direccion_imagen', image.path),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await obtenerFotos();
      } else {
        throw Exception('Error al subir la foto');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Dar o quitar Like
  Future<void> alternarLike(int id) async {
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

    // Comprobamos estado inicial
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
          return;
        }
      }
    }

    // Cambio visual rápido
    actualizarLista(_items);
    actualizarLista(_misItems);
    actualizarLista(_itemsUsuarioBuscado);
    notifyListeners();

    final url = Uri.parse('$_baseUrl/fotografias/$id/like');
    final token = await _obtenerToken();

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

      // Si falla en el servidor, deshacemos el cambio visual
      if (response.statusCode >= 400) {
        actualizarLista(_items);
        actualizarLista(_misItems);
        actualizarLista(_itemsUsuarioBuscado);
        notifyListeners();
      }
    } catch (error) {
      // Revertir si hay error de red
      actualizarLista(_items);
      actualizarLista(_misItems);
      actualizarLista(_itemsUsuarioBuscado);
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar contadores de comentarios
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

  // MÉTODOS DE ADMIN

  // Obtener todas las fotos para administración
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
        throw Exception('Error al listar fotos (admin)');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Eliminar foto definitivamente
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
        throw Exception('Error al eliminar foto');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Editar datos de una foto (admin)
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
        await obtenerFotos();
      } else {
        throw Exception('Error al editar foto');
      }
    } catch (error) {
      rethrow;
    }
  }

  // REPORTES

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
        throw errorData['error'] ?? 'Ya has reportado esta foto.';
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw 'Error al enviar reporte.';
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<List<dynamic>> obtenerReportes() async {
    final url = Uri.parse('$_baseUrl/admin/reportes');
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
        return data['data'];
      } else {
        return [];
      }
    } catch (error) {
      return [];
    }
  }

  // Borrar reportes de una foto
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
        throw Exception('Error al eliminar reportes.');
      }
    } catch (error) {
      rethrow;
    }
  }

  // MÉTODOS PRIVADOS PARA EL TOKEN

  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return null;
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['token'];
  }

  Future<String?> _obtenerNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return null;
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['userName'];
  }
}
