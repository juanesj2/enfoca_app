// ==========================================
// MODELO DE DATOS: DESAFÍO / LOGRO
// ==========================================

class Desafio {
  final int id;
  final String titulo;
  final String descripcion;
  final String icono;
  final String? conseguidoEn;

  Desafio({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.conseguidoEn,
  });

  factory Desafio.fromJson(Map<String, dynamic> json) {
    return Desafio(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      icono: json['icono'] ?? '',
      conseguidoEn: json['conseguido_en']?.toString(),
    );
  }

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
