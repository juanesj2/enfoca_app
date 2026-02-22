import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ==========================================
// PANTALLA DE SELECCIÓN EN MAPA
// ==========================================

class MapSelectionScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapSelectionScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // ==========================================
  // ESTADO (STATE)
  // ==========================================
  // Coordenadas seleccionadas por el usuario
  LatLng? _selectedLocation;
  // Controlador del mapa
  final MapController _mapController = MapController();

  // ==========================================
  // CICLO DE VIDA
  // ==========================================

  @override
  void initState() {
    super.initState();
    // Si ya había una posición seleccionada previamente, la cargamos
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  // ==========================================
  // MÉTODOS
  // ==========================================

  // Método para manejar el toque en el mapa
  void _manejarToque(TapPosition tapPosition, LatLng point) {
    // Usamos Future.delayed para separar completamente la actualización del ciclo de eventos actual
    // Esto soluciona el crash de MouseTracker en Windows/Desktop mejor que addPostFrameCallback
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _selectedLocation = point;
        });
      }
    });
  }

  // Método para confirmar la selección y volver atrás
  void _confirmarSeleccion() {
    Navigator.of(context).pop(_selectedLocation);
  }

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final defaultCenter = const LatLng(40.416775, -3.703790); // Madrid

    return Scaffold(
      // ==========================================
      // BARRA SUPERIOR (APPBAR)
      // ==========================================
      appBar: AppBar(
        title: const Text('Elige una ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // Solo permite confirmar si hay una ubicación seleccionada
            onPressed: _selectedLocation == null ? null : _confirmarSeleccion,
          ),
        ],
      ),

      // ==========================================
      // CUERPO DEL MAPA
      // ==========================================
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation ?? defaultCenter,
          initialZoom: 13.0,
          onTap: _manejarToque,
        ),
        children: [
          // Capa de mapas (OpenStreetMap)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.enfoca',
          ),
          // Capa de marcadores
          MarkerLayer(
            markers: [
              // Siempre renderizamos un marcador para mantener la estabilidad del árbol de widgets
              // y evitar el crash de MouseTracker. Si no hay selección, lo hacemos invisible.
              Marker(
                point: _selectedLocation ?? defaultCenter,
                width: 80,
                height: 80,
                child: _selectedLocation != null
                    ? const Icon(Icons.location_on, color: Colors.red, size: 40)
                    : const Opacity(
                        opacity: 0.0,
                        child: Icon(Icons.location_on, size: 40),
                      ), // Estabiliza el MouseTracker en escritorio
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // BOTÓN FLOTANTE DE CONFIRMACIÓN
      // ==========================================
      floatingActionButton: IgnorePointer(
        ignoring: _selectedLocation == null,
        child: AnimatedOpacity(
          opacity: _selectedLocation == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.extended(
            onPressed: _selectedLocation == null ? null : _confirmarSeleccion,
            label: const Text('Confirmar'),
            icon: const Icon(Icons.check),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
