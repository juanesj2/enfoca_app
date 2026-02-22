import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_service.dart';

// ==========================================
// PANTALLA DE DETALLES DE REPORTE
// ==========================================

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailsScreen({super.key, required this.reportData});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  bool _isLoading = false;

  // Acciones: Eliminar Foto (y reportes) o Solo Eliminar Reportes (Indultar)
  Future<void> _procesarAccion(bool eliminarFoto) async {
    setState(() => _isLoading = true);
    final photoService = Provider.of<PhotoService>(context, listen: false);
    final fotoId = widget.reportData['foto_id'];

    try {
      if (eliminarFoto) {
        await photoService.eliminarFoto(fotoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto eliminada correctamente')),
          );
        }
      } else {
        await photoService.eliminarReportes(fotoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reportes eliminados (Foto indultada)'),
            ),
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true para recargar lista
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al procesar acción: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Datos extraídos del objeto reportData
    // La imagen ya llega concatenada en una string en caso de poderse conseguir
    final String fotoUrl = widget.reportData['foto_url'] ?? '';

    final totalReportes = widget.reportData['total_reportes'] ?? 1;
    final List<dynamic> detalles =
        widget.reportData['detalles'] ?? [widget.reportData];

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Reporte')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen Grande
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                            fit: BoxFit
                                .contain, // Ajustado a contain para ver toda la foto
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

                  // Información General
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total de Reportes: $totalReportes',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Esta fotografía ha sido reportada por los siguientes motivos. Revise la imagen y decida si viola las normas de la comunidad.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista de Motivos (Descripciones de los reportes)
                  const Text(
                    'Motivos del Reporte:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    itemBuilder: (context, index) {
                      final reporte = detalles[index];
                      // Dependiendo de si reporta el endpoint motivo o descripción
                      final motivo =
                          reporte['motivo'] ?? 'Motivo no especificado';
                      final reporterName =
                          reporte['usuario_nombre'] ??
                          (reporte['usuario_id'] != null
                              ? 'Usuario #${reporte['usuario_id']}'
                              : 'Desconocido');
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
                          title: Text(motivo),
                          subtitle: Text(
                            'Reportado por $reporterName${fecha.isNotEmpty ? ' el $fecha' : ''}',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Botones de Acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mantener Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () => _procesarAccion(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Eliminar Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () => _procesarAccion(true),
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
