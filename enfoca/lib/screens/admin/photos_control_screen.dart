import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fotografia.dart';
import '../../services/photo_service.dart';

// ==========================================
// PANTALLA POLICIAL: CONTROL DE FOTOGRAFÍAS
// ==========================================
// Exclusiva para administradores. Muestra TODAS las fotos del servidor
// (incluso las de usuarios privados) en una lista infinita.
// Permite censurarlas (Vetar), editar sus títulos o ejecutarlas (Eliminar).

class PhotosControlScreen extends StatefulWidget {
  const PhotosControlScreen({super.key});

  @override
  State<PhotosControlScreen> createState() => _PhotosControlScreenState();
}

class _PhotosControlScreenState extends State<PhotosControlScreen> {
  // ==========================================
  // ESTADO INTERNO (STATE)
  // ==========================================
  bool _isLoading = false; // Rueda de carga general
  List<Fotografia> _photos = []; // Depósito masivo de fotos

  // ==========================================
  // CICLO DE VIDA (ARRANQUE)
  // ==========================================

  @override
  void initState() {
    super.initState();
    // Al abrir el inspector, solicitamos el cargamento de forma asíncrona.
    _cargarFotos();
  }

  // ==========================================
  // MÉTODOS DE INTELIGENCIA Y API
  // ==========================================

  // --- OBTENER TODO EL CATALOGO GLOBAL ---
  Future<void> _cargarFotos() async {
    setState(() => _isLoading = true);
    try {
      final photoService = Provider.of<PhotoService>(context, listen: false);
      // Método especial de Admin: Pide al backend TODAS las fotos, no importan permisos.
      await photoService.obtenerFotosAdmin();
      setState(() {
        _photos = photoService.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar archivo global: $e')),
        );
      }
    }
  }

  // --- EJECUCIÓN: BORRAR FOTO (CON DOBLE CONFIRMACIÓN) ---
  Future<void> _eliminarFoto(int id) async {
    // 1. Despliega un Popup de seguridad (Dialog) pidiendo confirmación.
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Ejecutar fotografía?'),
        content: const Text(
          'Esta acción termonuclear no se puede deshacer. Todo rastro desaparecerá.',
        ),
        actions: [
          // Botón Cobarde (Indultar)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          // Botón Ejecutor (Purgar)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desintegrar'),
          ),
        ],
      ),
    );

    // 2. Si el Administrador pulsó "Sí" (true)...
    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        // Orden divina al Servidor
        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).eliminarFoto(id);

        // Recargas el catálogo para ver cómo el hueco desaparece visualmente
        await _cargarFotos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Elemento purgado exitosamente.')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fallo en la desintegración: $e')),
          );
        }
      }
    }
  }

  // --- RE-EDUCACIÓN: EDITAR O VETAR FOTO (MODAL DE INYECTAR DATOS) ---
  void _mostrarDialogoEdicion(Fotografia photo) {
    // Clonación temporal de datos. Si el admin cancela, no estropeamos la clase original.
    String titulo = photo.titulo;
    String descripcion = photo.descripcion;
    bool vetada = photo.vetada;

    // Abrimos un Popup que tiene su propio "State" interno (StatefulBuilder)
    // Esto permite que el switch de "Vetada" se mueva dentro del popup visualmente
    // sin tener que reconstruir la pantalla grande de fondo.
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Censurar o Modificar'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Identificador Único: #${photo.id}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Subido por el ciudadano: ${photo.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Caja 1: Reescribir el Título
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Títular Modificado',
                    ),
                    controller: TextEditingController(text: titulo),
                    onChanged: (val) =>
                        titulo = val, // Actualización en la sombra
                  ),
                  const SizedBox(height: 10),

                  // Caja 2: Reescribir la Descripción
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Descripción Oficial',
                    ),
                    controller: TextEditingController(text: descripcion),
                    maxLines: 3,
                    onChanged: (val) => descripcion = val,
                  ),
                  const SizedBox(height: 20),

                  // Interruptor de Censura Total (Veto)
                  SwitchListTile(
                    title: const Text('¿Censurar en el Muro (Vetar)?'),
                    subtitle: const Text(
                      'Hace invisible la foto para la comunidad normal',
                    ),
                    value: vetada, // ¿Está activo o no?
                    onChanged: (val) {
                      // El setState del POPUP. Hace latir al botón visualmente al instante.
                      setDialogState(() => vetada = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Dejar como estaba'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Destruye el formulario visual
                  // Ejecuta la orden en Laravel usando los datos clonados y modificados
                  _guardarCambiosFoto(photo.id, titulo, descripcion, vetada);
                },
                child: const Text('Imponer Sentencia'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- SUBIENDO LA BUROCRACIA AL SERVIDOR ---
  Future<void> _guardarCambiosFoto(
    int id,
    String titulo,
    String descripcion,
    bool vetada,
  ) async {
    setState(() => _isLoading = true);
    try {
      // API Call a Controlador de Laravel: PhotosController@updateAdmin
      await Provider.of<PhotoService>(
        context,
        listen: false,
      ).editarFoto(id, titulo, descripcion, vetada);

      await _cargarFotos(); // Refrescar mural
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Decreto aplicado al servidor')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Resistencia de la API: $e')));
      }
    }
  }

  // ==========================================
  // ARQUITECTURA VISUAL (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control Policial de Fotografías')),
      // Ternario de estado múltiple:
      // ¿Cargando? -> Peonza azul
      // ¿Sin fotos? -> Mensaje de paz mundial
      // ¿Todo ok? -> ListView con el armamento visual
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? const Center(child: Text('El servidor es una página en blanco.'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];

                // Cada foto se envuelve en una "Tarjeta" (Card) flotante.
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CABECERA GRIS (DATOS Y BOTONES ADMIN) ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Propiedad de: ${photo.userName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Botonera de acciones fatales
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Intervenir'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _mostrarDialogoEdicion(photo),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Purgar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  onPressed: () => _eliminarFoto(photo.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // --- EL CUERPO DEL DELITO (IMAGEN) ---
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        // Descarga y cachea la imagen remota
                        child: Image.network(
                          photo.direccionImagen,
                          fit: BoxFit
                              .cover, // Recorte artístico sin deformaciones
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                      ),

                      // --- SELLO ROJO (SOLO SI ESTÁ PROHIBIDA) ---
                      if (photo.vetada)
                        Container(
                          width: double.infinity,
                          color: Colors.redAccent,
                          padding: const EdgeInsets.all(5),
                          child: const Text(
                            'MATERIAL CENSURADO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // --- METADATOS TÉCNICOS INFERIORES ---
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(photo.descripcion),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
