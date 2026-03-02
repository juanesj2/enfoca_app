import 'package:flutter/material.dart';
import '../models/fotografia.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../screens/foto_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

// Widget para mostrar cada foto en la lista
class PhotoItem extends StatelessWidget {
  final Fotografia photo;
  final bool fueraFotografia;

  const PhotoItem({Key? key, required this.photo, this.fueraFotografia = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: fueraFotografia
          ? GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (ctx) => PhotoScreen(photo: photo),
                  ),
                );
              },
              child: _buildCardContent(context),
            )
          : _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
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
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                photo.titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                photo.descripcion,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      photo.userName.isNotEmpty
                          ? photo.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    photo.userName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
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
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
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
