import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fotografia.dart';
import '../models/user.dart';

// ==========================================
// SERVICIO CENTRAL DE FOTOGRAFÍAS (REST API)
// ==========================================
// Este Provider es el núcleo pesado de toda la red social.
// Maneja la subida de fotos (Multipart), la descarga del feed,
// el sistema de "Me Gusta" optimista, y la moderación del Administrador.

class PhotoService with ChangeNotifier {
  // Nodo raíz de la API de Laravel
  static const String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // ==========================================
  // ESTADO GLOBAL DE LA APP (STATE)
  // ==========================================
  // Mantenemos 3 listas separadas en Memoria RAM para no mezclar contextos visuales.

  // 1. El Feed público general (pantalla principal)
  List<Fotografia> _items = [];

  // 2. Mi galería privada (Mi perfil)
  List<Fotografia> _misItems = [];

  // 3. Resultados temporales cuando uso el buscador (Pantalla de Búsqueda)
  List<Fotografia> _itemsUsuarioBuscado = [];

  // ==========================================
  // GETTERS (SEGURIDAD)
  // ==========================================
  // Usamos `[...]` para exportar copias inmutables y proteger el estado original.

  List<Fotografia> get items {
    return [..._items];
  }

  List<Fotografia> get misItems {
    return [..._misItems];
  }

  List<Fotografia> get itemsUsuarioBuscado {
    return [..._itemsUsuarioBuscado];
  }

  // ==========================================
  // BÚSQUEDA CRUZADA EN CACHÉ RAM
  // ==========================================
  // Utiliza el id de una foto para escanear las tres memorias listas locales de forma ultrarrápida,
  // antes de tener que pedirla a Internet. Útil al pulsar una notificación o enlace directo.
  Fotografia? obtenerFotoPorId(int id) {
    // 1. Escanea el Feed principal
    try {
      return _items.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // Ignoramos el error si no está
    }

    // 2. Escanea Mi Perfil
    try {
      return _misItems.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // Ignoramos el error si no está
    }

    // 3. Escanea la Búsqueda
    try {
      return _itemsUsuarioBuscado.firstWhere((photo) => photo.id == id);
    } catch (e) {
      // Ignoramos el error si no está
    }

    return null; // Si no está cargada en ninguna lista local, devolvemos nulo.
  }

  // ==========================================
  // OPERACIONES DE LECTURA (GET) - DESCARGAS MASIVAS
  // ==========================================

  // Descarga y sobrescribe la lista entera del feed público.
  Future<void> obtenerFotos() async {
    final url = Uri.parse('$_baseUrl/fotografias');
    final token = await _obtenerToken(); // Abro la bóveda local

    if (token == null) {
      throw Exception(
        'No hay token, el sistema cortocircuita la petición de red.',
      );
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

        // Laravel pagina o envuelve las respuestas en el nodo "data"
        final List<dynamic> photosList = data['data'];

        // Vaciamos e inflamos la lista principal
        _items = photosList.map((json) => Fotografia.fromJson(json)).toList();

        // Disparamos el Redraw (Re-dibujado) masivo de la UI
        notifyListeners();
      } else {
        throw Exception(
          'Error 500 o 404 del servidor al pedir catálogo general',
        );
      }
    } catch (error) {
      rethrow;
    }
  }

  // Idéntico al anterior pero consumiendo el Endpoint exclusivo para Mi Perfil
  Future<void> obtenerMisFotos() async {
    final url = Uri.parse('$_baseUrl/mis-fotos');
    final token = await _obtenerToken();

    if (token == null) {
      throw Exception('No hay token de sesión.');
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

        // Truco Visual: Si Laravel me omite mi propio nombre (por optimizar),
        // lo inyectamos manualmente para que mi perfil luzca perfecto.
        final userName = await _obtenerNombreUsuario() ?? 'Usuario';

        _misItems = photosList.map((json) {
          final foto = Fotografia.fromJson(json);
          // Constructor CopyWith: Si se llama Usuario, lo cambio por ejemplo a "Juanes"
          if (foto.userName == 'Usuario') {
            return foto.copyWith(userName: userName);
          }
          return foto;
        }).toList();

        notifyListeners();
      } else {
        throw Exception('El Backend rechazó darnos Tus Fotografías');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Lista las fotos que subió una persona específica clicando su nombre
  Future<void> obtenerFotosUsuario(int userId, {String? forcedUserName}) async {
    // Aquí la URL es dinámica: Contiene el ID de la víctima de nuestra búsqueda
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

        // Llenamos la 3ª Lista (La temporal de Búsqueda)
        _itemsUsuarioBuscado = photosList.map((json) {
          final foto = Fotografia.fromJson(json);
          if (forcedUserName != null && foto.userName == 'Usuario') {
            return foto.copyWith(userName: forcedUserName);
          }
          return foto;
        }).toList();

        notifyListeners();
      } else {
        throw Exception('Error 500 al investigar usuario concreto');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // OPERACIONES DE ESPECÍFICO A API (SINGLE FETCH)
  // ==========================================
  // Si nos pasan un enlace de WhatsApp y abrimos la app, puede que la foto
  // no estuviese en la RAM. Así que vamos forzosamente a buscar esa específica a la red.
  Future<Fotografia?> obtenerFotoPorIdApi(int fotoId) async {
    final url = Uri.parse('$_baseUrl/fotografias/$fotoId');
    final token = await _obtenerToken();

    // Intentamos mandarla sin Auth por si es pública, o con Auth si hay inicio de sesión.
    final headers = {'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Construimos 1 solo objeto modelo de Dart
        return Fotografia.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // BÚSQUEDA AVANZADA MEDIANTE FILTROS Y QUERIES REST
  // ==========================================

  // Buscar a alguien introduciendo letras en un formulario
  Future<User?> buscarUsuarioPorNombre(String name) async {
    // Construcción de la URL con un Query Parameter (?parametro=valor)
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
          // Devolvemos AL PRIMER sujeto que coincida y lo Parseamos a Objeto User
          return User.fromJson(usersData[0]);
        }
        return null;
      } else {
        throw Exception('El backend no entiende la solicitud de busqueda');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Buscador paramétrico de Exposición/ISO/Cámaras
  Future<void> buscarFotosAvanzado(String tipoBusqueda, String query) async {
    // Ej: ?iso=100
    // Ej: ?texto=Perro
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

        // Guardamos los resultados de los metadatos en la lista dinámica de buscador
        _itemsUsuarioBuscado = photosList
            .map((json) => Fotografia.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Fallo en el motor de búsqueda MySQL Avanzado');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // ALTA DE CONTENIDO NUEVO (POST MULTIPART)
  // ==========================================
  // Esto no es un POST normal de texto JSON. Estamos subiendo Binarios Grandes (Imágenes JPG/PNG).
  // Por lo tanto usamos el protocolo "Multipart/form-data".
  Future<void> crearFoto(
    File image, // Objeto binario del disco duro
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

    if (token == null) throw Exception('Token Extraviado');

    // Inicializamos una Petición Multiparte Asíncrona Especial de Flutter
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      // Acoplamos los Textos planos como "Campos" de Formulario Antiguo HTML
      ..fields['titulo'] = titulo
      ..fields['descripcion'] = descripcion;

    // Campos TÉCNICOS Opcionales (Si vienen null, simplemente no se los mandamos a PHP)
    if (latitud != null) request.fields['latitud'] = latitud.toString();
    if (longitud != null) request.fields['longitud'] = longitud.toString();
    if (iso != null) request.fields['ISO'] = iso.toString();
    if (velocidadObturacion != null) {
      request.fields['velocidad_obturacion'] = velocidadObturacion;
    }
    if (apertura != null) request.fields['apertura'] = apertura.toString();

    // Archivo Binario Giga/Megabyte (LA FOTO EN SÍ)
    request.files.add(
      await http.MultipartFile.fromPath(
        'direccion_imagen', // Llave mágica que Laravel 'Request->file()' está esperando atrapar
        image.path,
      ),
    );

    try {
      // Ordenamos a la antena Wi-Fi del móvil disparar los binarios fraccionados
      final streamedResponse = await request.send();
      // Re-ensamblamos el acuse de recibo
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Todo triunfó, así que le pedimos a Laravel que nos de el listado nuevo
        // para que la imagen que acabamos de subir aparezca renderizada de inmediato
        await obtenerFotos();
      } else {
        print('Error de Upload Multiparte: ${response.body}');

        // Parseador de Errores inteligente para extraer el texto rojo "Validation Error" de Laravel
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
      print('Excepción C en UPLOAD FOTO: $error');
      rethrow;
    }
  }

  // ==========================================
  // ACTUALIZACIONES OPTIMISTAS (UI UX MODERNA)
  // ==========================================
  // ¿Qué pasa al dar Like?
  // 1. Modificamos el diseño en 1 milisegundo (ROJO inmédiato). User Experience Increíble.
  // 2. Por detrás disparamos la petición a Laravel, que tarda 500ms en llegar a Francia.
  // 3. Si llega bien, todo se deja como está.
  // 4. Si el servidor de Francia se cae y da un 500 Timeout (Falla), HACE ROLLBACK, deshace el coloreo y le quita el Like en UI.

  Future<void> alternarLike(int id) async {
    // FUNCIÓN CLAUSTRO (Helper): Reemplaza la instancia vieja por una con Like contado en Memoria
    void actualizarLista(List<Fotografia> lista) {
      final index = lista.indexWhere((item) => item.id == id);
      if (index >= 0) {
        final oldPhoto = lista[index];
        final isLiked = oldPhoto.likedByUser; // Estado anterior

        // Matemáticas condicionales de suma/resta
        final newCount = isLiked
            ? (oldPhoto.likesCount > 0 ? oldPhoto.likesCount - 1 : 0)
            : oldPhoto.likesCount + 1;

        // Sobrescribimos en la ranura
        lista[index] = oldPhoto.copyWith(
          likedByUser: !isLiked,
          likesCount: newCount,
        );
      }
    }

    // 1. ANTES DE NADA: ¿La foto ya me gustaba o no? (Investigación Preventiva Local)
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
          return; // No existe
        }
      }
    }

    // 2. ACTUALIZACIÓN VISUAL INMEDIATA EN PANTALLA
    // Aplicamos a todas las listas para que no haya desincronización por si navegamos rápido.
    actualizarLista(_items);
    actualizarLista(_misItems);
    actualizarLista(_itemsUsuarioBuscado);
    notifyListeners(); // ¡Puum! Corazón pintado o despintado en pantalla con Animación

    // 3. LLAMADA REAL LENTA HACIA BACKEND LARAVEL PIVOT
    final url = Uri.parse('$_baseUrl/fotografias/$id/like');
    final token = await _obtenerToken();

    try {
      // Si la investigación local decía que sí me gustaba (ROJO), toca enviar VERBO DELETE (Borrar registro tabla pivot)
      // Si no me gustaba originalmente (GRIS), toca enviar VERBO POST (Crear registro de relación DB MySQL)
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

      // 4. CONTROL DE DAÑOS Y ROLLBACK
      if (response.statusCode >= 400) {
        // Ups, Internet caído o Error 404
        actualizarLista(
          _items,
        ); // Lo llamamos de nuevo (Al voltear booleanos des-hace la resta anterior)
        actualizarLista(_misItems);
        actualizarLista(_itemsUsuarioBuscado);
        notifyListeners(); // Refrescamos pantalla y destrozamos el Like visual al instante
        print(
          'Error en red al intentar solidificar Like: ${response.statusCode}',
        );
      }
    } catch (error) {
      // Rollback violento por excepción Try-Catch (Avión modo, etc...)
      actualizarLista(_items);
      actualizarLista(_misItems);
      actualizarLista(_itemsUsuarioBuscado);
      notifyListeners();
      rethrow;
    }
  }

  // ==========================================
  // INTERCONECTORES Y PARCHES DE CONTADORES (UI LOCAL)
  // ==========================================

  // Evitan tener que recargar toda la base de datos MySQL por red solo porque enviaste
  // tu comentario. Si enviaste comentario con éxito mediante ComentarioService, te llama aquí,
  // y actualiza tu +1 del contador visual de la caja de Fotografía Padre instantáneamente y en silencio temporal (+1).
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
  // PANEL PRIVADO DEL ADMINISTRADOR
  // ==========================================

  // Pide TODO. Incluso las que están "Vetadas" rojas ocultas al público general.
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

        // Enchufe directo en caché central public
        _items = photosList.map((json) => Fotografia.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Rebelión de datos al listar fotos administrativas');
      }
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  // Extirpación total e ignominiosa de una fotografía usando la Death Star HTTP DELETE.
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
        // Eliminación visual de todas las listas si la cirugía fue un éxito perimetral
        _items.removeWhere((item) => item.id == id);
        _misItems.removeWhere((item) => item.id == id);
        notifyListeners();
      } else {
        throw Exception('Servicio bloqueado. No se extirpó a tiempo.');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Veto Político y Modificaciones textuarias directas sin formulario pesado
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
        await obtenerFotos(); // Recarga Global Masiva al modificar un estado
      } else {
        throw Exception('El Backend repelió la invasión al editar');
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // GESTIÓN DE INCIDENCIAS/RECLAMACIONES DE CONTENIDO
  // ==========================================

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
        // Unique Constraint Exception en PostgreSQL o MySQL devuelta de maravilla en un JSON (Duplicidad)
        final errorData = json.decode(response.body);
        throw errorData['error'] ??
            'La foto ya figura en la libreta de reportes bajo tu mano.';
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw 'Fallo en la comisaría de base de datos.';
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
        // Devolvemos el array crudo para que la pantalla de administración la engulla
        return data['data'];
      } else {
        return [];
      }
    } catch (error) {
      return []; // Devolvemos lista trampa vacía antes de colgar con Exception la pantalla Admin.
    }
  }

  // Perdón presidencial (Indultar foto mediante exterminio de denuncias previas)
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
        throw Exception(
          'El Juez Backend denegó limpiar su historial policial.',
        );
      }
    } catch (error) {
      rethrow;
    }
  }

  // ==========================================
  // ÚTILES DISCO DURO AISLADO (PRIVADO)
  // ==========================================

  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['token'];
  }

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
