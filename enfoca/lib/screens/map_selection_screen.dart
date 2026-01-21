import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapSelectionScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapSelectionScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // Coordenadas seleccionadas por el usuario
  LatLng? _selectedLocation;
  // Controlador del mapa
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Si ya habia una posicion seleccionada previamente, la cargamos
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  // Metodo para manejar el toque en el mapa
  void _handleTap(TapPosition tapPosition, LatLng point) {
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

  // Metodo para confirmar la seleccion y volver atras
  void _confirmSelection() {
    Navigator.of(context).pop(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final defaultCenter = const LatLng(40.416775, -3.703790); // Madrid

    return Scaffold(
      // ********** Barra Superior (AppBar) ********** //
      appBar: AppBar(
        title: const Text('Elige una ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // Solo permite confirmar si hay una ubicacion seleccionada
            onPressed: _selectedLocation == null ? null : _confirmSelection,
          ),
        ],
      ),
      // ********** FIN Barra Superior ********** //

      // ********** Cuerpo del Mapa ********** //
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation ?? defaultCenter,
          initialZoom: 13.0,
          onTap: _handleTap,
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
                    : const SizedBox.shrink(), // Invisible
              ),
            ],
          ),
        ],
      ),
      // ********** FIN Cuerpo del Mapa ********** //

      // ********** Boton Flotante de Confirmacion ********** //
      floatingActionButton: _selectedLocation == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _confirmSelection,
              label: const Text('Confirmar'),
              icon: const Icon(Icons.check),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
      // ********** FIN Boton Flotante ********** //
    );
  }
}
