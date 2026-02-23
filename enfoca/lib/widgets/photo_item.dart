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
// Este archivo dibuja una fotografía completa dentro del Feed principal.
// Gestiona el dibujo de la imagen interactiva, los Likes (conectándose usando Provider),
// y los enlaces para compartir mediante el portapapeles o redes sociales.

class PhotoItem extends StatelessWidget {
  // ==========================================
  // ATRIBUTOS (INYECCIÓN DE DEPENDENCIAS)
  // ==========================================

  // El modelo de datos con toda la información de la imagen.
  final Fotografia photo;

  // Variable booleana crucial para reutilizar código.
  // 'true' = La foto está en la cuadrícula infinita del Feed (Se puede hacer clic para abrirla).
  // 'false' = La foto ya está abierta a pantalla completa (No debe ser clickable).
  final bool fueraFotografia;

  // ==========================================
  // CONSTRUCTOR DEL WIDGET
  // ==========================================
  // Requerimos la Fotografía obligatoriamente para existir.
  const PhotoItem({
    Key? key,
    required this.photo,
    this.fueraFotografia =
        true, // Por defecto siempre asumimos que está en el Feed normal
  }) : super(key: key);

  // ==========================================
  // MÉTODOS DE CONSTRUCCIÓN (BUILD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Retornamos un Card, que es un Widget nativo de Material Design para
    // encapsular contenido en una caja con bordes redondeados y sombra.
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5, // Sombra para darle profundidad óptica 3D contra el fondo
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

      // LÓGICA TERNARIA (Navegación Táctil)
      // Si `fueraFotografia` es true, envolvemos el contenido en un GestureDetector
      // para que al tocar la tarjeta entera, viajemos a la pantalla de Detalle.
      child: fueraFotografia
          ? GestureDetector(
              onTap: () {
                // El enrutador `Navigator.push` nos mete dentro de la pantalla `PhotoScreen`.
                // `rootNavigator: true` asegura que la navegación cubra todo, tapando incluso la barra inferior de pestañas.
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
            ), // Si ya estamos en el detalle, pintamos sin hacer bloque táctil
    );
  }

  // ==========================================
  // MÉTODOS DE CONSTRUCCIÓN AUXILIARES (UI PRIVADA)
  // ==========================================
  // Separamos el diseño interior en una función para no escribir lo mismo 2 veces arriba en el IF-Ternario.

  Widget _buildCardContent(BuildContext context) {
    // La columna principal apila verticalmente: (1) La Foto y (2) El área blanca de Texto
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // 1. ZONA SUPERIOR: IMAGEN PRINCIPAL Y ETIQUETAS
        // ==========================================
        // Usamos un 'Stack' (Pila de capas). Permite dibujar cosas unas encima de otras,
        // como Photoshop. La capa Base [0] es la foto, y la capa [1] puede ser el aviso rojo de VETO.
        Stack(
          children: [
            // Dibuja la imagen descargándola dinámicamente desde Internet
            Image.network(
              photo.direccionImagen,

              // Ajuste focal: Si estamos en el feed, la estiramos forzadamente para rellenar (cover).
              // Si estamos en el detalle, dejamos que respire mostrando bordes negros si hace falta (contain).
              fit: fueraFotografia ? BoxFit.cover : BoxFit.contain,
              height: fueraFotografia ? 250 : 450,
              width: double.infinity, // Ocupa todo el ancho posible en pantalla
              // Si la descarga falla (cuelgue de servidor o mala red), pintamos un bloque gris.
              errorBuilder: (ctx, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),

            // CAPA 2 (Condicional): Indicador Fotografía Vetada
            if (photo.vetada)
              // `Positioned` solo funciona dentro de un `Stack`. Lo anclamos a 10px de arriba y la derecha.
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
                    mainAxisSize: MainAxisSize
                        .min, // La caja se encoge al contenido exacto del texto
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

        // ==========================================
        // 2. ZONA INFERIOR: TEXTO Y BOTONERA
        // ==========================================
        Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // TÍTULO Y DESCRIPCIÓN
              // ==========================================
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
                ), // w100 es fuente delgada
              ),
              const SizedBox(height: 5),

              // ==========================================
              // INFORMACIÓN DEL AUTOR (AVATAR Y NOMBRE)
              // ==========================================
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

              // ==========================================
              // BARRA DE INTERACCIÓN LATERAL MÚLTIPLE
              // ==========================================
              // SpaceAround reparte equitativamente el espacio vacío entre los tres iconos (Likes/Comments/Share)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // ==========================
                  // BOTÓN Y LÓGICA DE 'LIKES'
                  // ==========================
                  GestureDetector(
                    // HitTestBehavior.opaque soluciona que si clicas en el espacio blanco entre el Corazón y el Número, el toque se registre satisfactoriamente.
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // LLAMADA AL PROVIDER:
                      // Vamos al árbol global de estado con `Provider.of` sin escucharlo re-dibujarse a sí mismo (`listen: false`)
                      // Le ordenamos a Laravel enviar o quitar el 'Like' por Internet mediante `PhotoService`.
                      Provider.of<PhotoService>(
                        context,
                        listen: false,
                      ).alternarLike(photo.id);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pintado dinámico del corazón
                        Icon(
                          photo.likedByUser
                              ? Icons
                                    .favorite // Corazón lleno
                              : Icons.favorite_border, // Corazón vacío
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

                  // =============================
                  // ACCESO DIRECTO A COMENTARIOS
                  // =============================
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
                        : null, // Si ya estoy dntro de la foto, este botón en la botonera no hace nada.
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

                  // ==========================
                  // SISTEMA DE COMPARTICIÓN NATIVA
                  // ==========================
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,

                    // ON-TAP (Toque Simple): Copia mágicamente el recíproco URL al portapapeles invisible del propio Teléfono (Clipboard).
                    onTap: () {
                      final url =
                          'https://enfoca.alwaysdata.net/comentar?fotografia_id=${photo.id}';
                      Clipboard.setData(ClipboardData(text: url));

                      // Mostramos un mensajito negro flotante abajo ("SnackBar") por 2 segundos indicándole que ya se copió.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },

                    // ON-LONG-PRESS (Mantener Dedo): Abre la ventana de Android/iOS estándar (WhatsApp, Telegram...) usando el Plugin "Share".
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
