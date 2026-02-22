// MODELO DE DATOS: USUARIO
// ==========================================

import 'desafio.dart';

class User {
  // ==========================================
  // ATRIBUTOS
  // ==========================================

  final int id; // Identificador único del usuario
  final String name; // Nombre de usuario
  final String email; // Correo electrónico
  final String rol; // Rol del usuario (admin, user, etc.)
  final String? avatar; // URL de la foto de perfil (Opcional)
  final bool vetado; // Indica si el usuario está vetado
  final List<Desafio> desafios; // Lista de logros o desafíos completados

  // ==========================================
  // CONSTRUCTOR
  // ==========================================

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.rol,
    this.avatar,
    this.vetado = false,
    this.desafios = const [],
  });

  // ==========================================
  // TRANSFORMACIONES JSON (SERIALIZACIÓN)
  // ==========================================

  // Factory: Crea un objeto User desde un JSON (respuesta de la API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Usuario',
      email: json['email'] ?? '',
      // Estandarizamos absolutamente cualquier valor a 'admin' o 'usuario' para evitar Fallos de aserción (Dropdown)
      rol: _parseRolLimpiado(json['rol']),
      // Mapeo del avatar si estuviera disponible
      avatar: null,
      // Asignamos false por defecto si el campo vetado viene nulo
      vetado:
          json['esta_vetado'] == 1 ||
          json['esta_vetado'] == true ||
          json['vetado'] == 1 ||
          json['vetado'] == true,
      desafios:
          (json['desafios'] as List<dynamic>?)
              ?.map((d) => Desafio.fromJson(d))
              .toList() ??
          [],
    );
  }

  // Sanitiza el string del rol asegurando compatibilidad nativa estricta con los Dropdowns
  static String _parseRolLimpiado(dynamic rolJson) {
    if (rolJson == null) return 'usuario';
    String strNormalizado = rolJson.toString().trim().toLowerCase();
    if (strNormalizado == 'admin') return 'admin';
    return 'usuario'; // Opciones desconocidas, incluyendo 'user' o textos con espacios accidentales, usarán por defecto 'usuario'
  }

  // Convierte el objeto User a JSON (para envíos a la API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'rol': rol,
      'vetado': vetado,
    };
  }
}
