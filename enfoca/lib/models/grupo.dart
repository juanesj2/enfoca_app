import 'user.dart';

class Grupo {
  final int id;
  final String nombre;
  final String? descripcion;
  final String codigoInvitacion;
  final int creadoPor;
  final List<User> usuarios;
  final DateTime createdAt;

  Grupo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.codigoInvitacion,
    required this.creadoPor,
    required this.usuarios,
    required this.createdAt,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    var list = json['usuarios'] as List? ?? [];
    List<User> usuariosList = list.map((i) => User.fromJson(i)).toList();

    return Grupo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre'] ?? 'Grupo',
      descripcion: json['descripcion'],
      codigoInvitacion: json['codigo_invitacion'] ?? '',
      creadoPor: json['creado_por'] is int
          ? json['creado_por']
          : int.tryParse(json['creado_por']?.toString() ?? '0') ?? 0,
      usuarios: usuariosList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'codigo_invitacion': codigoInvitacion,
      'creado_por': creadoPor,
      'usuarios': usuarios.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
