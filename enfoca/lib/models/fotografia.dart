// ==========================================
// MODELO DE DATOS: FOTOGRAFÍA
// ==========================================

class Fotografia {
  // ==========================================
  // ATRIBUTOS PRINCIPALES
  // ==========================================

  final int id; // Identificador único de la foto
  final String titulo; // Título de la foto
  final String descripcion; // Descripción detallada
  final String direccionImagen; // URL completa de la imagen
  final int likesCount; // Contador total de likes
  final int comentariosCount; // Contador total de comentarios

  // ==========================================
  // DATOS TÉCNICOS (METADATOS EXIF)
  // ==========================================

  final int? iso; // Sensibilidad ISO
  final String? velocidadObturacion; // Velocidad de obturación (ej. 1/100)
  final double? apertura; // Apertura del diafragma (f/)

  // ==========================================
  // UBICACIÓN (GEOLOCALIZACIÓN)
  // ==========================================

  final double? latitud; // Coordenada: Latitud
  final double? longitud; // Coordenada: Longitud

  // ==========================================
  // INFORMACIÓN DEL AUTOR
  // ==========================================

  final String userName; // Nombre del usuario que subió la foto

  // ==========================================
  // ESTADO DE INTERACCIÓN (USUARIO ACTUAL)
  // ==========================================

  final bool likedByUser; // Indica si el usuario actual le ha dado like
  final bool comentadoPorUsuario; // Indica si el usuario actual ha comentado
  final bool vetada; // Indica si la foto está vetada por un administrador

  // ==========================================
  // CONSTRUCTOR
  // ==========================================

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

  // ==========================================
  // TRANSFORMACIONES JSON (SERIALIZACIÓN)
  // ==========================================

  // Factory para crear una instancia de Fotografía desde el JSON recibido de la API
  factory Fotografia.fromJson(Map<String, dynamic> json) {
    return Fotografia(
      id: json['id'],
      titulo: json['titulo'],
      descripcion:
          json['descripcion'] ?? '', // Manejo de nulos para descripción
      // Construimos la URL manualmente ya que la URL nativa de la API puede venir incompleta
      direccionImagen:
          'http://enfoca.alwaysdata.net/images/${json['direccion_imagen']}',
      likesCount: json['likes_count'],
      comentariosCount: json['comentarios_count'],
      iso: json['ISO'],
      velocidadObturacion: json['velocidad_obturacion'],
      // Conversión segura a double para apertura
      apertura: json['apertura'] != null
          ? double.tryParse(json['apertura'].toString())
          : null,
      // Conversión segura a double para latitud
      latitud: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      // Conversión segura a double para longitud
      longitud: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,
      // Extracción segura del nombre de usuario
      userName: (json['user'] != null && json['user']['name'] != null)
          ? json['user']['name']
          : 'Usuario',
      likedByUser: json['likedByUser'] ?? false,
      comentadoPorUsuario: json['comentadoPorUsuario'] ?? false,
      vetada: json['vetada'] == 1 || json['vetada'] == true,
    );
  }

  // ==========================================
  // MÉTODOS DE UTILIDAD (COPIA INMUTABLE)
  // ==========================================

  // Método para crear una copia de la instancia con algunos valores modificados.
  // Es muy útil para actualizar el estado (ej. al dar like) sin mutar el objeto original.
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
    bool? comentadoPorUsuario, // Argumento opcional para estado de comentario
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
