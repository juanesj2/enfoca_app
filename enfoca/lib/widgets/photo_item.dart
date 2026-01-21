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
      clipBehavior:
          Clip.antiAlias, // Necesario para que el InkWell respete los bordes
      child: InkWell(
        onTap: fueraFotografia
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PhotoScreen(photo: photo),
                  ),
                );
              }
            : null, // Si estamos dentro, no hace nada el tap general
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con bordes redondeados arriba (ya no es necesario el Radius porque el Card recorta)
            // Pero lo mantenemos si el InkWell no recorta childs, pero con clipBehavior en Card sí lo hace.
            // Dejamos el ClipRRect interno por seguridad o lo quitamos?
            // Si el Card tiene clipAntiAlias, todo lo de dentro se recorta.
            // Para simplificar, dejaremos el child tal cual, solo envolviendo en InkWell.
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
                      TextButton.icon(
                        // Usamos un boton con icono
                        onPressed: () {
                          Provider.of<PhotoService>(
                            context,
                            listen: false,
                          ).toggleLike(photo.id);
                        },
                        icon: Icon(
                          photo.likedByUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: photo.likedByUser ? Colors.red : Colors.grey,
                        ),
                        label: Text(
                          '${photo.likesCount}',
                          style: TextStyle(
                            color: photo.likedByUser ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                      // ******** FIN Like ********//

                      // ********* Comentarios **********//
                      TextButton.icon(
                        // Boton con icono
                        // Si el boton de comentar esta "activado" le dejamos hacer cosas
                        onPressed: fueraFotografia
                            ? () {
                                // Al presionar el boton pasan cosas
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => PhotoScreen(photo: photo),
                                  ),
                                );
                              }
                            // Si esta "desactivado" Lo bloqueamos
                            : null,
                        icon: Icon(
                          photo.comentadoPorUsuario
                              ? Icons.chat_bubble
                              : Icons.chat_bubble_outline,
                          color: photo.comentadoPorUsuario
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        label: Text(
                          '${photo.comentariosCount}',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),

                      // ********* FIN Comentarios **********//
                      TextButton.icon(
                        onPressed: () {
                          // Acción de compartir
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Compartir no implementado aún'),
                            ),
                          );
                        },
                        icon: Icon(Icons.share, color: Colors.grey),
                        label: Text(
                          'Compartir',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
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
