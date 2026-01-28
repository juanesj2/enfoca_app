import 'package:flutter/material.dart';
import '../models/fotografia.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../screens/foto_screen.dart';

class PhotoItem extends StatelessWidget {
  final Fotografia photo;
  final bool
  fueraFotografia; // Variable para saber si estoy dentro o fuera de la foto

  const PhotoItem({
    Key? key,
    required this.photo,
    this.fueraFotografia = true, // Por defecto estara en true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5, // Sombra para que quede más bonito
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: fueraFotografia
          ? GestureDetector(
              onTap: () {
                Future.delayed(Duration.zero, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => PhotoScreen(photo: photo),
                    ),
                  );
                });
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
        // Imagen con bordes redondeados arriba (ya no es necesario el Radius porque el Card recorta)
        Image.network(
          photo.direccionImagen,
          fit: fueraFotografia ? BoxFit.cover : BoxFit.contain,
          height: fueraFotografia ? 250 : 450,
          width: double.infinity,
          errorBuilder: (ctx, error, stackTrace) => Container(
            height: 250,
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titulo de la imagen
              Text(
                photo.titulo,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Descripcio de la imagen
              Text(
                photo.descripcion,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w100),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  // Esto es un avatar con la primera letra del usuario
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      photo.userName[0].toUpperCase(),
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  // Aqui mostramos datos del usuario
                  SizedBox(width: 8),
                  Text(
                    photo.userName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // ********* Likes **********//
                  // ********* Likes **********//
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Provider.of<PhotoService>(
                        context,
                        listen: false,
                      ).alternarLike(photo.id);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // To behave like a button
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
                  // ******** FIN Like ********//

                  // ********* Comentarios **********//
                  // ********* Comentarios **********//
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: fueraFotografia
                        ? () {
                            Future.delayed(Duration.zero, () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => PhotoScreen(photo: photo),
                                ),
                              );
                            });
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

                  // ********* FIN Comentarios **********//
                  // ********* Compartir **********//
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Compartir no implementado aún'),
                        ),
                      );
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
