// Modelo para las fotos
class Fotografia {
  final int id;
  final String titulo;
  final String descripcion;
  final String direccionImagen;
  final int likesCount;
  final int comentariosCount;
  final int? iso;
  final String? velocidadObturacion;
  final double? apertura;
  final double? latitud;
  final double? longitud;
  final String userName;
  final bool likedByUser;
  final bool comentadoPorUsuario;
  final bool vetada;

  Fotografia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.direccionImagen,
    required this.likesCount,
    required this.comentariosCount,
    this.iso,
    this.velocidadObturacion,
    this.apertura,
    this.latitud,
    this.longitud,
    required this.userName,
    required this.likedByUser,
    required this.comentadoPorUsuario,
    this.vetada = false,
  });

  factory Fotografia.fromJson(Map<String, dynamic> json) {
    return Fotografia(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'] ?? '',
      direccionImagen:
          'http://enfoca.alwaysdata.net/images/${json['direccion_imagen']}',
      likesCount: json['likes_count'],
      comentariosCount: json['comentarios_count'],
      iso: json['ISO'],
      velocidadObturacion: json['velocidad_obturacion'],
      apertura: json['apertura'] != null
          ? double.tryParse(json['apertura'].toString())
          : null,
      latitud: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,
      userName: (json['user'] != null && json['user']['name'] != null)
          ? json['user']['name']
          : 'Usuario',
      likedByUser: json['likedByUser'] ?? false,
      comentadoPorUsuario: json['comentadoPorUsuario'] ?? false,
      vetada: json['vetada'] == 1 || json['vetada'] == true,
    );
  }

  Fotografia copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? direccionImagen,
    int? likesCount,
    int? comentariosCount,
    int? iso,
    String? velocidadObturacion,
    double? apertura,
    double? latitud,
    double? longitud,
    String? userName,
    bool? likedByUser,
    bool? comentadoPorUsuario,
    bool? vetada,
  }) {
    return Fotografia(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      direccionImagen: direccionImagen ?? this.direccionImagen,
      likesCount: likesCount ?? this.likesCount,
      comentariosCount: comentariosCount ?? this.comentariosCount,
      iso: iso ?? this.iso,
      velocidadObturacion: velocidadObturacion ?? this.velocidadObturacion,
      apertura: apertura ?? this.apertura,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      userName: userName ?? this.userName,
      likedByUser: likedByUser ?? this.likedByUser,
      comentadoPorUsuario: comentadoPorUsuario ?? this.comentadoPorUsuario,
      vetada: vetada ?? this.vetada,
    );
  }
}
