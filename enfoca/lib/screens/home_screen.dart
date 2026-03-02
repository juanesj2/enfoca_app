import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../services/theme_service.dart';

import '../widgets/photo_item.dart';
import 'foto_create_screen.dart';
import 'fotos_usuario_screen.dart'; // Importamos la pantalla de Mis Fotos
import 'perfil_screen.dart'; // Importamos la pantalla de Perfil

// Pantalla principal con las pestañas de navegación
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _isInit = true;
  var _isLoading = false;
  int _selectedIndex = 0;

  final GlobalKey<NavigatorState> _feedNavigatorKey =
      GlobalKey<NavigatorState>();

  bool _canPopNow = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      // Cargar las fotos al iniciar
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al cargar las fotos')),
            );
          });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _alTocarItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _construirPagina() {
    switch (_selectedIndex) {
      case 0:
        return Navigator(
          key: _feedNavigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) {
                return Consumer<PhotoService>(
                  builder: (ctx, photoService, _) {
                    final photos = photoService.items;
                    if (photos.isEmpty) {
                      return const Center(
                        child: Text('No hay fotos para mostrar'),
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
      case 1:
        return const FotosUsuarioScreen(isSearchMode: true);
      case 2:
        return FotoCreateScreen(
          onPhotoUploaded: () {
            _alTocarItem(0);
          },
        );
      case 3:
        return const FotosUsuarioScreen(isSearchMode: false);
      case 4:
        return const PerfilScreen();
      default:
        return const Center(child: Text("Pantalla no encontrada"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPopNow,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_selectedIndex == 0) {
          final poppedInternal = await _feedNavigatorKey.currentState!
              .maybePop();
          if (poppedInternal) {
            return;
          }
        }

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
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/images/logo.ico', height: 40),
              const SizedBox(width: 10),
              const Text(
                'Enfoca',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return IconButton(
                  icon: Icon(
                    themeService.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    themeService.toggleTheme();
                  },
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _construirPagina(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 2;
            });
          },
          backgroundColor: Colors.orange,
          elevation: 4,
          child: const Icon(Icons.add_a_photo, size: 28),
        ),
        floatingActionButtonLocation:
            const CustomFloatingActionButtonLocation(),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(0),
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(1),
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(3),
                ),
                IconButton(
                  icon: Icon(
                    Icons.manage_accounts,
                    color: _selectedIndex == 4 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const CustomFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;

    final double standardY =
        scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height / 2.0;

    return Offset(fabX, standardY + 30.0);
  }
}
