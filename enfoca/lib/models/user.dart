import 'desafio.dart';

// Modelo de Usuario
class User {
  final int id;
  final String name;
  final String email;
  final String rol;
  final String? avatar;
  final bool vetado;
  final List<Desafio> desafios;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.rol,
    this.avatar,
    this.vetado = false,
    this.desafios = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Usuario',
      email: json['email'] ?? '',
      rol: _parseRolLimpiado(json['rol']),
      avatar: null,
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

  static String _parseRolLimpiado(dynamic rolJson) {
    if (rolJson == null) return 'usuario';
    String strNormalizado = rolJson.toString().trim().toLowerCase();
    if (strNormalizado == 'admin') return 'admin';
    return 'usuario';
  }

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
