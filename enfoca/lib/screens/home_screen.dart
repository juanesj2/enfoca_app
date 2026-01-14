import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../services/auth_service.dart';
import '../widgets/photo_item.dart';
import 'foto_create_screen.dart';
import 'mis_fotos_screen.dart'; // Importamos la pantalla de Mis Fotos
import 'perfil_screen.dart'; // Importamos la pantalla de Perfil

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ********** Variables de Estado ********** //
  var _isInit = true; // Controla si es la primera carga para inicializar datos
  var _isLoading = false; // Controla el spinner de carga
  int _selectedIndex = 0; // Índice de la página actual

  // Key para el navegador anidado del Feed
  final GlobalKey<NavigatorState> _feedNavigatorKey =
      GlobalKey<NavigatorState>();

  // Variable para controlar PopScope
  bool _canPopNow = false;
  // ********** FIN Variables de Estado ********** //

  @override
  void didChangeDependencies() {
    // Carga inicial de datos (Fotos)
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      Provider.of<PhotoService>(context)
          .fetchPhotos()
          .then((_) {
            setState(() {
              _isLoading = false;
            });
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            // Manejar error (mostrar alerta, etc.)
          });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // Método para cambiar de página desde la barra de navegación
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método para construir la pantalla correspondiente según el índice
  Widget _buildPage(List<dynamic> photos) {
    // photos es List<Fotografia> pero dynamic aqui facilita
    switch (_selectedIndex) {
      case 0: // Inicio (Explorar)
      case 0: // Inicio (Explorar)
        // Usamos un Navigator anidado para que al entrar en el detalle se mantenga el BottomBar
        return Navigator(
          key: _feedNavigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => RefreshIndicator(
                onRefresh: () => Provider.of<PhotoService>(
                  context,
                  listen: false,
                ).fetchPhotos(),
                child: ListView.builder(
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) => PhotoItem(photo: photos[i]),
                ),
              ),
            );
          },
        );
      case 1: // Buscador
        return const Center(child: Text("Próximamente: Buscador de usuarios"));
      case 2: // Crear (Acción del FAB)
        // Pasamos el callback para que al terminar de subir, vuelva a la home
        return FotoCreateScreen(
          onPhotoUploaded: () {
            // Volver al inicio (Feed) y refrescar si es necesario
            _onItemTapped(0);
          },
        );
      case 3: // Mis Fotos
        return const MisFotosScreen(); // Devolvemos la pantalla de Mis Fotos
      case 4: // Perfil
        return const PerfilScreen(); // Devolvemos la pantalla de Perfil
      default:
        return const Center(child: Text("Página no encontrada"));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las fotos del provider
    final photos = Provider.of<PhotoService>(context).items;

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
        // ********** AppBar Superior ********** //
        appBar: AppBar(
          // Logo y titulo de la app
          title: Row(
            children: [
              Image.asset('assets/images/logo.ico', height: 40),
              const SizedBox(width: 10),
              const Text('Enfoca'),
            ],
          ),
        ),
        // ********** FIN AppBar ********** //

        // ********** Cuerpo Dinámico ********** //
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildPage(photos),
        // ********** FIN Cuerpo ********** //

        // ********** Botón Flotante (FAB) - CREAR ********** //
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Acción del botón Crear
            setState(() {
              _selectedIndex = 2;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abrir cámara/galería')),
            );
          },
          backgroundColor:
              Colors.orange, // Color distintivo para que sobresalga
          elevation: 4,
          child: const Icon(Icons.add_a_photo, size: 28),
        ),
        floatingActionButtonLocation:
            const CustomFloatingActionButtonLocation(),
        // ********** FIN Botón Flotante ********** //

        // ********** Barra de Navegación Inferior (BottomAppBar) ********** //
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
                  onPressed: () => _onItemTapped(0),
                  tooltip: 'Inicio',
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _onItemTapped(1),
                  tooltip: 'Buscar',
                ),

                const SizedBox(width: 40), // Espacio para el FAB
                // --- Derecha ---
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _onItemTapped(3),
                  tooltip: 'Mis Fotos',
                ),
                IconButton(
                  icon: Icon(
                    Icons.manage_accounts,
                    color: _selectedIndex == 4 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _onItemTapped(4),
                  tooltip: 'Perfil',
                ),
              ],
            ),
          ),
        ),
        // ********** FIN Barra de Navegación ********** //
      ),
    );
  }
}

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
