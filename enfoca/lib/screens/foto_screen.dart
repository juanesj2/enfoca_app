import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fotografia.dart';
import '../models/comentario.dart';
import '../widgets/photo_item.dart';
import '../widgets/comentario_item.dart';
import '../services/photo_service.dart';

// ==========================================
// PANTALLA DE DETALLE DE FOTO
// ==========================================

class PhotoScreen extends StatefulWidget {
  final Fotografia photo;

  const PhotoScreen({Key? key, required this.photo}) : super(key: key);

  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  // ==========================================
  // ESTADO (STATE)
  // ==========================================
  List<Comentario> _comentarios = []; // Lista local de comentarios
  bool _isLoading = true; // Variable para mostrar el spinner de carga
  int? _currentUserId; // Para saber quién es el usuario actual
  final _commentController =
      TextEditingController(); // Controlador para el input de texto

  // ==========================================
  // CICLO DE VIDA
  // ==========================================

  @override
  void initState() {
    super.initState();
    // Al iniciar, buscamos quién es el usuario y cargamos los comentarios
    _obtenerUsuarioActual();
    _obtenerComentarios();
  }

  // ==========================================
  // MÉTODOS DE API Y LÓGICA
  // ==========================================

  // Obtiene el usuario actual (Localmente o vía API)
  Future<void> _obtenerUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return;

    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

    // 1. Intentamos obtener userId de SharedPreferences (optimizado)
    if (extractedUserData.containsKey('userId')) {
      if (!mounted) return;
      setState(() {
        _currentUserId = extractedUserData['userId'];
      });
      return;
    }

    // 2. Fallback: Solo si no está guardado, llamamos a la API
    final token = extractedUserData['token'];
    final url = Uri.parse('http://enfoca.alwaysdata.net/api/user');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final userId =
            userData['data']['id']; // API devuelve { data: { id: ... } }

        if (!mounted) return;
        setState(() {
          _currentUserId = userId;
        });

        // Guardamos para la próxima vez
        extractedUserData['userId'] = userId;
        extractedUserData['userName'] = userData['data']['name'];
        extractedUserData['userEmail'] = userData['data']['email'];
        await prefs.setString('userData', json.encode(extractedUserData));
      }
    } catch (e) {
      debugPrint('Error obteniendo usuario fallback: $e');
    }
  }

  // Descarga los comentarios del servidor
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

      // Intentamos obtener ID de params locales también aquí por si acaso
      if (_currentUserId == null && extractedUserData.containsKey('userId')) {
        _currentUserId = extractedUserData['userId'];
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> comentariosList = data['data'];
        if (!mounted) return;
        setState(() {
          _comentarios = comentariosList
              .map((json) => Comentario.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        // Manejar error silenciosamente o mostrar UI de error local
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

  // Envía un nuevo comentario al servidor
  Future<void> _enviarComentario() async {
    final enteredComment = _commentController.text;

    if (enteredComment.isEmpty) {
      return;
    }

    final url = Uri.parse(
      'http://enfoca.alwaysdata.net/api/fotografias/${widget.photo.id}/comentarios',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) return;

      final extractedUserData =
          json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      final token = extractedUserData['token'];

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'contenido': enteredComment}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _commentController.clear(); // Limpiamos el input
        if (!mounted) return;
        await _obtenerComentarios(); // Recargar comentarios
        if (!mounted) return;

        // Actualizar el contador global en el servicio (UI Pantalla principal)
        Provider.of<PhotoService>(
          context,
          listen: false,
        ).notificarComentarioAnadido(widget.photo.id);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al enviar el comentario: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red al enviar comentario.')),
      );
    }
  }

  // Elimina un comentario propio
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
          _comentarios.removeWhere((c) => c.id == commentId);
        });

        // Verificar si el usuario todavía tiene comentarios para mantener/quitar el color azul
        final bool userStillHasComments = _comentarios.any(
          (c) => c.userId == _currentUserId,
        );

        // Actualizar el contador global en el servicio
        Provider.of<PhotoService>(
          context,
          listen: false,
        ).notificarComentarioEliminado(widget.photo.id, userStillHasComments);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comentario eliminado')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${response.statusCode}')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red al eliminar.')),
      );
    }
  }

  // Mostrar diálogo para reportar la fotografía
  void _mostrarDialogoReporte() {
    String motivoSeleccionado = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar Fotografía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Por qué quieres reportar esta foto? Un administrador revisará tu petición.',
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Motivo del reporte',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (val) {
                motivoSeleccionado = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (motivoSeleccionado.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;

              try {
                await Provider.of<PhotoService>(
                  context,
                  listen: false,
                ).reportarFoto(widget.photo.id, motivoSeleccionado.trim());
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reporte enviado correctamente. Gracias.'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al enviar reporte: $e')),
                );
              }
            },
            child: const Text(
              'Enviar Reporte',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Buscamos la foto más reciente en el servicio (para mantener likes sincronizados)
    // Usamos el nuevo método obtenerFotoPorId que busca en todas las listas
    final photoService = Provider.of<PhotoService>(context);
    final currentPhoto =
        photoService.obtenerFotoPorId(widget.photo.id) ?? widget.photo;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPhoto.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem),
            tooltip: 'Reportar foto',
            onPressed: _mostrarDialogoReporte,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // CARGA DE FOTOGRAFÍA (WIDGET COMPARTIDO)
            // ==========================================
            PhotoItem(photo: currentPhoto, fueraFotografia: false),

            // ==========================================
            // SECCIÓN DE COMENTARIOS
            // ==========================================
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Definimos dónde empiezan los comentarios
                children: [
                  const SizedBox(height: 20),
                  // Texto inicial
                  const Text(
                    "Comentarios",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ==========================================
                  // INPUT DE COMENTARIOS
                  // ==========================================
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Escribe un comentario...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _enviarComentario, // Enviar comentario
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // LISTA DE COMENTARIOS
                  // ==========================================
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        ) // Comprobamos si hay comentarios
                      : _comentarios.isEmpty
                      ? const Text("No hay comentarios aún, sé el primero.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comentarios.length,
                          itemBuilder: (ctx, index) {
                            return ComentarioItem(
                              comentario: _comentarios[index],
                              idUsuarioActual:
                                  _currentUserId, // Pasamos el ID para saber si podemos borrar
                              alBorrar: () => _eliminarComentario(
                                _comentarios[index].id,
                              ), // Lógica de borrado
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
