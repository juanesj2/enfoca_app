import 'package:flutter/material.dart';
import '../models/comentario.dart';

// ==========================================
// WIDGET: ITEM DE COMENTARIO
// ==========================================
// Este archivo dibuja el diseño visual individual de cada comentario.
// Hereda de `StatelessWidget` porque un comentario, una vez dibujado en pantalla
// (con su texto, fecha y autor), no necesita cambiar su estado interno (no es reactivo por sí solo).

class ComentarioItem extends StatelessWidget {
  // ==========================================
  // ATRIBUTOS (DEPENDENCIAS INYECTADAS)
  // ==========================================

  // Objeto con toda la información JSON convertida que necesitamos pintar.
  final Comentario comentario;

  // ID del usuario que está usando la aplicación ahora mismo.
  // Opcional (puede ser null) si por algún motivo no lo cargamos.
  final int? idUsuarioActual;

  // Una "Función Callback". Es una función que el componente padre (la pantalla)
  // le pasa a este hijo. Si el usuario hace clic en "Borrar", este hijo invocará al padre.
  final VoidCallback? alBorrar;

  // ==========================================
  // CONSTRUCTOR DEL WIDGET
  // ==========================================
  // Todos los widgets reciben un 'Key' opcional para que el motor de Flutter sepa identificarlos en las listas.
  const ComentarioItem({
    Key? key,
    required this.comentario,
    this.idUsuarioActual,
    this.alBorrar,
  }) : super(key: key);

  // ==========================================
  // BUILD (EL PINTOR DE LA ASIGNATURA DE INTERFACES)
  // ==========================================
  // El método 'build' es el corazón de cualquier Widget. Es llamado por Flutter
  // 60 veces por segundo si hay animaciones, devolviendo siempre un "árbol" de widgets visuales.
  @override
  Widget build(BuildContext context) {
    // Usamos 'Card' para darle a cada comentario una pequeña tarjeta flotante con sombra.
    return Card(
      elevation: 2, // Fuerza de la sombra difuminada debajo de la caja
      margin: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 8,
      ), // Márgenes exteriores
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ), // Bordes redondeados
      // 'Padding' le da un margen INTERIOR para que el texto no toque las esquinas grises de la tarjeta.
      child: Padding(
        padding: const EdgeInsets.all(12.0),

        // El 'Column' apila elementos de Arriba hacia Abajo.
        // 1. Cabecera (Avatar + Nombre + Borrar)
        // 2. Separador
        // 3. Texto del comentario
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Alinea el texto a la izquierda
          children: [
            // ==========================================
            // CABECERA DEL COMENTARIO (Fila Horizontal)
            // ==========================================
            // 'Row' alinea sus hijos de Izquierda a Derecha.
            Row(
              children: [
                // 1. Círculo de Avatar usando la inicial del nombre de usuario
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor, // Adopta el color principal de la App (Ej. Morado/Gris según ThemeService)
                  radius: 16,
                  child: Text(
                    // Lógica: Si el nombre tiene texto, cogemos la 1ª letra (`[0]`) y la ponemos en mayúscula.
                    comentario.userName.isNotEmpty
                        ? comentario.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

                // Divisor de espacio fijo
                const SizedBox(width: 8),

                // 2. Nombre del usuario en negrita
                Text(
                  comentario.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, // Negrita
                    fontSize: 14,
                  ),
                ),

                // 3. El Spacer() actúa como un muelle invisible que empuja todo
                // lo que tiene a su izquierda a la izquierda del todo, y lo que tiene
                // a la derecha, al borde derecho de la pantalla.
                const Spacer(),

                // 4. Fecha estructurada (DD/MM/AAAA) extraída formateando la variable DateTime
                Text(
                  _formatearFecha(comentario.fecha),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),

                // ==========================================
                // LÓGICA DE CONDICIONAL IF-DART DENTRO DEL ARRAY
                // ==========================================
                // Flutter nos permite incrustar if's dentro de listas de Widgets.
                // Si nosotros somos el dueño de este comentario, instanciamos mágicamente el cubo de basura (Borrar).
                if (idUsuarioActual != null &&
                    comentario.userId == idUsuarioActual)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    // Al darle click, ejecutamos el código del padre
                    onPressed: alBorrar,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(), // Minimiza el área de toque para que no rompa el diseño
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ==========================================
            // CUERPO: TEXTO DEL COMENTARIO
            // ==========================================
            Text(comentario.contenido, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FUNCIÓN AUXILIAR FORMATO
  // ==========================================
  // Convierte un objeto calendario de Dart completo en una cadenita de texto leíble en España.
  String _formatearFecha(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
