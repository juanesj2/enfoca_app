import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Motor de mapas OpenSource estilo Google Maps
import 'package:latlong2/latlong.dart'; // Matemáticas de coordenadas (Grados, Minutos, Segundos)

// ==========================================
// PANTALLA CARTOGRÁFICA INTERACTIVA (SELECCIÓN DE MAPA)
// ==========================================
// Widget modal a pantalla completa diseñado para que el usuario "clave"
// una chincheta virtual en cualquier rincón del planeta.

class MapSelectionScreen extends StatefulWidget {
  // Paracaídas de entrada: Si la foto ya venía con unas coordenadas previas
  // (P. ej. al editar), que el mapa aterrice allí directamente.
  final double? initialLat;
  final double? initialLng;

  const MapSelectionScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // ==========================================
  // ESTADO (STATE ESPACIAL)
  // ==========================================
  // Objeto matemático que guarda latitud y longitud. Si es nulo, no hay punto elegido.
  LatLng? _selectedLocation;

  // Joystick del Mapa: Permite mover la cámara por código (Animaciones, vuelo hasta París, etc).
  final MapController _mapController = MapController();

  // ==========================================
  // CICLO DE VIDA (INICIO DEL VUELO)
  // ==========================================

  @override
  void initState() {
    super.initState();
    // ¿Venimos con mandato de aterrizaje? Construimos la coordenada inicial.
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  // ==========================================
  // FÍSICA Y EVENTOS
  // ==========================================

  // Disparador al tocar con el dedo en cualquier callejón virtual.
  void _manejarToque(TapPosition tapPosition, LatLng point) {
    // Hack de Redibujado: A veces, clavar múltiples chinchetas muy rápido colapsaba
    // el sistema de render de escritorio (Windows/Mac). Retrasar medio segundo
    // el guardado tranquiliza al hilo gráfico.
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _selectedLocation =
              point; // Mutación: El alfiler rojo vuela a la nueva posición.
        });
      }
    });
  }

  // El botón verde de "Aceptar". Regresa al formulario de "Crear Foto" con el botín.
  void _confirmarSeleccion() {
    Navigator.of(context).pop(_selectedLocation);
  }

  // ==========================================
  // ARQUITECTURA GRÁFICA (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Si no saben dónde empezar, empezamos en Puerta del Sol, Madrid.
    final defaultCenter = const LatLng(40.416775, -3.703790);

    return Scaffold(
      // ==========================================
      // BARRA SUPERIOR (MANDO DE NAVEGACIÓN)
      // ==========================================
      appBar: AppBar(
        title: const Text('Topografía Global'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // Defensa Lógica: "null" apaga el botón. No puedes volver si no has pinchado nada.
            onPressed: _selectedLocation == null ? null : _confirmarSeleccion,
          ),
        ],
      ),

      // ==========================================
      // CUERPO: PLANETA TIERRA EN 2D (FlutterMap)
      // ==========================================
      body: FlutterMap(
        mapController: _mapController, // Enchufamos el joystick
        options: MapOptions(
          initialCenter:
              _selectedLocation ??
              defaultCenter, // Aterriza en tu destino o en Madrid
          initialZoom: 13.0, // Zoom "Nivel Ciudad"
          onTap: _manejarToque, // Qué pasa al tocar
        ),
        // Flutter Map funciona por Capas (Layers), como Photoshop.
        children: [
          // Capa 1: Las Baldosas PNG (Tiles) del mapa de fondo
          TileLayer(
            // OpenStreetMap nos cede gratuitamente las fotos de satélite (Sin API Key cara de Google Maps)
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.example.enfoca', // Respeto a los servidores de OSM
          ),

          // Capa 2: Dibujos superpuestos (Chinchetas, Polígonos, Rutas GPS)
          MarkerLayer(
            markers: [
              // Declaración del Pincho Rojo
              Marker(
                point: _selectedLocation ?? defaultCenter,
                width: 80,
                height: 80,
                // Si el usuario no ha pinchado, pintamos un "Fantasma" invisible (Opacity 0)
                // Esto es un parche estructural para evitar que Flutter llore por listas cambiantes.
                child: _selectedLocation != null
                    ? const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 50,
                      )
                    : const Opacity(
                        opacity: 0.0,
                        child: Icon(Icons.location_on, size: 40),
                      ),
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // GATILLO FLOTANTE INFERIOR
      // ==========================================
      // Envuelto en Ignoradores de Punteros para que sea "Fantasma" hasta que pinches el mapa
      floatingActionButton: IgnorePointer(
        ignoring: _selectedLocation == null,
        child: AnimatedOpacity(
          opacity: _selectedLocation == null
              ? 0.0
              : 1.0, // Face IN/OUT Suavizado
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.extended(
            onPressed: _selectedLocation == null ? null : _confirmarSeleccion,
            label: const Text(
              'Fijar Coordenadas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.gps_fixed),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 8,
          ),
        ),
      ),
    );
  }
}
