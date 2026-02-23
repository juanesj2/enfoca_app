import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../widgets/photo_item.dart';

// ==========================================
// PANTALLA DE ALMACÉN DE FOTOGRAFÍAS (MIS FOTOS)
// ==========================================
// Una versión minimalista del muro principal centrada 100%
// en enseñar únicamente el archivo digital del propietario activo.

class MisFotosScreen extends StatefulWidget {
  const MisFotosScreen({super.key});

  @override
  State<MisFotosScreen> createState() => _MisFotosScreenState();
}

class _MisFotosScreenState extends State<MisFotosScreen> {
  // ==========================================
  // FLUJO DE CONTROL SECUENCIAL (STATE)
  // ==========================================
  var _isInit = true; // Actuador de disparo-único
  var _isLoading = false; // Manejador de animación circular anti-ansiedad

  // ==========================================
  // HOOKS DE MONTAJE Y CICLO VITAL
  // ==========================================

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // Bloqueamos la interfaz para evitar clicks nerviosos
      setState(() {
        _isLoading = true;
      });
      // Despertamos al Servicio de Fotografía.
      // Si la base de datos es gigantesca, esto puede tardar unos segundos.
      Provider.of<PhotoService>(context)
          .obtenerMisFotos()
          .then((_) {
            // "mounted" comprueba físicamente si la pieza de puzzle de esta pantalla
            // sigue existiendo en el tablón del móvil. Evita crasheos de navegación rápida.
            if (mounted) {
              setState(() {
                _isLoading = false; // Desbloqueamos interfaz = Pintar!
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // Mecanismo nativo de Alertas discretas inferiores
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Interrupción o Ruptura de Enlace Fotográfico'),
                ),
              );
            }
          });
    }
    _isInit = false; // Sellar acceso secundario
    super.didChangeDependencies();
  }

  // ==========================================
  // SISTEMA DE RENDERIZACIÓN (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Almacén Lógico Inmediato. Como ya nos cargamos los datos asíncronamente en el INIT,
    // aquí solo abrimos e iteramos la caja "misItems" sin esperas.
    final misFotos = Provider.of<PhotoService>(context).misItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Fotos Subidas')),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Giro Hipnótico
          : RefreshIndicator(
              // RefreshIndicator: Si en el móvil pones el dedo en medio y arrastras salvajemente
              // hacia el puerto USB, fuerzas una nueva descarga forzosa contra Laravel.
              onRefresh: () => Provider.of<PhotoService>(
                context,
                listen: false,
              ).obtenerMisFotos(),
              child: misFotos.isEmpty
                  ? const Center(
                      // Placeholder amistoso
                      child: Text(
                        'El rollo fotográfico virtual está vacío.\n¡Toma tu cámara!',
                      ),
                    )
                  : ListView.builder(
                      // Creación perezosa por Scroll Infinita "Lazy Loading":
                      // Si hay mil fotos, de inicio solo renderea las 3 fotos que caben en pantalla.
                      itemCount: misFotos.length,
                      itemBuilder: (ctx, i) => PhotoItem(photo: misFotos[i]),
                    ),
            ),
    );
  }
}
