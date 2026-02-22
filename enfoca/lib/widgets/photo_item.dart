import 'package:flutter/material.dart';
import '../models/fotografia.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../screens/foto_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

// ==========================================
// WIDGET: ITEM DE FOTOGRAFÍA (TARJETA)
// ==========================================

class PhotoItem extends StatelessWidget {
  // ==========================================
  // ATRIBUTOS
  // ==========================================
  final Fotografia photo;
  final bool
  fueraFotografia; // Variable para saber si estoy dentro (detalle) o fuera (feed) de la foto

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  const PhotoItem({
    Key? key,
    required this.photo,
    this.fueraFotografia = true, // Por defecto estará en true (modo feed)
  }) : super(key: key);

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5, // Sombra para darle profundidad
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: fueraFotografia
          ? GestureDetector(
              onTap: () {
                // Navegación al detalle de la foto
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (ctx) => PhotoScreen(photo: photo),
                  ),
                );
              },
              child: _buildCardContent(context),
            )
          : _buildCardContent(
              context,
            ), // En detalle no es "clickable" toda la tarjeta
    );
  }

  // ==========================================
  // MÉTODOS DE CONSTRUCCIÓN AUXILIARES
  // ==========================================

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // IMAGEN PRINCIPAL Y ESTADO VETO
        // ==========================================
        Stack(
          children: [
            Image.network(
              photo.direccionImagen,
              fit: fueraFotografia ? BoxFit.cover : BoxFit.contain,
              height: fueraFotografia ? 250 : 450,
              width: double.infinity,
              errorBuilder: (ctx, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            // Indicador Fotografía Vetada
            if (photo.vetada)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'VETADA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // TÍTULO Y DESCRIPCIÓN
              // ==========================================
              // Título de la imagen
              Text(
                photo.titulo,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Descripción de la imagen
              Text(
                photo.descripcion,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w100),
              ),
              SizedBox(height: 5),

              // ==========================================
              // INFORMACIÓN DEL USUARIO (AVATAR Y NOMBRE)
              // ==========================================
              Row(
                children: [
                  // Avatar con inicial
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      photo.userName.isNotEmpty
                          ? photo.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Nombre del usuario
                  Text(
                    photo.userName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),

              SizedBox(height: 15),

              // ==========================================
              // BARRA DE ACCIONES (LIKES, COMENTARIOS, COMPARTIR)
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // LIKES
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Provider.of<PhotoService>(
                        context,
                        listen: false,
                      ).alternarLike(photo.id);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          photo.likedByUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: photo.likedByUser ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${photo.likesCount}',
                          style: TextStyle(
                            color: photo.likedByUser ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // COMENTARIOS
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // Si estamos fuera (feed), al tocar vamos al detalle
                    onTap: fueraFotografia
                        ? () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (ctx) => PhotoScreen(photo: photo),
                              ),
                            );
                          }
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          photo.comentadoPorUsuario
                              ? Icons.chat_bubble
                              : Icons.chat_bubble_outline,
                          color: photo.comentadoPorUsuario
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${photo.comentariosCount}',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),

                  // COMPARTIR
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final url =
                          'https://enfoca.alwaysdata.net/comentar?fotografia_id=${photo.id}';
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    onLongPress: () {
                      final url =
                          'https://enfoca.alwaysdata.net/comentar?fotografia_id=${photo.id}';
                      Share.share('¡Mira esta foto en Enfoca! $url');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Compartir', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
