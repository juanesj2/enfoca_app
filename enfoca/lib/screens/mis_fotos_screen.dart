import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../widgets/photo_item.dart';

// ==========================================
// PANTALLA DE MIS FOTOS (VERSION SIMPLIFICADA)
// ==========================================

class MisFotosScreen extends StatefulWidget {
  const MisFotosScreen({super.key});

  @override
  State<MisFotosScreen> createState() => _MisFotosScreenState();
}

class _MisFotosScreenState extends State<MisFotosScreen> {
  // ==========================================
  // ESTADO (STATE)
  // ==========================================
  var _isInit = true; // Controla carga inicial
  var _isLoading = false; // Controla spinner

  // ==========================================
  // CICLO DE VIDA
  // ==========================================

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // Evitamos llamar a setState si no está montado, pero didChangeDependencies es seguro para iniciar cargas
      setState(() {
        _isLoading = true;
      });
      // Llamamos al método obtenerMisFotos del servicio
      Provider.of<PhotoService>(context)
          .obtenerMisFotos()
          .then((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // Manejo básico de errores
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al cargar mis fotos')),
              );
            }
          });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Obtenemos SOLO las fotos del usuario (misItems)
    final misFotos = Provider.of<PhotoService>(context).misItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Fotos Subidas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // Permite recargar deslizando hacia abajo
              onRefresh: () => Provider.of<PhotoService>(
                context,
                listen: false,
              ).obtenerMisFotos(),
              child: misFotos.isEmpty
                  ? const Center(
                      child: Text('No has subido ninguna foto todavía.'),
                    )
                  : ListView.builder(
                      itemCount: misFotos.length,
                      itemBuilder: (ctx, i) => PhotoItem(photo: misFotos[i]),
                    ),
            ),
    );
  }
}
