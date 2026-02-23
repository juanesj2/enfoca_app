// ==========================================
// MODELO DE DATOS: DESAFÍO / LOGRO
// ==========================================
// Esta clase mapea los logros o retos que el usuario puede desbloquear en la aplicación.

class Desafio {
  // ==========================================
  // ATRIBUTOS (VARIABLES INMUTABLES DE CLASE)
  // ==========================================

  final int
  id; // Número único que identifica el logro en la base de datos (Ej: Logro #1).
  final String titulo; // Nombre descriptivo del logro (Ej: "Primeros Pasos").
  final String
  descripcion; // Explicación de cómo se consigue (Ej: "Has subido tu primera fotografía").
  final String
  icono; // URL, nombre del asset, o código del icono relacionado que enviará el servidor.

  // La variable 'conseguidoEn' es nullable (?) (puede ser null).
  // Esto se debe a que un usuario puede ver la lista de TODOS los logros,
  // incluso los que NO ha conseguido todavía, por lo que no todos tienen fecha de desbloqueo.
  final String? conseguidoEn;

  // ==========================================
  // CONSTRUCTOR
  // ==========================================

  Desafio({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.conseguidoEn, // Opcional por defecto, no lleva "required"
  });

  // ==========================================
  // TRANSFORMACIONES JSON (DE RED A OBJETO DART)
  // ==========================================

  // FACTORY: De JSON a Objeto Dart
  // ------------------------------------------
  // Recibe la respuesta de la Base de Datos en formato Diccionario/JSON de texto dinamicamente tipado,
  // y lo empaqueta limpiamente en un objeto 'Desafio' seguro y tipado en Dart.
  factory Desafio.fromJson(Map<String, dynamic> json) {
    return Desafio(
      // Seguridad ante tipos: comprobamos si el ID en el JSON viene ya como
      // un número (int) o si viene como texto ("1") y hay que intentar transformarlo.
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,

      // Aplicamos el fallback `?? ""` (string vacío) por si algún reto en la BD
      // estuviera corrupto y no tuviera título, descripción, o icono, evitando crasheos visuales.
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      icono: json['icono'] ?? '',

      // Para la fecha, simplemente la transformamos a texto (si existe).
      conseguidoEn: json['conseguido_en']?.toString(),
    );
  }

  // MÉTODO JSON: De Objeto Dart a JSON
  // ------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'icono': icono,
      'conseguido_en': conseguidoEn,
    };
  }
}
