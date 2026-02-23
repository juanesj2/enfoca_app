import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_service.dart';
import '../../services/auth_service.dart';
import 'report_details_screen.dart';

// ==========================================
// TRIBUNAL: MESA DE DENUNCIAS (CONTROL DE REPORTES)
// ==========================================
// Los usuarios reportan fotos que no cumplen las reglas.
// Laravel nos entrega las denuncias "desordenadas" (una por cada click).
// El trabajo MAESTRO de esta pantalla es "Agrupar" todas las denuncias en
// paquetes por foto para que el administrador pueda ver:
// "La foto 5 tiene 8 denuncias juntas".

class ReportsControlScreen extends StatefulWidget {
  const ReportsControlScreen({super.key});

  @override
  State<ReportsControlScreen> createState() => _ReportsControlScreenState();
}

class _ReportsControlScreenState extends State<ReportsControlScreen> {
  // ==========================================
  // MATRIZ DE ESTADO (VARIABLE LOCAL)
  // ==========================================
  bool _isLoading = false;
  // Guardaremos la lista purgada y combinada de expedientes listos.
  List<dynamic> _reports = [];

  // ==========================================
  // INICIO DE INVESTIGACIÓN (INIT)
  // ==========================================

  @override
  void initState() {
    super.initState();
    // Invocamos al Fiscal Automático al abrir el módulo.
    _cargarReportes();
  }

  // ==========================================
  // CEREBRO DE ENJAMBRE (LÓGICA DE DICCIONARIOS)
  // ==========================================

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    try {
      final photoService = Provider.of<PhotoService>(context, listen: false);
      // Descargamos TODAS las actas criminales puras (Sin filtrar)
      final rawReports = await photoService.obtenerReportes();

      // TRUCO DE MEMORIA (CACHÉ LATERAL):
      // Nos traemos el censo completo de todos los ciudadanos registrados
      // Para poder saber cómo se llama el "Policía local ID: 4" sin preguntarle a la DB mil veces.
      final Map<int, String> usersMap = {};
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final usersList = await authService.obtenerUsuarios();
        for (var u in usersList) {
          usersMap[u.id] = u.name; // Diccionario ["ID" -> "Nombre Real"]
        }
      } catch (_) {
        // Tolerancia a fallos: Si la libreta se quema, ponemos 'Usuario Desconocido'
      }

      // ========================================================
      // ALGORITMO DE AGRUPACIÓN Y CLASIFICACIÓN (GROUP BY LOCAL)
      // ========================================================
      // Vamos a agarrar 100 reportes y meterlos en las carpetas correctas por Foto ID.
      final Map<int, Map<String, dynamic>> groupedReports = {};

      for (var r in rawReports) {
        int fotoId = r['foto_id']; // Llave del archivador

        // Cruzamos los datos con nuestra libreta para escribir su nombre real
        int? uId = r['usuario_id'];
        if (uId != null) {
          r['usuario_nombre'] = usersMap[uId] ?? 'Ciudadano #$uId';
        }

        // Construir la URL completa del cuerpo del delito (La imagen de la foto)
        String fullImageUrl = '';
        // A veces Laravel entrega el molde anidado...
        if (r['foto'] != null && r['foto']['direccion_imagen'] != null) {
          fullImageUrl =
              'http://enfoca.alwaysdata.net/images/${r['foto']['direccion_imagen']}';
        }

        // ¿Existe la carpeta para esta Foto_ID en nuestro Mapamundi `groupedReports`?
        if (!groupedReports.containsKey(fotoId)) {
          // NO: Es el primer reporte que leo de esta foto. Nace su carpeta.

          // ... Y si Laravel NO nos dio la imagen embebida, el Juez lanza
          // un helicóptero individual rápido a preguntar al backend de quién es la foto.
          if (fullImageUrl.isEmpty) {
            final fotoExtraida = await photoService.obtenerFotoPorIdApi(fotoId);
            if (fotoExtraida != null) {
              fullImageUrl = fotoExtraida.direccionImagen; // Salvados
            }
          }

          // Creamos el Archivo Oficial para esta Foto (Con sub-array de detalles)
          groupedReports[fotoId] = {
            'foto_id': fotoId,
            'foto_url': fullImageUrl, // Identificación visual firme
            'total_reportes': 0, // Contador oficial a 0 provisional
            'detalles': [], // Las actas literales ("Me pareció ofensivo")
          };
        }

        // SÍ/NO: Sea como sea, aumentamos el castigo total
        groupedReports[fotoId]!['total_reportes']++;
        // Y apilamos el papiro en el sub-array de evidencias.
        groupedReports[fotoId]!['detalles'].add(r);
      }

      // Terminamos. Truncamos el Diccionario a una Lista Plana inyectable en la UI
      setState(() {
        _reports = groupedReports.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- TRANSICIÓN FORENSE ---
  // Cuando el líder pulsa sobre "Ver Detalles", el Juez pasa a una Sala de Deliberación única.
  void _verDetalles(Map<String, dynamic> reportData) async {
    // Escucha atentamente la vuelta. "Ver Detalles" es un Push "Await".
    // La pantalla de detalles puede retornar TRUE si el caso fue cerrado.
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(
          reportData: reportData,
        ), // Transportamos el JSON Completo compilado arriba
      ),
    );

    // Si hubo sangre purgada o indulto global (se hizo algo), recargamos el Juzgado de cero.
    if (result == true) {
      _cargarReportes();
    }
  }

  // ==========================================
  // ARQUITECTURA OFIMÁTICA (TABLA DE DATOS VISUAL)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comité de Quejas Administrativas')),
      // La Mágica Trinidad de Respuestas Visuales
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 1. Ocupado
          : _reports.isEmpty
          ? const Center(
              // 2. Victorioso (Paz Comunitaria)
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
                    'Paz mundial instaurada (0 Casos pendientes)',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          // 3. El Expediente (Sistema estilo Excel Básico "DataTable" de Flutter)
          : SingleChildScrollView(
              // Permanece en Scroll Lateral en pantallas estrechas de móviles pequeños
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                // Scroll natural vertical para infinitas denuncias
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 15,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Imagen a Juicio',
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
                        'Contador Denuncias',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Veredicto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  // Inyección de celdas iterativas (Equivalente al Table Row <tr> HTML)
                  rows: _reports.map((report) {
                    final fotoId = report['foto_id'];
                    final totalReportes = report['total_reportes'];
                    final String fotoUrl = report['foto_url'] ?? '';

                    return DataRow(
                      cells: [
                        DataCell(
                          // Avatar de la Foto Pequeñito Enmarcado (ClipRRect)
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
                                      // Blindaje por si albergara URL corrupta
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
                          // Rojo alarma según número de quejas.
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
                            icon: const Icon(Icons.gavel, size: 16),
                            label: const Text('Abrir Sala de Vistas'),
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
