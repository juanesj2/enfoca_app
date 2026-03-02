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

// Pantalla que muestra el detalle de la foto y sus comentarios
class PhotoScreen extends StatefulWidget {
  final Fotografia photo; // Recibimos la obra de arte por parámetro

  const PhotoScreen({Key? key, required this.photo}) : super(key: key);

  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  List<Comentario> _comentarios = [];
  bool _isLoading = true;
  int? _currentUserId;

  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obtenerUsuarioActual();
    _obtenerComentarios();
  }

  // ==========================================
  // LÓGICA DE NEGOCIO Y COMUNICACIONES (API)
  // ==========================================

  // --- OBTENER INQUILINO ACTUAL ---
  Future<void> _obtenerUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return;

    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

    if (extractedUserData.containsKey('userId')) {
      if (!mounted) return;
      setState(() {
        _currentUserId = extractedUserData['userId'];
      });
      return;
    }

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
        final userId = userData['data']['id'];

        if (!mounted) return;
        setState(() {
          _currentUserId = userId;
        });

        extractedUserData['userId'] = userId;
        extractedUserData['userName'] = userData['data']['name'];
        extractedUserData['userEmail'] = userData['data']['email'];
        await prefs.setString('userData', json.encode(extractedUserData));
      }
    } catch (e) {
      debugPrint('Error obteniendo identidad: $e');
    }
  }

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
        final List<dynamic> comentariosList = data['data'];
        if (!mounted) return;

        setState(() {
          _comentarios = comentariosList
              .map((json) => Comentario.fromJson(json))
              .toList();
          _isLoading = false;
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

  // 3. ENVIAR UN NUEVO COMENTARIO
  Future<void> _enviarComentario() async {
    final enteredComment = _commentController.text;

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

      if (response.statusCode == 201 || response.statusCode == 200) {
        _commentController.clear();
        if (!mounted) return;

        await _obtenerComentarios();
        if (!mounted) return;

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

  // 4. ELIMINAR COMENTARIO
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

        final bool userStillHasComments = _comentarios.any(
          (c) => c.userId == _currentUserId,
        );

        Provider.of<PhotoService>(
          context,
          listen: false,
        ).notificarComentarioEliminado(widget.photo.id, userStillHasComments);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu comentario ha sido eliminado.')),
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
        const SnackBar(
          content: Text('Error de red al eliminar el comentario.'),
        ),
      );
    }
  }

  void _mostrarDialogoReporte() {
    String motivoSeleccionado = '';

    // Popup Modal oscuro en medio de la pantalla
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Denunciar Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Indica el motivo por el cual procedes a denunciar esta foto.',
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Motivo',
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
                    content: Text('Reporte enviado correctamente.'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al procesar el reporte: $e')),
                );
              }
            },
            child: const Text(
              'Reportar',
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
            PhotoItem(photo: currentPhoto, fueraFotografia: false),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Comentarios",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Añade un comentario...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _enviarComentario,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _comentarios.isEmpty
                      ? const Text(
                          "Nadie ha comentado todavía.",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comentarios.length,
                          itemBuilder: (ctx, index) {
                            return ComentarioItem(
                              comentario: _comentarios[index],
                              idUsuarioActual: _currentUserId,
                              alBorrar: () =>
                                  _eliminarComentario(_comentarios[index].id),
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
