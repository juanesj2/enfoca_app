class User {
  // ********** Atributos del Usuario ********** //
  final int id;
  final String name;
  final String email;
  final String? avatar; // URL de la foto de perfil si la tuviera (Opcional)
  // ********** FIN Atributos ********** //

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  // ********** Transformaciones JSON ********** //

  // Factory: Crea un User desde un JSON (lo que devuelve la API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      // Si en el futuro añades avatar a la API, lo mapeas aquí
      avatar: null,
    );
  }

  // Convierte el User a JSON (por si necesitamos enviarlo de vuelta)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }

  // ********** FIN Transformaciones JSON ********** //
}
