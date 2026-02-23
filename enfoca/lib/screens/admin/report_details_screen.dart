import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_service.dart';

// ==========================================
// SALA DE VISTAS: DETALLES DE UNA DENUNCIA
// ==========================================
// Tras pulsar "Ver Detalles" en la tabla anterior, llegamos aquí.
// Esta pantalla disecciona UNA sola foto, y despliega todos
// los motivos exactos por los que distintos usuarios se han quejado de ella.

class ReportDetailsScreen extends StatefulWidget {
  // El "Expediente Policial" empaquetado que fabricamos en la pantalla anterior.
  // Contiene la URL de la foto, y un array dentro con todas las quejas.
  final Map<String, dynamic> reportData;

  const ReportDetailsScreen({super.key, required this.reportData});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  // Rueda de espera para acciones destructivas.
  bool _isLoading = false;

  // ==========================================
  // MARTILLAZO DEL JUEZ (ACCIONES FINALES)
  // ==========================================
  // Parámetro "eliminarFoto":
  // TRUE = Ejecutar a la foto. FALSE = Archivar el caso por falsa alarma.
  Future<void> _procesarAccion(bool eliminarFoto) async {
    setState(() => _isLoading = true);
    final photoService = Provider.of<PhotoService>(context, listen: false);
    final fotoId =
        widget.reportData['foto_id']; // Extracción de la clave forense

    try {
      if (eliminarFoto) {
        // --- SENTENCIA DE MUERTE ---
        // Borrar la foto destruye por cascada (en Laravel) todos los reportes,
        // comentarios, y likes asociados a ella.
        await photoService.eliminarFoto(fotoId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La fotografía ha sido desintegrada.'),
            ),
          );
        }
      } else {
        // --- INDULTO ---
        // La foto se queda viva, pero borramos (quemamos) todo el papeleo de quejas
        // de la base de datos para que no siga saliendo en "Administrar Reportes".
        await photoService.eliminarReportes(fotoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carpeta archivada. Se perdonó a la fotografía.'),
            ),
          );
        }
      }
      if (mounted) {
        // Volvemos a la pantalla anterior.
        // OJO: Retornamos "true" como si fuera un telegrama.
        // Esto le avisa a la tabla anterior (ReportsControlScreen) que DEBE
        // recargar sus datos de internet, porque hemos matado un elemento.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Colapso en la sentencia judicial: $e')),
        );
      }
    }
  }

  // ==========================================
  // ARQUITECTURA VISUAL (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------------------------------
    // FASE DE AUTOPSIA: Diseccionamos el Json
    // -----------------------------------------------------------------

    // 1. Extraemos el Identificador Visual (URL Absoluta lista para usarse)
    final String fotoUrl = widget.reportData['foto_url'] ?? '';

    // 2. ¿Cuánta gente se ha quejado?
    final totalReportes = widget.reportData['total_reportes'] ?? 1;

    // 3. Extracción manual de las sentencias escritas (Motivos literales)
    // El doble condicional es por seguridad ante estructuras malformadas.
    final List<dynamic> detalles =
        widget.reportData['detalles'] ?? [widget.reportData];

    return Scaffold(
      appBar: AppBar(title: const Text('Auditoría Forense')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // ZONA 1: LA EVIDENCIA (FOTO EN GRANDE)
                  // ==========================================
                  // Usamos "contain" para no recortarla y poder ver cada píxel en detalle.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Bordes redondeados sutiles
                    child: fotoUrl.isEmpty
                        ? Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          )
                        : Image.network(
                            fotoUrl,
                            width: double.infinity,
                            fit: BoxFit.contain, // Modalidad lupa anatómica
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // ZONA 2: INFORME RESUMEN
                  // ==========================================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acusaciones acumuladas: $totalReportes',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Esta fotografía ha sido reportada por los siguientes motivos. Revise la imagen y dicte sentencia como Administrador Supremo de moderación de convivencia.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // ZONA 3: LISTADO DE DECLARACIONES LEYENDO EL JSON
                  // ==========================================
                  const Text(
                    'Declaraciones Literales:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Iteramos el sub-array de detalles usando ListView integrado
                  ListView.builder(
                    shrinkWrap:
                        true, // Para que el padre determine el tamaño, no la lista
                    physics:
                        const NeverScrollableScrollPhysics(), // Evita choque de scrolls (Lista contra Página)
                    itemCount: detalles.length,
                    itemBuilder: (context, index) {
                      final reporte =
                          detalles[index]; // Fila de la Base de Datos concreta

                      // Minería de Json por Clave
                      final motivo = reporte['motivo'] ?? 'Ausencia de alegato';

                      // ¿Tenemos el String del nombre cacheado, o solo el Int del ID duro?
                      final reporterName =
                          reporte['usuario_nombre'] ??
                          (reporte['usuario_id'] != null
                              ? 'Ciudadano Identificador #${reporte['usuario_id']}'
                              : 'Voz Fantasma (Null)');

                      // Parser asqueroso de fechar (Corta la "T" que manda SQL)
                      // Ejemplo SQL: 2024-11-05T08:33:00 -> Resultado: 2024-11-05
                      final fechaStr = reporte['created_at'];
                      final fecha = fechaStr != null
                          ? fechaStr.toString().split('T').first
                          : '';

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          title: Text(motivo), // El Grito en el Cielo
                          subtitle: Text(
                            'Reportado por $reporterName${fecha.isNotEmpty ? ' en el ciclo solar de $fecha' : ''}',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // ==========================================
                  // ZONA 4: PANEL DE BOTONES (VEREDICTO)
                  // ==========================================
                  Row(
                    children: [
                      // Botón Vida (Indulto Excepcional)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Indultar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green, // Código civil verde militar
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () =>
                              _procesarAccion(false), // Acción "Save"
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón Muerte (Ejecución Forense)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Sentenciar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red, // Código purga rojo escarlata
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () =>
                              _procesarAccion(true), // Acción "Kill"
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
