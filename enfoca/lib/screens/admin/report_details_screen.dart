import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_service.dart';

// Pantalla de detalles de un reporte
class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailsScreen({super.key, required this.reportData});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  bool _isLoading = false;

  Future<void> _procesarAccion(bool eliminarFoto) async {
    setState(() => _isLoading = true);
    final photoService = Provider.of<PhotoService>(context, listen: false);
    final fotoId = widget.reportData['foto_id'];

    try {
      if (eliminarFoto) {
        await photoService.eliminarFoto(fotoId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La fotografía ha sido eliminada.')),
          );
        }
      } else {
        await photoService.eliminarReportes(fotoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte descartado. La fotografía se mantiene.'),
            ),
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la acción: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fotoUrl = widget.reportData['foto_url'] ?? '';
    final totalReportes = widget.reportData['total_reportes'] ?? 1;
    final List<dynamic> detalles =
        widget.reportData['detalles'] ?? [widget.reportData];

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Reportes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            fit: BoxFit.contain,
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

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cantidad de reportes: $totalReportes',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Esta fotografía ha sido reportada por los siguientes motivos. Revise la imagen y decida si eliminarla o conservarla.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Detalles:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    itemBuilder: (context, index) {
                      final reporte = detalles[index];
                      final motivo =
                          reporte['motivo'] ?? 'Sin motivo específico';
                      final reporterName =
                          reporte['usuario_nombre'] ??
                          (reporte['usuario_id'] != null
                              ? 'Usuario #${reporte['usuario_id']}'
                              : 'Usuario desconocido');

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

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Descartar Reportes'),
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
                          label: const Text('Eliminar Fotografía'),
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
