import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Motor de mapas OpenSource estilo Google Maps
import 'package:latlong2/latlong.dart'; // Matemáticas de coordenadas (Grados, Minutos, Segundos)

// Pantalla para que el usuario seleccione una ubicación en el mapa.

class MapSelectionScreen extends StatefulWidget {
  // Coordenadas iniciales si se entra para editar.
  final double? initialLat;
  final double? initialLng;

  const MapSelectionScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  LatLng? _selectedLocation;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  void _manejarToque(TapPosition tapPosition, LatLng point) {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _selectedLocation = point;
        });
      }
    });
  }

  void _confirmarSeleccion() {
    Navigator.of(context).pop(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    // Coordenadas por defecto (Puerta del Sol, Madrid).
    final defaultCenter = const LatLng(40.416775, -3.703790);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedLocation == null ? null : _confirmarSeleccion,
          ),
        ],
      ),

      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation ?? defaultCenter,
          initialZoom: 13.0,
          onTap: _manejarToque,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.enfoca',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation ?? defaultCenter,
                width: 80,
                height: 80,
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

      floatingActionButton: IgnorePointer(
        ignoring: _selectedLocation == null,
        child: AnimatedOpacity(
          opacity: _selectedLocation == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.extended(
            onPressed: _selectedLocation == null ? null : _confirmarSeleccion,
            label: const Text(
              'Seleccionar',
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
