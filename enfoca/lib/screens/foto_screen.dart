import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // El cartero de Internet
import 'dart:convert'; // Traductor de JSON a Clases Dart
import 'package:shared_preferences/shared_preferences.dart'; // Disco Duro Local (Cookies móviles)

import '../models/fotografia.dart';
import '../models/comentario.dart';
import '../widgets/photo_item.dart';
import '../widgets/comentario_item.dart';
import '../services/photo_service.dart';

// ==========================================
// PANTALLA DE DETALLE (EL CINE FOTOGRÁFICO)
// ==========================================
// Cuando tocas una foto en el muro, esta pantalla se desdobla.
// Muestra la foto en pantalla completa arriba, y el chat de comentarios debajo.

class PhotoScreen extends StatefulWidget {
  final Fotografia photo; // Recibimos la obra de arte por parámetro

  const PhotoScreen({Key? key, required this.photo}) : super(key: key);

  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  // ==========================================
  // ESTADO INTERNO (MEMORIA RAM DE LA PANTALLA)
  // ==========================================
  List<Comentario> _comentarios = []; // Buzón de mensajes
  bool _isLoading = true; // Telón de carga azul
  int?
  _currentUserId; // ¿Quién soy yo? (Para saber si el botón "Borrar" sale o no)

  // Teclado virtual
  final _commentController = TextEditingController();

  // ==========================================
  // IGNICIÓN DE LA PANTALLA (INIT)
  // ==========================================

  @override
  void initState() {
    super.initState();
    // En cuanto la pantalla nace, mandamos 2 cartas simultáneas (Asíncronas):
    // 1. Averiguar quién tiene el móvil en la mano.
    _obtenerUsuarioActual();
    // 2. Descargar el historial de chat de esta foto.
    _obtenerComentarios();
  }

  // ==========================================
  // LÓGICA DE NEGOCIO Y COMUNICACIONES (API)
  // ==========================================

  // --- OBTENER INQUILINO ACTUAL ---
  Future<void> _obtenerUsuarioActual() async {
    // Abrimos el cajón de la mesita de noche del móvil
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData'))
      return; // No hay nadie logueado (Imposible pero seguro)

    // Decodifica el maletín JSON guardado
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

    // 1. Camino Rápido (Caché Oculta): Si ya guardamos el ID ayer, úsalo.
    if (extractedUserData.containsKey('userId')) {
      if (!mounted) return;
      setState(() {
        _currentUserId = extractedUserData['userId'];
      });
      return;
    }

    // 2. Camino Lento (API Rest): Si es la primera vez, pregúntale a Laravel.
    final token = extractedUserData['token']; // Llave maestra
    final url = Uri.parse('http://enfoca.alwaysdata.net/api/user');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // 200 OK: La puerta del servidor se abrió
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final userId = userData['data']['id']; // Buceo en el JSON

        if (!mounted)
          return; // Si el usuario cerró la pantalla rápida, no hagas crash
        setState(() {
          _currentUserId = userId; // Asignación visual
        });

        // Memorizamos en el disco duro para no volver a preguntar mañana
        extractedUserData['userId'] = userId;
        extractedUserData['userName'] = userData['data']['name'];
        extractedUserData['userEmail'] = userData['data']['email'];
        await prefs.setString('userData', json.encode(extractedUserData));
      }
    } catch (e) {
      debugPrint('Error de sonar obteniendo identidad: $e');
    }
  }

  // --- DESCARGAR EL HILO DE CHAT ---
  Future<void> _obtenerComentarios() async {
    final url = Uri.parse(
      'http://enfoca.alwaysdata.net/api/fotografias/${widget.photo.id}/comentarios',
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) return;

      final extractedUserData =
          json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      final token = extractedUserData['token'];

      // Redundancia de seguridad: Si no sabíamos quién éramos, lo forzamos.
      if (_currentUserId == null && extractedUserData.containsKey('userId')) {
        _currentUserId = extractedUserData['userId'];
      }

      // Interrogatorio HTTP GET
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> comentariosList =
            data['data']; // El array puro "[]"
        if (!mounted) return;

        // Conversión Mágica: De Array sucio a Lista de Objetos Dart (POJO) orientada a objetos.
        setState(() {
          _comentarios = comentariosList
              .map((json) => Comentario.fromJson(json))
              .toList();
          _isLoading = false; // Levantamos el telón azul
        });
      } else {
        // Silencio diplomático
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- DISPARAR NUEVO MENSAJE (HTTP POST) ---
  Future<void> _enviarComentario() async {
    final enteredComment = _commentController.text;

    // Filtro Anti-Spam (Evita enviar cajas vacías a la base de datos)
    if (enteredComment.isEmpty) return;

    final url = Uri.parse(
      'http://enfoca.alwaysdata.net/api/fotografias/${widget.photo.id}/comentarios',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) return;

      final extractedUserData =
          json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      final token = extractedUserData['token'];

      // Emisión del paquete de datos al espacio
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type':
              'application/json', // Ojo: A diferencia del GET, mandamos un TYPE porque enviamos un Body
        },
        body: json.encode({
          'contenido': enteredComment,
        }), // Serialización inversa (De Texto a JSON)
      );

      // Si Laravel dio luz verde (201 Created o 200 OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        _commentController
            .clear(); // Limpiamos la cajetilla del texto como el WhatsApp
        if (!mounted) return;

        // Recargamos el hilo entero para que la nueva burbujita aparezca abajo (Sensación de directo)
        await _obtenerComentarios();
        if (!mounted) return;

        // MAGIA NEGRA FLUÍDA: Le chivamos al Provider general (PhotoService)
        // que ha sumado un comentario, así el "globo" de fuera en el feed principal
        // subirá su contador (Ej: De 10 a 11) SIN RECARGAR LA PÁGINA ANTERIOR.
        Provider.of<PhotoService>(
          context,
          listen: false,
        ).notificarComentarioAnadido(widget.photo.id);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comunicaciones fallidas: ${response.statusCode}'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colisión de red. Intenta más tarde.')),
      );
    }
  }

  // --- FUEGO AMIGO: ELIMINAR PROPIO COMENTARIO (HTTP DELETE) ---
  Future<void> _eliminarComentario(int commentId) async {
    final url = Uri.parse(
      'http://enfoca.alwaysdata.net/api/comentarios/$commentId',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final extractedUserData =
          json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      final token = extractedUserData['token'];

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;

        setState(() {
          // Destruimos el widget local en la memoria (Visual instantáneo sin recargar nada de internet)
          _comentarios.removeWhere((c) => c.id == commentId);
        });

        // Matemáticas: ¿Quedó algún otro comentario de este usuario?
        // Sirve para apagar el "brillo azul" del icono de comentarios general en el Muro si ya no hay rastro tuyo.
        final bool userStillHasComments = _comentarios.any(
          (c) => c.userId == _currentUserId,
        );

        // Actualizar el contador global en el servicio restando "-1" y avisando del brillo azul.
        Provider.of<PhotoService>(
          context,
          listen: false,
        ).notificarComentarioEliminado(widget.photo.id, userStillHasComments);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu voz ha sido purgada.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Defensa de la red activada: ${response.statusCode}'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red inescrutable al eliminar.')),
      );
    }
  }

  // ==========================================
  // WIDGETS EMERGENTES: EL TRIBUNAL DE REPORTES
  // ==========================================

  void _mostrarDialogoReporte() {
    String motivoSeleccionado = '';

    // Popup Modal oscuro en medio de la pantalla
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Denuncia Formal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enuncia los crímenes visuales de esta captura. Un Gran Administrador evaluará el caso.',
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Motivo Causal',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (val) {
                motivoSeleccionado = val; // Actualiza el string ciego
              },
            ),
          ],
        ),
        actions: [
          // Botón Pánico (Salida)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Indultar'),
          ),
          // Botón Ejecutor
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (motivoSeleccionado.trim().isEmpty) return; // Validación vacía

              Navigator.of(ctx).pop(); // Escondemos el menú primero.
              if (!mounted) return;

              try {
                // Inquisición en proceso a PHP.
                await Provider.of<PhotoService>(
                  context,
                  listen: false,
                ).reportarFoto(widget.photo.id, motivoSeleccionado.trim());
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Burocracia tramitada. Notarios en camino.'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fallo en el servidor judicial: $e')),
                );
              }
            },
            child: const Text(
              'Sentenciar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RENDERIZADO VISUAL DEL ESPECTÁCULO (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Truco de reactividad en cadena.
    // Aunque nos llega 'widget.photo' por el portal estático, nosotros preguntamos
    // en tiempo real al Banco de RAM (Provider) si existe una "versión más nueva" de ella,
    // (Ej. Porque el usuario le acaba de dar "Me gusta"). Si la hay, la pintamos en lugar de la foto vieja.
    final photoService = Provider.of<PhotoService>(context);
    final currentPhoto =
        photoService.obtenerFotoPorId(widget.photo.id) ?? widget.photo;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPhoto.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem),
            tooltip: 'Censurar Documento',
            onPressed: _mostrarDialogoReporte,
          ),
        ],
      ),
      // SingleChildScrollView engloba la Foto GIGANTE y la lista de Comentarios LARGA
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // LA OBRA PRINCIPAL (MÓDULO COMPARTIDO)
            // ==========================================
            // Pasamos "currentPhoto" (La actualizada) al Widget que la diseña.
            // "fueraFotografia: false" significa "No somos la tarjeta pequeña del muro, somos la tarjeta XXL HD".
            PhotoItem(photo: currentPhoto, fueraFotografia: false),

            // ==========================================
            // SECCIÓN COLUMNA VERTEBRAL DEL CHAT
            // ==========================================
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // Alineamos los textos a la izquierda (Start)
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // "Header" de los comentarios
                  const Text(
                    "Ágora Pública",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ==========================================
                  // ZONA DEL TECLADO INPUT CIBERNÉTICO
                  // ==========================================
                  Row(
                    children: [
                      // La caja de escritura, que crece en FlexRatio "Expanded"
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText:
                                'Transmite tus pulsos electromagnéticos...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      // El Gatillo Inyector de Mensajes
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _enviarComentario, // Enviar al Servidor
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // PARRILLA SOCIAL DE BURBUJAS DE COMENTARIOS
                  // ==========================================
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _comentarios.isEmpty
                      ? const Text(
                          "Esta publicación es un páramo estepario de soledad. Inaugúrala.",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        )
                      // Bucle constructor. No hace Scroll (shrinkWrap, NeverScrollable)
                      // porque esto ya hace Scroll dentro del "SingleChildScrollView" general superior.
                      : ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Físicas anuladas
                          itemCount: _comentarios.length,
                          itemBuilder: (ctx, index) {
                            return ComentarioItem(
                              comentario: _comentarios[index],
                              idUsuarioActual:
                                  _currentUserId, // Delegamos el ID para decidir si se le habilita la papelera al lado
                              alBorrar: () => _eliminarComentario(
                                _comentarios[index].id,
                              ), // Puntero a función (No se ejecuta, se DELEGA el borrado).
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
