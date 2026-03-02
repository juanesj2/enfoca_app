import 'package:flutter/material.dart';
import '../models/comentario.dart';

// Widget para mostrar un comentario individual
class ComentarioItem extends StatelessWidget {
  final Comentario comentario;
  final int? idUsuarioActual;
  final VoidCallback? alBorrar;

  const ComentarioItem({
    Key? key,
    required this.comentario,
    this.idUsuarioActual,
    this.alBorrar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                Text(
                  comentario.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatearFecha(comentario.fecha),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (idUsuarioActual != null &&
                    comentario.userId == idUsuarioActual)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: alBorrar,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comentario.contenido, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
