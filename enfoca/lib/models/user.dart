// ==========================================
// MODELO DE DATOS: USUARIO
// ==========================================
// Este archivo representa la estructura de un usuario dentro de nuestra aplicación.
// En Programación Orientada a Objetos (POO), crear un "Modelo" sirve para agrupar
// todas las propiedades que definen a un elemento del mundo real (como un Usuario).

import 'desafio.dart';

class User {
  // ==========================================
  // ATRIBUTOS (VARIABLES DE CLASE)
  // ==========================================
  // Usamos la palabra reservada 'final' porque una vez que creamos el Usuario,
  // sus datos base (como su ID o su nombre) no deberían cambiar repentinamente
  // en memoria sin volver a instanciarlo o actualizarlo a través de la API.

  final int
  id; // Identificador numérico y único del usuario en la base de datos MySQL.
  final String name; // Nombre o seudónimo visible del usuario.
  final String email; // Correo electrónico utilizado para iniciar sesión.
  final String
  rol; // Perfil de permisos del usuario (puede ser 'admin' para administradores o 'usuario' para gente normal).
  final String?
  avatar; // URL de la fotografía de perfil. El símbolo '?' significa que puede ser nulo (null) si no ha subido foto.
  final bool
  vetado; // Verdadero o falso. Si es true (= verdadero), el usuario está silenciado o expulsado y no puede comentar/subir fotos.
  final List<Desafio>
  desafios; // Lista de los retos o logros que el usuario ha conseguido completar en la App.

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  // El constructor es el bloque de código que se ejecuta al intentar crear un "nuevo" Usuario.
  // 'required' nos obliga obligatoriamente a pasarle ese dato o el programa fallará,
  // ya que un usuario no puede existir sin id, nombre, email o rol.
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.rol,
    this.avatar,
    this.vetado =
        false, // Si no decimos nada, por defecto un usuario nuevo jamás estará vetado.
    this.desafios = const [], // Lista vacía por defecto.
  });

  // ==========================================
  // TRANSFORMACIONES JSON (SERIALIZACIÓN)
  // ==========================================

  // FACTORY: De JSON a Objeto Dart
  // ------------------------------------------
  // Las bases de datos y la API de Laravel nos hablan en formato de texto llamado "JSON".
  // Pero Flutter solo entiende objetos "clase User" de Dart. Este método 'fromJson' coge
  // el diccionario de texto JSON entrante y lo transforma en un objeto Dart utilizable.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Extraemos el ID numérico, previniendo errores si viniera como texto.
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      // Extraemos nombre y email, y si de casualidad faltan, ponemos valores por defecto ('Usuario', '')
      name: json['name'] ?? 'Usuario',
      email: json['email'] ?? '',

      // Pasamos el rol por el método privado "_parseRolLimpiado" para asegurar que diga estrictamente
      // 'admin' o 'usuario'. Esto arregla problemas de programación defensiva si en la BD se escribió mal o con espacios.
      rol: _parseRolLimpiado(json['rol']),

      avatar:
          null, // Por ahora el backend/modelo no carga avatares, así que lo forzamos a nulo.
      // Chequeo robusto del campo 'vetado'. Analizamos si el JSON de Laravel trae un 1, un 'true'
      // y también analizamos las traducciones 'esta_vetado' por si acaso hubiera diferencias en la API.
      vetado:
          json['esta_vetado'] == 1 ||
          json['esta_vetado'] == true ||
          json['vetado'] == 1 ||
          json['vetado'] == true,

      // Comprobamos si el JSON incluyó un array de 'desafios'.
      // Si existe, convertimos cada uno de esos minimapas en un objeto de la clase `Desafio`.
      desafios:
          (json['desafios'] as List<dynamic>?)
              ?.map((d) => Desafio.fromJson(d))
              .toList() ??
          [],
    );
  }

  // MÉTODO PRIVADO (Ayudante para limpieza de datos)
  // ------------------------------------------
  // Esta función comprueba lo que recibimos e impide que entre basura (textos raros) al programa.
  // Es estática (static) para no requerir tener un usuario previamente creado para acceder a ella.
  static String _parseRolLimpiado(dynamic rolJson) {
    if (rolJson == null) return 'usuario';
    String strNormalizado = rolJson.toString().trim().toLowerCase();

    // Si la cadena exacta es 'admin', le cedemos permisos. Si es cualquier otra cosa (incluso un error), será 'usuario' raso por seguridad.
    if (strNormalizado == 'admin') return 'admin';
    return 'usuario';
  }

  // MÉTODO JSON: De Objeto Dart a JSON
  // ------------------------------------------
  // Al contrario que el Factory. Cuando queremos mandarle información modificada
  // a nuestro servidor Laravel por Internet, convertimos nuestro "User" en un Mapa de strings JSON comprensible por PHP.
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
