import 'package:flutter/material.dart';
import '../models/comentario.dart';

class ComentarioItem extends StatelessWidget {
  final Comentario comentario;
  final int? idUsuarioActual; // ID del usuario actual para verificaciones
  final VoidCallback? alBorrar; // Funcion callback para borrar el comentario

  const ComentarioItem({
    Key? key,
    required this.comentario,
    this.idUsuarioActual,
    this.alBorrar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // Sombra suave
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ********** Cabecera del Comentario (Avatar, Nombre, Fecha, Borrar) ********** //
            Row(
              children: [
                // Avatar con inicial
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 16,
                  child: Text(
                    comentario.userName.isNotEmpty
                        ? comentario.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),

                // Nombre de usuario
                Text(
                  comentario.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const Spacer(), // Empuja el contenido a la derecha
                // Fecha formateada
                Text(
                  _formatearFecha(comentario.fecha),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),

                // ********** Boton de Borrar (Solo si es mi comentario) ********** //
                if (idUsuarioActual != null &&
                    comentario.userId == idUsuarioActual)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed:
                        alBorrar, // Ejecuta la funcion de borrado pasada por parametro
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                // ********** FIN Boton de Borrar ********** //
              ],
            ),

            // ********** FIN Cabecera del Comentario ********** //
            const SizedBox(height: 8),

            // ********** Contenido del Comentario ********** //
            Text(comentario.contenido, style: const TextStyle(fontSize: 14)),
            // ********** FIN Contenido del Comentario ********** //
          ],
        ),
      ),
    );
  }

  // Metodo auxiliar para formatear la fecha a DD/MM/AAAA
  String _formatearFecha(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
