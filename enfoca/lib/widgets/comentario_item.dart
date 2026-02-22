import 'package:flutter/material.dart';
import '../models/comentario.dart';

// ==========================================
// WIDGET: ITEM DE COMENTARIO
// ==========================================

class ComentarioItem extends StatelessWidget {
  // ==========================================
  // ATRIBUTOS
  // ==========================================
  final Comentario comentario;
  final int?
  idUsuarioActual; // ID del usuario actual para verificaciones (ej. borrar)
  final VoidCallback? alBorrar; // Función callback para borrar el comentario

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  const ComentarioItem({
    Key? key,
    required this.comentario,
    this.idUsuarioActual,
    this.alBorrar,
  }) : super(key: key);

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================
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
            // ==========================================
            // CABECERA DEL COMENTARIO
            // ==========================================
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

                // ==========================================
                // BOTÓN DE BORRAR (SOLO SI ES MI COMENTARIO)
                // ==========================================
                if (idUsuarioActual != null &&
                    comentario.userId == idUsuarioActual)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed:
                        alBorrar, // Ejecuta la función de borrado pasada por parámetro
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ==========================================
            // CONTENIDO DEL COMENTARIO
            // ==========================================
            Text(comentario.contenido, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================

  // Método auxiliar para formatear la fecha a DD/MM/AAAA
  String _formatearFecha(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
