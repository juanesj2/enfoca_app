import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../services/photo_service.dart';

class FotoCreateScreen extends StatefulWidget {
  static const routeName = '/foto-create';
  final VoidCallback? onPhotoUploaded;

  const FotoCreateScreen({super.key, this.onPhotoUploaded});

  @override
  _FotoCreateScreenState createState() => _FotoCreateScreenState();
}

class _FotoCreateScreenState extends State<FotoCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Values
  String _titulo = '';
  String _descripcion = '';
  int? _iso;
  String? _velocidadObturacion;
  double? _apertura;
  double? _latitud;
  double? _longitud;

  // Image
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // State
  bool _isLoading = false;
  bool _isGettingLocation = false;

  // Controllers to update UI when values change programmatically
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920, // Optimization
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
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de ubicación denegados')),
          );
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de ubicación denegados permanentemente'),
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
      ).showSnackBar(SnackBar(content: Text('Error obteniendo ubicación: $e')));
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<PhotoService>(context, listen: false).createPhoto(
        _pickedImage!,
        _titulo,
        _descripcion,
        latitud: _latitud,
        longitud: _longitud,
        iso: _iso,
        velocidadObturacion: _velocidadObturacion,
        apertura: _apertura,
      );

      // Navigate back or to home
      // Using pushReplacementNamed to go to home and refresh could be an option,
      // or just pop if it was pushed.
      // Since it's a page in logic, let's reset or show success.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Foto subida con éxito!')));

      // Notify parent to switch tab
      if (widget.onPhotoUploaded != null) {
        widget.onPhotoUploaded!();
      }
      // If used as a route elsewhere, we might want to pop, but for now it's embedded.
      // Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ocurrió un error: $error')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                    // --- Image Picker ---
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Tomar Foto'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Galería'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickImage(ImageSource.gallery);
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
                                  Text('Toca para añadir foto'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Basic Info ---
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Título'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un título';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _titulo = value!;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      onSaved: (value) {
                        _descripcion = value ?? '';
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Location ---
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _latitud != null
                                ? 'Ubicación: $_latitud, $_longitud'
                                : 'Sin ubicación',
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
                          TextButton.icon(
                            icon: const Icon(Icons.my_location),
                            label: const Text('Añadir Ubicación'),
                            onPressed: _getCurrentLocation,
                          ),
                      ],
                    ),
                    const Divider(),

                    // --- Tech Specs (Collapsible or just fields) ---
                    const Text(
                      'Datos Técnicos (Opcional)',
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
                            decoration: const InputDecoration(labelText: 'ISO'),
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
                              labelText: 'Apertura (f/)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido'; // El backend lo exige
                              }
                              // Sanitizamos: quitamos 'f', '/', espacios y cambiamos coma por punto
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
                        labelText: 'Velocidad Obturación (ej. 1/1000)',
                      ),
                      onSaved: (value) {
                        _velocidadObturacion = value;
                      },
                    ),

                    const SizedBox(height: 30),

                    // --- Submit Button ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                        'PUBLICAR FOTO',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
