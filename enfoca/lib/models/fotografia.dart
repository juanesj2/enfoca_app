// ==========================================
// MODELO DE DATOS: FOTOGRAFÍA
// ==========================================
// Esta clase mapea una imagen subida por los usuarios a la red social,
// incluyendo tanto la información visual como sus metadatos (EXIF) y estadísticas.

class Fotografia {
  // ==========================================
  // ATRIBUTOS PRINCIPALES (Obligatorios)
  // ==========================================
  // Propiedades básicas que toda fotografía debe tener para poder ser dibujada en pantalla.

  final int
  id; // Identificador numérico único de la foto en la base de datos primaria
  final String
  titulo; // Título o nombre corto que el usuario le asignó a la captura
  final String descripcion; // Texto largo detallando qué ocurre en la imagen
  final String
  direccionImagen; // URL completa de red absoluta hacia el archivo .jpg/.png en el servidor
  final int
  likesCount; // Total acumulado de "Me gustas" dados por toda la comunidad
  final int
  comentariosCount; // Total de comentarios escritos debajo de esta imagen

  // ==========================================
  // DATOS TÉCNICOS (METADATOS EXIF)
  // ==========================================
  // Estos datos son extraídos silenciosamente del archivo de imagen cuando el usuario
  // dispara con su cámara. Son opcionales (nullable '?') ya que no todas las fotos
  // descargadas de internet conservan su metadata EXIF intacta.

  final int?
  iso; // Sensibilidad del sensor de la cámara (ISO). Ej: 100, 400, 3200.
  final String?
  velocidadObturacion; // Tiempo que el obturador estuvo abierto (Ej. "1/1000", "2s").
  final double?
  apertura; // Nivel de apertura del diafragma de la lente (f/). Numérico flotante.

  // ==========================================
  // UBICACIÓN (GEOLOCALIZACIÓN)
  // ==========================================
  // Posición GPS codificada donde se tomó la foto, para poder mostrarla en el Mapa Mundial.

  final double? latitud; // Coordenada de Latitud (Norte/Sur)
  final double? longitud; // Coordenada de Longitud (Este/Oeste)

  // ==========================================
  // INFORMACIÓN DEL AUTOR
  // ==========================================

  final String
  userName; // Nombre del usuario creador para atribuirle crédito visual

  // ==========================================
  // ESTADO DE INTERACCIÓN (RELATIVO AL USUARIO ACTUAL)
  // ==========================================
  // Estas variables no son de la foto en sí, sino de la *relación* entre la foto y la persona
  // que está usando la app ahora mismo mirando la pantalla.

  final bool
  likedByUser; // 'true' si NOSOTROS le hemos dado 'Me Gusta'. Sirve para pintar el corazón rojo.
  final bool
  comentadoPorUsuario; // 'true' si NOSOTROS hemos escrito algún comentario aquí.
  final bool
  vetada; // 'true' si un administrador silenció o baneó esta foto por contenido inapropiado.

  // ==========================================
  // CONSTRUCTOR DEL MODELO
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
  // TRANSFORMACIONES JSON (DE LA RED A LA APP)
  // ==========================================

  // Factory: Este método se convierte en una fábrica que ensambla objetos `Fotografia`
  // absorbiendo la amalgama de datos crudos (JSON) que el Servidor Web (Laravel) devuelve.
  factory Fotografia.fromJson(Map<String, dynamic> json) {
    return Fotografia(
      id: json['id'],
      titulo: json['titulo'],
      descripcion:
          json['descripcion'] ??
          '', // Fallback seguro para evitar roturas locales si es nulo
      // CONSTRUCCIÓN DE LA URL
      // El backend almacena típicamente rutas relativas (ej: 'posts/mi_foto.jpg').
      // Aquí concatenamos el dominio para que el widget Image.network de Flutter sepa dónde apuntar.
      direccionImagen:
          'http://enfoca.alwaysdata.net/images/${json['direccion_imagen']}',

      likesCount: json['likes_count'],
      comentariosCount: json['comentarios_count'],

      iso: json['ISO'],
      velocidadObturacion: json['velocidad_obturacion'],

      // DOUBLE PARSERS
      // Es muy común que las APIs devuelvan números decimales (doubles) como cadenas mágicas ("2.5").
      // Usamos `double.tryParse` para forzar su traducción a un tipo numérico matemático en la RAM del móvil.
      apertura: json['apertura'] != null
          ? double.tryParse(json['apertura'].toString())
          : null,
      latitud: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,

      // OBTENCIÓN DE NOMBRES ANIDADOS
      // Miramos si dentro del diccionario de la foto, hay un diccionario de 'user' inyectado
      userName: (json['user'] != null && json['user']['name'] != null)
          ? json['user']['name']
          : 'Usuario',

      likedByUser: json['likedByUser'] ?? false,
      comentadoPorUsuario: json['comentadoPorUsuario'] ?? false,
      vetada: json['vetada'] == 1 || json['vetada'] == true,
    );
  }

  // ==========================================
  // MÉTODOS DE UTILIDAD EN PROGRAMACIÓN FUNCIONAL
  // ==========================================

  // MÉTODO PATRÓN COPY-WITH (Copia Modificada)
  // ------------------------------------------
  // En Dart es una mala práctica mutar (cambiar directamente) las variables de un objeto existente (ej. foto.likesCount = 5).
  // En su lugar, cuando alguien da Like, usamos este método para crear un "CLON EXACTO" entero de la foto,
  // pero alterando exclusivamente las propiedades que le pasemos por parámetro (como sumarle 1 al contador).
  // Esto hace que las reconstrucciones de interfaz en Flutter sean extremadamentes rápidas de comparar y seguras.
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
      // Por cada variable usamos el operador ?? (If Null).
      // Significa: "Si el clonador me envió un nuevo 'id', pon el nuevo. Si no, usa el 'this.id' que yo ya tenía".
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
