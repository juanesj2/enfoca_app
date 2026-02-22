import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fotografia.dart';
import '../../services/photo_service.dart';

// ==========================================
// PANTALLA DE CONTROL DE FOTOGRAFÍAS
// ==========================================

class PhotosControlScreen extends StatefulWidget {
  const PhotosControlScreen({super.key});

  @override
  State<PhotosControlScreen> createState() => _PhotosControlScreenState();
}

class _PhotosControlScreenState extends State<PhotosControlScreen> {
  // ==========================================
  // ESTADO
  // ==========================================
  bool _isLoading = false;
  List<Fotografia> _photos = [];

  // ==========================================
  // CICLO DE VIDA
  // ==========================================

  @override
  void initState() {
    super.initState();
    _cargarFotos();
  }

  // ==========================================
  // MÉTODOS PRIVADOS
  // ==========================================

  // Carga todas las fotos
  Future<void> _cargarFotos() async {
    setState(() => _isLoading = true);
    try {
      final photoService = Provider.of<PhotoService>(context, listen: false);
      await photoService.obtenerFotosAdmin();
      setState(() {
        _photos = photoService.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar fotos: $e')));
      }
    }
  }

  // Eliminar foto con confirmación
  Future<void> _eliminarFoto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar fotografía?'),
        content: const Text(
          'Esta acción no se puede deshacer. La foto se borrará permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).eliminarFoto(id);
        await _cargarFotos(); // Recargar lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fotografía eliminada correctamente')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar fotografía: $e')),
          );
        }
      }
    }
  }

  // Mostrar diálogo de edición
  void _mostrarDialogoEdicion(Fotografia photo) {
    String titulo = photo.titulo;
    String descripcion = photo.descripcion;
    bool vetada = photo.vetada;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Fotografía'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ID: ${photo.id}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Usuario: ${photo.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Título'),
                    controller: TextEditingController(text: titulo),
                    onChanged: (val) => titulo = val,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    controller: TextEditingController(text: descripcion),
                    maxLines: 3,
                    onChanged: (val) => descripcion = val,
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('¿Vetada?'),
                    subtitle: const Text('Oculta la foto a los usuarios'),
                    value: vetada,
                    onChanged: (val) {
                      setDialogState(() => vetada = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  _guardarCambiosFoto(photo.id, titulo, descripcion, vetada);
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Guardar cambios de edición
  Future<void> _guardarCambiosFoto(
    int id,
    String titulo,
    String descripcion,
    bool vetada,
  ) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<PhotoService>(
        context,
        listen: false,
      ).editarFoto(id, titulo, descripcion, vetada);
      await _cargarFotos(); // Recargar lista
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotografía actualizada correctamente')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar fotografía: $e')),
        );
      }
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Fotografías')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? const Center(child: Text('No hay fotografías disponibles.'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera de la tarjeta
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
                                'Publicación de: ${photo.userName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Editar'),
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
                                  label: const Text('Eliminar'),
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
                      // Imagen
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: Image.network(
                          photo.direccionImagen,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      // Estado de Veto (si aplica)
                      if (photo.vetada)
                        Container(
                          width: double.infinity,
                          color: Colors.redAccent,
                          padding: const EdgeInsets.all(5),
                          child: const Text(
                            'FOTOGRAFÍA VETADA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // Detalles
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
