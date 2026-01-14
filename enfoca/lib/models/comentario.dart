class Comentario {
  // ********** Atributos del Comentario ********** //
  final int id;
  final String contenido;
  final String userName; // Nombre del usuario que comenta
  final int userId; // ID del usuario para verificar permisos (borrar)
  final DateTime fecha;
  // ********** FIN Atributos ********** //

  Comentario({
    required this.id,
    required this.contenido,
    required this.userName,
    required this.fecha,
    required this.userId,
  });

  // ********** Transformaciones JSON ********** //

  // Factory para crear un Comentario desde el JSON de la API
  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      contenido: json['contenido'],
      userName: json['user']['name'] ?? 'Anónimo',
      userId: json['user']['id'], // Obtenemos el ID del usuario anidado
      // Parseamos la fecha, si es nula usamos la actual
      fecha: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
  // ********** FIN Transformaciones JSON ********** //
}
