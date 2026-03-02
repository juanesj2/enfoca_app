// Modelo de Comentario
class Comentario {
  final int id;
  final String contenido;
  final String userName;
  final int userId;
  final DateTime fecha;

  Comentario({
    required this.id,
    required this.contenido,
    required this.userName,
    required this.fecha,
    required this.userId,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      contenido: json['contenido'],
      userName: json['user'] != null
          ? (json['user']['name'] ?? 'Anónimo')
          : 'Anónimo',
      userId: json['user'] != null ? json['user']['id'] : 0,
      fecha: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
