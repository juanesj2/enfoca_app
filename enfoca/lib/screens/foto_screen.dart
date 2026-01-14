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

class PhotoScreen extends StatefulWidget {
  final Fotografia photo;

  const PhotoScreen({Key? key, required this.photo}) : super(key: key);

  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  // ********** Variables de Estado ********** //
  List<Comentario> _comentarios = []; // Lista local de comentarios
  bool _isLoading = true; // Variable para mostrar el spinner de carga
  int? _currentUserId; // Para saber quién es el usuario actual
  final _commentController =
      TextEditingController(); // Controlador para el input de texto
  // ********** FIN Variables de Estado ********** //

  @override
  void initState() {
    super.initState();
    // Al iniciar, buscamos quien es el usuario y cargamos los comentarios
    _fetchCurrentUser();
    _fetchComentarios();
  }

  // ********** Metodos de API y Logica ********** //

  // Obtiene el usuario actual (Localmente o via API)
  Future<void> _fetchCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return;

    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

    // 1. Intentamos obtener userId de SharedPreferences (optimizado)
    if (extractedUserData.containsKey('userId')) {
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
      print('Error fetching user fallback: $e');
    }
  }

  // Descarga los comentarios del servidor
  Future<void> _fetchComentarios() async {
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
        setState(() {
          _comentarios = comentariosList
              .map((json) => Comentario.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        // Manejar error
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      // Manejar error
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Envia un nuevo comentario al servidor
  Future<void> _submitComment() async {
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
        await _fetchComentarios(); // Recargar comentarios

        // Actualizar el contador global en el servicio (UI Pantalla principal)
        Provider.of<PhotoService>(
          context,
          listen: false,
        ).notifyCommentAdded(widget.photo.id);
      } else {
        // Manejar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al enviar el comentario: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (error) {
      // Manejar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red al enviar comentario.')),
      );
    }
  }

  // Elimina un comentario propio
  Future<void> _deleteComment(int commentId) async {
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
        ).notifyCommentDeleted(widget.photo.id, userStillHasComments);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comentario eliminado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red al eliminar.')),
      );
    }
  }
  // ********** FIN Metodos de API y Logica ********** //

  @override
  Widget build(BuildContext context) {
    // Buscamos la foto más reciente en el servicio (para mantener likes sincronizados)
    final photoService = Provider.of<PhotoService>(context);
    final currentPhoto = photoService.items.firstWhere(
      (element) => element.id == widget.photo.id,
      orElse: () => widget.photo,
    );

    return Scaffold(
      appBar: AppBar(title: Text(currentPhoto.titulo)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ************** Aqui se carga la fotografia (Widget) ************** //
            PhotoItem(photo: currentPhoto, fueraFotografia: false),
            // ******************* FIN carga de la fotografia ******************* //

            // ******************* Carga de los Comentarios ******************* //
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Definimos donde empiezan los comentarios
                children: [
                  const SizedBox(height: 20),
                  // Texto inicial
                  const Text(
                    "Comentarios",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ********** Input de Comentarios ********** //
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
                        onPressed: _submitComment, // Enviar comentario
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),

                  // ********** FIN Input de Comentarios ********** //
                  const SizedBox(height: 20),

                  // ********** Lista de Comentarios ********** //
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        ) // Comprobamos si hay comentarios
                      : _comentarios.isEmpty
                      ? const Text("No hay comentarios aún, se el primero.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comentarios.length,
                          itemBuilder: (ctx, index) {
                            return ComentarioItem(
                              comentario: _comentarios[index],
                              currentUserId:
                                  _currentUserId, // Pasamos el ID para saber si podemos borrar
                              onDelete: () => _deleteComment(
                                _comentarios[index].id,
                              ), // Logica de borrado
                            );
                          },
                        ),
                  // ********** FIN Lista de Comentarios ********** //
                ],
              ),
            ),
            // ****************** FIN General de Comentarios ***************** //
          ],
        ),
      ),
    );
  }
}
