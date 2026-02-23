// ==========================================
// MODELO DE DATOS: COMENTARIO
// ==========================================
// Esta clase mapea un "Comentario" individual que un usuario
// escribe debajo de una fotografía dentro de la aplicación.

class Comentario {
  // ==========================================
  // ATRIBUTOS (VARIABLES INMUTABLES)
  // ==========================================
  // Usamos 'final' porque un comentario, una vez descargado de la API
  // y mostrado en pantalla, no cambia sus valores en tiempo real
  // (a menos que lo volvamos a descargar modificado).

  final int id; // Identificador numérico único de este comentario en la BD.
  final String contenido; // El texto literal que escribió el usuario.
  final String
  userName; // El nombre del autor del comentario (extraído del modelo User asociado en Laravel).
  final int
  userId; // El ID numérico del autor. Crucial para saber si el usuario que está usando la app tiene permiso para borrar este comentario.
  final DateTime
  fecha; // Estructura de tiempo avanzada de Dart para guardar exactamente el día, mes, año y hora en que se publicó.

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  // Parámetros obligatorios requeridos (required) para crear un objeto Comentario válido.
  Comentario({
    required this.id,
    required this.contenido,
    required this.userName,
    required this.fecha,
    required this.userId,
  });

  // ==========================================
  // TRANSFORMACIONES JSON (DE RED A OBJETO DART)
  // ==========================================

  // FACTORY: De JSON a Objeto Dart
  // ------------------------------------------
  // Este constructor especial 'factory' toma el mapa (Map) que nos devuelve PHP/Laravel
  // y rellena las variables tipadas de Dart para que Flutter sepa cómo dibujarlas en la UI.
  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      // Asignaciones directas
      id: json['id'],
      contenido: json['contenido'],

      // RELACIONES ANIDADAS (Eloquent With)
      // Como en Laravel hemos hecho un Eager Loading (probablemente `with('user')`),
      // la API nos devuelve el objeto User anidado dentro de este comentario.
      // Así que buscamos `json['user']` y dentro de él pedimos el `['name']`.
      // Si por fallo de red no viene, el operador `??` pone 'Anónimo' en su lugar.
      userName: json['user']['name'] ?? 'Anónimo',
      userId: json['user']['id'],

      // CONVERSIÓN DE FECHAS
      // Laravel devuelve un texto como "2026-02-22T20:00:00.000Z".
      // La variable de Dart espera un objeto `DateTime`.
      // Usamos `DateTime.parse()` para convertir de "texto" a un "objeto Calendario".
      fecha: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(), // Fallback: si falla, usamos la hora actual del dispositivo temporalmente
    );
  }
}
