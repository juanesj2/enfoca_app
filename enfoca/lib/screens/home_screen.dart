import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../services/theme_service.dart';

import '../widgets/photo_item.dart';
import 'foto_create_screen.dart';
import 'fotos_usuario_screen.dart'; // Importamos la pantalla de Mis Fotos
import 'perfil_screen.dart'; // Importamos la pantalla de Perfil

// ==========================================
// PANTALLA PRINCIPAL (HOME / FEED)
// ==========================================

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==========================================
  // ESTADO (STATE)
  // ==========================================
  var _isInit = true; // Controla si es la primera carga para inicializar datos
  var _isLoading = false; // Controla el spinner de carga
  int _selectedIndex = 0; // Índice de la página actual

  // Key para el navegador anidado del Feed
  final GlobalKey<NavigatorState> _feedNavigatorKey =
      GlobalKey<NavigatorState>();

  // Variable para controlar PopScope
  bool _canPopNow = false;

  // ==========================================
  // CICLO DE VIDA
  // ==========================================

  @override
  void didChangeDependencies() {
    // Carga inicial de datos (Fotos)
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      Provider.of<PhotoService>(context)
          .obtenerFotos()
          .then((_) {
            setState(() {
              _isLoading = false;
            });
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            // Manejar error (mostrar alerta, etc. si fuera necesario)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al cargar fotos')),
            );
          });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // ==========================================
  // MÉTODOS DE CONTROL
  // ==========================================

  // Método para cambiar de página desde la barra de navegación
  void _alTocarItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método para construir la pantalla correspondiente según el índice
  Widget _construirPagina() {
    switch (_selectedIndex) {
      case 0: // Inicio (Explorar / Feed)
        // Usamos un Navigator anidado para que al entrar en el detalle se mantenga el BottomBar
        return Navigator(
          key: _feedNavigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) {
                // Usamos Consumer para escuchar cambios en PhotoService (ej. likes)
                return Consumer<PhotoService>(
                  builder: (ctx, photoService, _) {
                    final photos = photoService.items;
                    if (photos.isEmpty) {
                      return const Center(
                        child: Text('No hay fotos disponibles'),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => Provider.of<PhotoService>(
                        ctx,
                        listen: false,
                      ).obtenerFotos(),
                      child: ListView.builder(
                        itemCount: photos.length,
                        itemBuilder: (c, i) => PhotoItem(photo: photos[i]),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      case 1: // Buscador
        return const FotosUsuarioScreen(isSearchMode: true);
      case 2: // Crear (Acción del FAB)
        // Pasamos el callback para que al terminar de subir, vuelva a la home
        return FotoCreateScreen(
          onPhotoUploaded: () {
            // Volver al inicio (Feed) y refrescar si es necesario
            _alTocarItem(0);
          },
        );
      case 3: // Mis Fotos
        return const FotosUsuarioScreen(
          isSearchMode: false,
        ); // Devolvemos la pantalla de Mis Fotos
      case 4: // Perfil
        return const PerfilScreen(); // Devolvemos la pantalla de Perfil
      default:
        return const Center(child: Text("Página no encontrada"));
    }
  }

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPopNow,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }

        // Si estamos en el tab de Inicio (0) y hay historial en su navegador anidado
        if (_selectedIndex == 0) {
          final poppedInternal = await _feedNavigatorKey.currentState!
              .maybePop();
          if (poppedInternal) {
            // Si pudo hacer pop dentro del tab, ya se manejó el evento
            return;
          }
        }

        // Si no se manejó internamente, permitimos salir
        setState(() {
          _canPopNow = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
        // ==========================================
        // APPBAR SUPERIOR
        // ==========================================
        appBar: AppBar(
          // Logo y título de la app
          title: Row(
            children: [
              Image.asset('assets/images/logo.ico', height: 40),
              const SizedBox(width: 10),
              const Text('Enfoca'),
            ],
          ),
          // ==========================================
          // ACCIONES DE LA APPBAR (DERECHA)
          // ==========================================
          actions: [
            // Usamos Consumer para escuchar reactivamente al ThemeService.
            // Cuando el estado de isDarkMode cambia, solo este widget (el Icono) se redibuja.
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return IconButton(
                  // Alternamos el icono dinámicamente:
                  // Si está en Modo Oscuro, mostramos un Sol (para volver a claro).
                  // Si está en Modo Claro, mostramos una Luna (para ir al oscuro).
                  icon: Icon(
                    themeService.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  // Al presionar el botón, ejecutamos el método toggleTheme del ThemeService
                  // que invertirá el valor y notificará a toda la App.
                  onPressed: () {
                    themeService.toggleTheme();
                  },
                  // Texto emergente al mantener presionado (Accesibilidad)
                  tooltip: themeService.isDarkMode
                      ? 'Cambiar a Modo Claro'
                      : 'Cambiar a Modo Oscuro',
                );
              },
            ),
          ],
        ),

        // ==========================================
        // CUERPO DINÁMICO
        // ==========================================
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _construirPagina(),

        // ==========================================
        // BOTÓN FLOTANTE (FAB) - CREAR
        // ==========================================
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Acción del botón Crear
            setState(() {
              _selectedIndex = 2;
            });
          },
          backgroundColor:
              Colors.orange, // Color distintivo para que sobresalga
          elevation: 4,
          child: const Icon(Icons.add_a_photo, size: 28),
        ),
        floatingActionButtonLocation:
            const CustomFloatingActionButtonLocation(),

        // ==========================================
        // BARRA DE NAVEGACIÓN INFERIOR (BOTTOM APP BAR)
        // ==========================================
        bottomNavigationBar: BottomAppBar(
          shape:
              const CircularNotchedRectangle(), // Recorte circular para el FAB
          notchMargin: 8.0, // Margen entre FAB y barra
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // --- Izquierda ---
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(0),
                  tooltip: 'Inicio',
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(1),
                  tooltip: 'Buscar',
                ),

                const SizedBox(width: 40), // Espacio para el FAB
                // --- Derecha ---
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(3),
                  tooltip: 'Mis Fotos',
                ),
                IconButton(
                  icon: Icon(
                    Icons.manage_accounts,
                    color: _selectedIndex == 4 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(4),
                  tooltip: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CLASE AUXILIAR: UBICACIÓN DEL FAB
// ==========================================

// Clase personalizada para bajar un poco el botón flotante
class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const CustomFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Calculamos la posición X (centrada)
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;

    // Calculamos la posición Y estándar (centerDocked)
    final double standardY =
        scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height / 2.0;

    // Bajamos el botón 30 pixeles más para que no sobresalga tanto
    return Offset(fabX, standardY + 30.0);
  }
}
