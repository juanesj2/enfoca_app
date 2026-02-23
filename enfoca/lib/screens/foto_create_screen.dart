import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Librería estelar para acceder a Cámara/Galería
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; // Librería estelar para satélites GPS

import 'package:latlong2/latlong.dart';
import '../services/photo_service.dart';
import 'map_selection_screen.dart';

// ==========================================
// PANTALLA DE ALTA DE PUBLICACIÓN (CREAR FOTO)
// ==========================================
// Este Widget es un formulario mastodóntico (StatefulWidget) que recopila
// tanto una Imagen Binaria (Archivo físico) como Textos (Metadatos).
// Todo esto debe empaquetarse junto usando el formato 'multipart/form-data' de HTTP.

class FotoCreateScreen extends StatefulWidget {
  // Alias de enrutamiento interno
  static const routeName = '/foto-create';

  // Callback o Trigger de Inyección.
  // Cuando terminamos con éxito, el "Padre" (HomeScreen) ejecutará esta misteriosa
  // función anónima ordenando al BottomNavigationBar que regrese al Tab0 (El Feed).
  final VoidCallback? onPhotoUploaded;

  const FotoCreateScreen({super.key, this.onPhotoUploaded});

  @override
  _FotoCreateScreenState createState() => _FotoCreateScreenState();
}

class _FotoCreateScreenState extends State<FotoCreateScreen> {
  // Llave Maestra del Formulario. Con ella le decimos a Flutter:
  // "Revisa si todas las validaciones de los TextFormField están en verde".
  final _formKey = GlobalKey<FormState>();

  // ==========================================
  // ESTADO INTERNO (VARIABLES DE RECOLECCIÓN)
  // ==========================================

  // --- 1. Metadatos de Negocio ---
  String _titulo = '';
  String _descripcion = '';
  // --- 2. Metadatos Fotográficos Opcionales ---
  int? _iso;
  String? _velocidadObturacion;
  double? _apertura;
  // --- 3. Posicionamiento Global ---
  double? _latitud;
  double? _longitud;

  // --- 4. El Archivo Físico Binario ---
  File? _pickedImage;
  // Instancia del Recolector de Imágenes (Nativo de Android/iOS)
  final ImagePicker _picker = ImagePicker();

  // --- 5. Banderas (Flags) de UX ---
  bool _isLoading = false; // Rulita de subida al servidor
  bool _isGettingLocation =
      false; // Rulita pequeña para el GPS buscando satélites

  // Controladores Mutables: A diferencia del 'onSaved', los Controladores nos permiten
  // INYECTAR texto programáticamente en las cajas (Ej. Tras capturar GPS automáticamente).
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // ==========================================
  // CICLO DE VIDA (DESTRUCCIÓN)
  // ==========================================

  @override
  void dispose() {
    // Al salir de esta pantalla, matamos los controladores de memoria para evitar goteras (Memory Leaks).
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ==========================================
  // LÓGICA CORE: OBTENCIÓN DE RECURSOS DEL MÓVIL
  // ==========================================

  // 1. INVOCAR SISTEMA DE IMÁGENES
  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      // Abre subrutina nativa del SO. Detiene la app hasta que el usuario elija o cancele.
      final XFile? pickedFile = await _picker.pickImage(
        source: source, // ¿ImageSource.camera o ImageSource.gallery?
        maxWidth:
            1920, // Autocompresión en frontend para no arruinar el ancho de banda
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          // Casteamos de XFile (Memoria volátil de la librería) a un File físico nativo puro de Dart
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error del kernel al capturar lente: $e')),
      );
    }
  }

  // 2. INVOCAR HARDWARE GPS
  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _isGettingLocation = true; // Activar ruletita GPS
    });

    try {
      // 2.1 Fase Legal: Comprobar Permisos de Android/iOS con el usuario
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Interrumpimos pidiendo permiso con el Popup del Sistema Operativo
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso interceptado o denegado')),
          );
          setState(() => _isGettingLocation = false);
          return; // Abortamos
        }
      }

      // Si el usuario nos mandó "Nunca" en los permisos, no insistimos.
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No podemos triangular. Ve a Ajustes del Sistema.'),
          ),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      // 2.2 Fase Física: Solicitar triangulación
      // DesiredAccuracy.high fuerza el chip GPS real (consume más batería) vs las antenas móviles.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // ¡Hemos encontrado el objetivo! Sobrescribimos interfaz.
      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _latController.text = _latitud.toString();
        _lngController.text = _longitud.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Satélites inalcanzables: $e')));
    } finally {
      setState(() {
        _isGettingLocation = false; // Apagar ruletita GPS
      });
    }
  }

  // 3. SELECCIÓN VISUAL MEDIANTE MAPA FLUTTER_MAP
  Future<void> _seleccionarUbicacionEnMapa() async {
    // Abrimos una "Mini-aplicación" paralela enviando un cohete (push)
    // El 'await' congela esta pantalla hasta que el usuario decida volver con un botín estelar (Un objeto LatLng).
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (ctx) =>
            MapSelectionScreen(initialLat: _latitud, initialLng: _longitud),
      ),
    );

    // ¿Cayó botín (Pincho clavado)? Rellenamos formulario
    if (result != null) {
      setState(() {
        _latitud = result.latitude;
        _longitud = result.longitude;
        _latController.text = _latitud.toString();
        _lngController.text = _longitud.toString();
      });
    }
  }

  // 4. PREPARACIÓN Y LANZAMIENTO DEL MISIL (HTTP POST)
  Future<void> _enviarFormulario() async {
    // ¿Todas las casillas requeridas pasan la validación regex (Si la hubiera) o están llenas?
    // Si currentState devuelve false, la pantalla se llena de textos rojos y parpadea. Abortamos envio.
    if (!_formKey.currentState!.validate()) return;

    // Validación artesanal: Un Post sin imagen de Post es inútil
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserta película fotográfica visual, por favor'),
        ),
      );
      return;
    }

    // Ordenamos a los TextFormFields que vacíen su 'onSaved' inyectándolo a nuestras variables top-level de esta clase.
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true; // Activar el Spinnersote gigante
    });

    try {
      // Disparo definitivo contra el Backend. Multipart HTTP Request.
      // Aquí está el truco: listen: false para que no explote la pila de memoria por reconstrucciones sutiles a medias.
      await Provider.of<PhotoService>(context, listen: false).crearFoto(
        _pickedImage!, // "!" le jura por dios a Dart que NUNCA será nulo, ya que arriba lo hemos protegido en el if()-return
        _titulo,
        _descripcion,
        latitud: _latitud,
        longitud: _longitud,
        iso: _iso,
        velocidadObturacion: _velocidadObturacion,
        apertura: _apertura,
      );

      // Si PHP nos devolvió OK HTTP 201:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Procesado exitoso! 📸')));

      // Apretamos el botón inalámbrico secreto para chivarle a HomeScreen
      // que cambie a la pestaña 0 (Muro), así vemos triunfales nuestra foto arriba de todas.
      if (widget.onPhotoUploaded != null) {
        widget.onPhotoUploaded!();
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fracaso Operativo: $error')));
    } finally {
      setState(() {
        _isLoading = false; // Apagamos el loader
      });
    }
  }

  // ==========================================
  // RENDERIZADO VISUAL DEL LIENZO (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Publicación')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // Formulario gigantesco protegigo por ScrollViewer para teclados en pantalla
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // Firma de contrato para poder hacer .validate()
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // Abarcar 100% de ancho
                  children: [
                    // ==========================================
                    // SECCIÓN 1: SELECTOR GRÁFICO (RECEPTÁCULO)
                    // ==========================================
                    // GestureDetector = Hacemos que CUALQUIER WIDGET se vuelva "Clicable".
                    GestureDetector(
                      onTap: () {
                        // ModalBottomSheet es un Popup que brota desde abajo del móvil hacia arriba.
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize
                                .min, // Solo ocupa de alto lo que necesiten sus hijos
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Tomar Foto Directa'),
                                onTap: () {
                                  Navigator.pop(ctx); // Cierra el Popup primero
                                  _seleccionarImagen(
                                    ImageSource.camera,
                                  ); // Lanza la cámara
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text(
                                  'Explorar Galería Carchipiélago',
                                ),
                                onTap: () {
                                  Navigator.pop(ctx); // Cierra el Popup primero
                                  _seleccionarImagen(
                                    ImageSource.gallery,
                                  ); // Lanza carrete nativo
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        height:
                            200, // Fijado para que quede cuadrado estilo Instagram
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Esquinas SUV
                        ),
                        alignment: Alignment.center,
                        // ¿Tengo una foto ya? La planto (Image.file). ¿No tengo? Pongo texto gris "Toca para añadir".
                        child: _pickedImage != null
                            ? Image.file(
                                _pickedImage!,
                                fit: BoxFit
                                    .cover, // Recorta equitativamente por los bordes si no cabe la rel. aspecto
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
                                    'Toca para infundir rollo fílmico',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // SECCIÓN 2: LITERATURA
                    // ==========================================
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Titular de la Captura',
                      ),
                      // Al darle a Enter en el móvil salta al siguiente campo
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          // Texto rojo cabreado de Flutter (UX Errors)
                          return 'El protocolo exige una designación formal.';
                        }
                        return null; // Todo "Ok"
                      },
                      onSaved: (value) {
                        _titulo =
                            value!; // Se inyecta al final en el submit final colectivo
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Boceto Descriptivo (Opcional)',
                      ),
                      maxLines: 3, // Caja grande multilínea
                      keyboardType: TextInputType.multiline,
                      onSaved: (value) {
                        _descripcion = value ?? '';
                      },
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // SECCIÓN 3: TOPOGRAFÍA Y CARTOGRAFÍA (GPS)
                    // ==========================================
                    const Text(
                      'Ubicación Planetaria',
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
                                ? 'Fijado: ${_latitud!.toStringAsFixed(4)}, ${_longitud!.toStringAsFixed(4)}'
                                : 'Coordenadas Perdidas',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        // Si está buscando la posición vía satélite, spinner.
                        if (_isGettingLocation)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          // Botones de Comando (2 Opciones de Fichaje)
                          Column(
                            mainAxisSize:
                                MainAxisSize.min, // Juntitos verticalmente
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

                    // ==========================================
                    // SECCIÓN 4: PARÁMETROS FOTÓNICOS (METADATOS EXIF)
                    // ==========================================
                    const Text(
                      'Datos Biométricos de Lente',
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
                            // Fuerza abrir SOLO números (Sin letras) en móvil
                            keyboardType: TextInputType.number,
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _iso = int.tryParse(
                                  value,
                                ); // Convierte "100" string a 100 entero de CPU
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
                              decimal:
                                  true, // Deja pulsar comas o puntos (Relevante para f/ 1.8)
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Obligtorio en Laravel';
                              }
                              // --- SANITIZACIÓN ROBUSTA (PARSER) ---
                              // El usuario humano es torpe, escribirá "f1,8" o " 1.8 ", o "f/1.8"
                              // Destruimos la basura visual e igualamos comas europeas a puntos universales (US)
                              final sanitized = value
                                  .toLowerCase()
                                  .replaceAll('f', '')
                                  .replaceAll('/', '')
                                  .replaceAll(' ', '')
                                  .replaceAll(',', '.');

                              if (double.tryParse(sanitized) == null) {
                                return 'No es matemático (Ej: 2.8)';
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
                                _apertura = double.tryParse(
                                  sanitized,
                                ); // Convierte a C++ Double (00.00)
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Velocidad de Obturación (Ráfaga /100)',
                      ),
                      onSaved: (value) {
                        // Lo guardamos como string puro, si pone 1/100 se lo come entero el SQL como VARCHAR.
                        _velocidadObturacion = value;
                      },
                    ),

                    const SizedBox(
                      height: 30,
                    ), // Margen inferior antes del disparo final
                    // ==========================================
                    // EL INTERRUPTOR FINAL: LANZAR A LARAVEL
                    // ==========================================
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _enviarFormulario,
                      child: const Text(
                        'REVELAR Y PUBLICAR 🚀',
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
