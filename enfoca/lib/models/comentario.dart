// ==========================================
// MODELO DE DATOS: COMENTARIO
// ==========================================

class Comentario {
  // ==========================================
  // ATRIBUTOS
  // ==========================================

  final int id; // Identificador único del comentario
  final String contenido; // Texto del comentario
  final String userName; // Nombre del usuario que comenta
  final int userId; // ID del usuario para verificar permisos (ej. borrar)
  final DateTime fecha; // Fecha de creación del comentario

  // ==========================================
  // CONSTRUCTOR
  // ==========================================

  Comentario({
    required this.id,
    required this.contenido,
    required this.userName,
    required this.fecha,
    required this.userId,
  });

  // ==========================================
  // TRANSFORMACIONES JSON (SERIALIZACIÓN)
  // ==========================================

  // Factory para crear una instancia de Comentario desde el JSON recibido de la API
  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      contenido: json['contenido'],
      // Si el nombre viene nulo, usamos 'Anónimo' por defecto
      userName: json['user']['name'] ?? 'Anónimo',
      // Obtenemos el ID del usuario anidado dentro del objeto 'user'
      userId: json['user']['id'],
      // Parseamos la fecha. Si es nula, usamos la fecha y hora actual.
      fecha: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
