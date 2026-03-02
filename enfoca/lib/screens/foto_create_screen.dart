import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Librería estelar para acceder a Cámara/Galería
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; // Librería estelar para satélites GPS

import 'package:latlong2/latlong.dart';
import '../services/photo_service.dart';
import 'map_selection_screen.dart';

// Pantalla para crear una nueva publicación con foto y detalles.

class FotoCreateScreen extends StatefulWidget {
  // Alias de enrutamiento interno
  static const routeName = '/foto-create';

  // Callback ejecutado al subir la foto con éxito.
  final VoidCallback? onPhotoUploaded;

  const FotoCreateScreen({super.key, this.onPhotoUploaded});

  @override
  _FotoCreateScreenState createState() => _FotoCreateScreenState();
}

class _FotoCreateScreenState extends State<FotoCreateScreen> {
  // Clave del formulario para validación.
  final _formKey = GlobalKey<FormState>();

  // ==========================================
  // ESTADO INTERNO (VARIABLES DE RECOLECCIÓN)
  // ==========================================

  // --- Metadatos de la foto ---
  String _titulo = '';
  String _descripcion = '';
  // --- Metadatos técnicos (Opcionales) ---
  int? _iso;
  String? _velocidadObturacion;
  double? _apertura;
  // --- 3. Posicionamiento Global ---
  double? _latitud;
  double? _longitud;

  // --- Archivo de imagen ---
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // --- Estado de la interfaz ---
  bool _isLoading = false;
  bool _isGettingLocation = false;

  // Controladores de texto para las coordenadas.
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // ==========================================
  // CICLO DE VIDA
  // ==========================================

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ==========================================
  // LÓGICA DE NEGOCIO
  // ==========================================

  // 1. SELECCIONAR IMAGEN
  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar la imagen: $e')),
      );
    }
  }

  // 2. OBTENER UBICACIÓN ACTUAL
  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Activa los permisos de ubicación en los ajustes del sistema.',
            ),
          ),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _latController.text = _latitud.toString();
        _lngController.text = _longitud.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  // 3. SELECCIONAR UBICACIÓN EN MAPA
  Future<void> _seleccionarUbicacionEnMapa() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (ctx) =>
            MapSelectionScreen(initialLat: _latitud, initialLng: _longitud),
      ),
    );

    if (result != null) {
      setState(() {
        _latitud = result.latitude;
        _longitud = result.longitude;
        _latController.text = _latitud.toString();
        _lngController.text = _longitud.toString();
      });
    }
  }

  // 4. ENVIAR FORMULARIO
  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una imagen para la publicación'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<PhotoService>(context, listen: false).crearFoto(
        _pickedImage!,
        _titulo,
        _descripcion,
        latitud: _latitud,
        longitud: _longitud,
        iso: _iso,
        velocidadObturacion: _velocidadObturacion,
        apertura: _apertura,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicación creada con éxito!')),
      );

      if (widget.onPhotoUploaded != null) {
        widget.onPhotoUploaded!();
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al publicar: $error')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // RENDERIZADO VISUAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Publicación')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SELECTOR DE IMAGEN ---
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Tomar Foto Directa'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _seleccionarImagen(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Explorar Galería'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _seleccionarImagen(ImageSource.gallery);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: _pickedImage != null
                            ? Image.file(
                                _pickedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Toca para añadir una imagen',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- DATOS BÁSICOS ---
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Título'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Introduce un título para la foto.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _titulo = value!;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Descripción (Opcional)',
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      onSaved: (value) {
                        _descripcion = value ?? '';
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- UBICACIÓN ---
                    const Text(
                      'Ubicación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _latitud != null
                                ? '${_latitud!.toStringAsFixed(4)}, ${_longitud!.toStringAsFixed(4)}'
                                : 'Sin coordenadas',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        if (_isGettingLocation)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.my_location),
                                label: const Text('Triangular Aquí'),
                                onPressed: _obtenerUbicacionActual,
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.map),
                                label: const Text('Clavar en Mapa'),
                                onPressed: _seleccionarUbicacionEnMapa,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const Divider(),

                    // --- DATOS TÉCNICOS ---
                    const Text(
                      'Datos fotográficos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'ISO Sensitivy',
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _iso = int.tryParse(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Diafragma (f/)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Obligatorio';
                              }
                              final sanitized = value
                                  .toLowerCase()
                                  .replaceAll('f', '')
                                  .replaceAll('/', '')
                                  .replaceAll(' ', '')
                                  .replaceAll(',', '.');

                              if (double.tryParse(sanitized) == null) {
                                return 'Formato inválido (ej: 2.8)';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                final sanitized = value
                                    .toLowerCase()
                                    .replaceAll('f', '')
                                    .replaceAll('/', '')
                                    .replaceAll(' ', '')
                                    .replaceAll(',', '.');
                                _apertura = double.tryParse(sanitized);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Velocidad de Obturación',
                      ),
                      onSaved: (value) {
                        _velocidadObturacion = value;
                      },
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _enviarFormulario,
                      child: const Text(
                        'PUBLICAR FOTO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
