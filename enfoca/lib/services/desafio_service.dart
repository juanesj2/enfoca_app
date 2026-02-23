import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/desafio.dart';

// ==========================================
// SERVICIO DE RED: GESTOR DE DESAFÍOS (LOGROS)
// ==========================================
// Esta clase se encarga EXCLUSIVAMENTE de hablar con el servidor de Laravel
// para descargar los logros (Todos o los míos).
//
// Al usar 'with ChangeNotifier', convertimos esta clase en un "Proveedor de Estado Global" (Provider).
// Significa que si descargamos logros nuevos, podemos gritar `notifyListeners()`
// y todas las pantallas que estén dibujando logros se actualizarán automáticamente al unísono.

class DesafioService with ChangeNotifier {
  // ==========================================
  // CONFIGURACIÓN DE RED
  // ==========================================
  // Ruta base de nuestra API en Internet (El servidor remoto donde alojamos Laravel)
  final String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  // ==========================================
  // ESTADO INTERNO (Datos Privados)
  // ==========================================
  // Usamos el guion bajo '_' para que estas listas sean privadas (Encapsulamiento).
  // Solo este servicio puede modificarlas directamente.
  List<Desafio> _todosLosDesafios = [];
  List<Desafio> _misDesafios = [];

  // ==========================================
  // GETTERS (Exposición Segura de Datos)
  // ==========================================
  // Usamos el operador spread `[...]` para devolver un "Clon" de la lista.
  // Así evitamos que un widget tramposo modifique nuestra lista _global_ directamente por error.
  List<Desafio> get todosLosDesafios => [..._todosLosDesafios];
  List<Desafio> get misDesafios => [..._misDesafios];

  // ==========================================
  // AUTENTICACIÓN: OBTENER TOKEN JWT
  // ==========================================
  // Lee el disco duro del móvil para sacar la clave secreta de seguridad (Token)
  // que nos dio Laravel al hacer Login. Indispensable para que el servidor confíe en nosotros.
  Future<String?> _obtenerToken() async {
    final prefs =
        await SharedPreferences.getInstance(); // Acceso a la memoria del teléfono

    if (!prefs.containsKey('userData')) {
      return null;
    }

    // Convertimos el String guardado en el disco a un Mapa dinámico
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

    // Devolvemos la pieza que nos interesa
    return extractedUserData['token'];
  }

  // ==========================================
  // PROCESO DE CARGA MASIVA RÁPIDA
  // ==========================================
  // Llama secuencialmente a las dos funciones de descarga. Útil al arrancar la App.
  Future<void> cargarTodo() async {
    try {
      await obtenerTodos();
    } catch (e) {
      print('Error obteniendo todos los desafíos: $e');
      rethrow; // Si falla el catálogo general, la app debe saberlo
    }

    try {
      await obtenerMisDesafios();
    } catch (e) {
      print(
        'Aviso: Fallo al obtener mis desafíos (Ignorando para evitar Pantalla Vacía): $e',
      );
      // Falla silenciosamente. No lanzamos excepcion para no bloquear la Interfaz del usuario
      // si por algún casual el servidor de base de datos remoto se satura al contar mis logros.
    }
  }

  // ==========================================
  // PETICIÓN GET: TODOS LOS DESAFÍOS
  // ==========================================
  Future<void> obtenerTodos() async {
    final token = await _obtenerToken();
    if (token == null)
      return; // Si no hay usuario logueado, cancelamos la llamada de red.

    // Construimos la URL completa: http://enfoca...net/api/desafios
    final url = Uri.parse('$_baseUrl/desafios');

    try {
      // Función asíncrona: El hilo principal se detiene de forma transparente aquí
      // esperando la respuesta del servidor mientras el usuario sigue viendo animaciones.
      final response = await http.get(
        url,
        // Inyectamos las cabeceras REST HTTP
        headers: {
          'Authorization': 'Bearer $token', // Nuestro pase VIP
          'Accept':
              'application/json', // Exigimos a PHP que nos responda estrictamente en JSON
        },
      );

      // El código 200 HTTP significa "OK", todo salió perfectamente bien en el servidor.
      if (response.statusCode == 200) {
        final data = json.decode(
          response.body,
        ); // Parseamos el texto en un mapa de Dart

        // Magia condicional: La API a veces empaqueta la lista cruda, y a veces dentro
        // de un bloque llave-valor llamado "data". Lo averiguamos.
        final List<dynamic> desafiosJson = data is List
            ? data
            : (data['data'] ?? []);

        // Map asíncrono: Convertimos cada "Desafío crudo en JSON" a "Desafio (Clase Dart)"
        _todosLosDesafios = desafiosJson
            .map((json) => Desafio.fromJson(json))
            .toList();

        // MUY IMPORTANTE: Avisar a las pantallas que ya hay datos nuevos para que se vuelvan a pintar.
        notifyListeners();
      } else {
        throw Exception('Error HTTP: al cargar todos los desafíos');
      }
    } catch (e) {
      print('Excepción en obtenerTodos: $e');
      rethrow;
    }
  }

  // ==========================================
  // PETICIÓN GET: MIS DESAFÍOS COMPLETADOS
  // ==========================================
  // (La arquitectura y lógica de red es idéntica a la función anterior, pero cambia la URL objetivo y la variable).
  Future<void> obtenerMisDesafios() async {
    final token = await _obtenerToken();
    if (token == null) return;

    // Conectamos a un endpoint distinto que, por lógica del backend,
    // solo nos traerá los asociados numéricamente a nuestra id_usuario.
    final url = Uri.parse('$_baseUrl/desafios/mis-desafios');
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
        final List<dynamic> desafiosJson = data is List
            ? data
            : (data['data'] ?? []);

        // Rellenamos LA OTRA LISTA (La personal), y avisamos a la interfaz.
        _misDesafios = desafiosJson
            .map((json) => Desafio.fromJson(json))
            .toList();

        notifyListeners();
      } else {
        throw Exception('Error al cargar mis desafíos');
      }
    } catch (e) {
      print('Excepción en obtenerMisDesafios: $e');
      rethrow;
    }
  }
}
