import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_service.dart';
import '../../services/auth_service.dart';
import 'report_details_screen.dart';

// Pantalla para listar y agrupar los reportes de fotografías
class ReportsControlScreen extends StatefulWidget {
  const ReportsControlScreen({super.key});

  @override
  State<ReportsControlScreen> createState() => _ReportsControlScreenState();
}

class _ReportsControlScreenState extends State<ReportsControlScreen> {
  bool _isLoading = false;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    try {
      final photoService = Provider.of<PhotoService>(context, listen: false);
      final rawReports = await photoService.obtenerReportes();

      final Map<int, String> usersMap = {};
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final usersList = await authService.obtenerUsuarios();
        for (var u in usersList) {
          usersMap[u.id] = u.name;
        }
      } catch (_) {
        // En caso de fallar, dejaremos el nombre como "Usuario desconocido" más adelante
      }

      final Map<int, Map<String, dynamic>> groupedReports = {};

      for (var r in rawReports) {
        int fotoId = r['foto_id'];

        int? uId = r['usuario_id'];
        if (uId != null) {
          r['usuario_nombre'] = usersMap[uId] ?? 'Usuario #$uId';
        }

        String fullImageUrl = '';
        if (r['foto'] != null && r['foto']['direccion_imagen'] != null) {
          fullImageUrl =
              'http://enfoca.alwaysdata.net/images/${r['foto']['direccion_imagen']}';
        }

        if (!groupedReports.containsKey(fotoId)) {
          if (fullImageUrl.isEmpty) {
            final fotoExtraida = await photoService.obtenerFotoPorIdApi(fotoId);
            if (fotoExtraida != null) {
              fullImageUrl = fotoExtraida.direccionImagen;
            }
          }

          groupedReports[fotoId] = {
            'foto_id': fotoId,
            'foto_url': fullImageUrl,
            'total_reportes': 0,
            'detalles': [],
          };
        }

        groupedReports[fotoId]!['total_reportes']++;
        groupedReports[fotoId]!['detalles'].add(r);
      }

      setState(() {
        _reports = groupedReports.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _verDetalles(Map<String, dynamic> reportData) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(reportData: reportData),
      ),
    );

    if (result == true) {
      _cargarReportes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comité de Reportes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay reportes pendientes',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 15,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Imagen',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Reportes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Acciones',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: _reports.map((report) {
                    final fotoId = report['foto_id'];
                    final totalReportes = report['total_reportes'];
                    final String fotoUrl = report['foto_url'] ?? '';

                    return DataRow(
                      cells: [
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: fotoUrl.isNotEmpty
                                  ? Image.network(
                                      fotoUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        DataCell(Text('#$fotoId')),
                        DataCell(
                          Text(
                            totalReportes.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        DataCell(
                          ElevatedButton.icon(
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('Ver Detalles'),
                            onPressed: () => _verDetalles(report),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
