// ==========================================
// MODELO DE DATOS: GRUPO
// ==========================================
// Esta clase representa a los Grupos sociales dentro de la aplicación.
// Los usuarios pueden agruparse mediante un "código de invitación" para competir entre ellos.

import 'user.dart';

class Grupo {
  // ==========================================
  // ATRIBUTOS
  // ==========================================

  final int id; // Identificación numérica del grupo en MySQL
  final String
  nombre; // Nombre público del grupo (P. ej: "Fotógrafos de Sevilla")
  final String? descripcion; // Detalles opcionales del propósito del grupo
  final String
  codigoInvitacion; // Clave de 6 letras que se pasa a los amigos para unirse
  final int
  creadoPor; // Almacena el ID numérico (User ID) de la persona dueña/creadora del grupo

  // RELACIÓN ELOQUENT EN DART
  // -------------------------
  // Representa todos los usuarios que están metidos en este grupo.
  // Es una "Lista" de objetos de la clase "User". Mapea una relación "Muchos a Muchos" de la BD.
  final List<User> usuarios;

  final DateTime createdAt; // Fecha en la que se fundó el grupo

  // ==========================================
  // CONSTRUCTOR
  // ==========================================

  Grupo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.codigoInvitacion,
    required this.creadoPor,
    required this.usuarios,
    required this.createdAt,
  });

  // ==========================================
  // TRANSFORMACIONES JSON (DE RED A OBJETO DART)
  // ==========================================

  factory Grupo.fromJson(Map<String, dynamic> json) {
    // 1. ANÁLISIS DE LA LISTA DE USUARIOS
    // Verificamos si la respuesta del backend contiene un arreglo llamado 'usuarios'.
    // Si la lista está vacía o es nula, creamos una lista vacía por defecto [] para no crashear.
    var list = json['usuarios'] as List? ?? [];

    // Convertimos cada iteración del array JSON en una clase User estructurada
    // llamando repetidamente al propio factorizador de `User.fromJson(i)`.
    List<User> usuariosList = list.map((i) => User.fromJson(i)).toList();

    return Grupo(
      // Parsing robusto del ID garantizando un numérico seguro
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      // Valores de texto
      nombre: json['nombre'] ?? 'Grupo',
      descripcion:
          json['descripcion'], // Puede ser nulo, por lo que no usamos fallback
      codigoInvitacion: json['codigo_invitacion'] ?? '',

      // Asegurando el ID del creador
      creadoPor: json['creado_por'] is int
          ? json['creado_por']
          : int.tryParse(json['creado_por']?.toString() ?? '0') ?? 0,

      // Asignamos la lista estandarizada que generamos arriba
      usuarios: usuariosList,

      // Parseando fechas al estándar Dart `DateTime`
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ==========================================
  // EXPORTANDO A JSON
  // ==========================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'codigo_invitacion': codigoInvitacion,
      'creado_por': creadoPor,

      // De Dart a Json: Recorremos la Lista de usuarios instanciados
      // y ordenamos que cada uno ejecute su propio método `.toJson()` individual.
      'usuarios': usuarios.map((e) => e.toJson()).toList(),

      // Serializando fecha estricta para HTTP
      'created_at': createdAt.toIso8601String(),
    };
  }
}
