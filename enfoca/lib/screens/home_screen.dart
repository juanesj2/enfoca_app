import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../services/theme_service.dart';

import '../widgets/photo_item.dart';
import 'foto_create_screen.dart';
import 'fotos_usuario_screen.dart'; // Importamos la pantalla de Mis Fotos
import 'perfil_screen.dart'; // Importamos la pantalla de Perfil

// ==========================================
// PANTALLA PRINCIPAL (HOME / FEED CENTRAL)
// ==========================================
// Este archivo actúa como el esqueleto contenedor (Scaffold) principal de la App.
// Alberga la Barra Superior (AppBar), el Botón Flotante (FAB) central,
// y la Barra de Navegación Inferior (BottomNavigationBar) que alterna 5 pantallas distintas.

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==========================================
  // ESTADO INTERNO (STATE)
  // ==========================================
  var _isInit =
      true; // Candado lógico para asegurar que la descarga inicial solo ocurra 1 vez.
  var _isLoading =
      false; // Controla que salga la "rulita" de carga al principio.
  int _selectedIndex =
      0; // Índice de la pestaña actual activada (0 = Feed, 1 = Buscar, etc.)

  // Llave Maestra (GlobalKey) para un Navegador "Anidado".
  // Esto permite que el Tab de Inicio (#0) tenga su propio historial de flechas de retroceso
  // sin que la barra inferior desaparezca misteriosamente de la pantalla.
  final GlobalKey<NavigatorState> _feedNavigatorKey =
      GlobalKey<NavigatorState>();

  // Bandera física del sistema (Botón 'Atrás' de Android)
  bool _canPopNow = false;

  // ==========================================
  // CICLO DE VIDA (INIT)
  // ==========================================

  // Primer latido de vida del Widget antes de dibujarse en pantalla
  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true; // Enciende el Spinner
      });
      // Llama a PHP y trae todas las fotos del muro social.
      Provider.of<PhotoService>(context)
          .obtenerFotos()
          .then((_) {
            setState(() {
              _isLoading = false; // Apaga el Spinner
            });
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            // Si hay error (Ej: No hay Wifi), aparece un cartelito (SnackBar) desde abajo.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error al cargar red social: Servidor inaccesible',
                ),
              ),
            );
          });
    }
    _isInit = false; // Cierra la puerta para siempre
    super.didChangeDependencies();
  }

  // ==========================================
  // MÉTODOS DE CONTROL / ENRUTAMIENTO
  // ==========================================

  // Disparado al presionar cualquier icono de la barra inferior
  void _alTocarItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fábrica de Pantallas ("Router" casero basado en Switch-Case)
  Widget _construirPagina() {
    switch (_selectedIndex) {
      case 0: // ÍNDICE 0: Feed de Noticias (El Muro)
        // Ojo: Se usa un Navigator especial aquí dentro para que si el usuario entra a ver
        // los comentarios de una foto especifica, siga viendo la botonera principal abajo.
        return Navigator(
          key: _feedNavigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) {
                // Consumer se suscribe a PhotoService.
                // Si alguien da Like o sube foto, esto se auto-redibuja en tiempo real.
                return Consumer<PhotoService>(
                  builder: (ctx, photoService, _) {
                    final photos = photoService.items;
                    if (photos.isEmpty) {
                      return const Center(
                        child: Text('El muro está vacío O_o'),
                      );
                    }
                    // RefreshIndicator envuelve al muro. Si "tiras hacia abajo" con el dedo,
                    // vuelve a llamar a la API para ver fotos nuevas (Como Instagram).
                    return RefreshIndicator(
                      onRefresh: () => Provider.of<PhotoService>(
                        ctx,
                        listen: false,
                      ).obtenerFotos(),
                      child: ListView.builder(
                        itemCount: photos.length, // Número de cajas a dibujar
                        // photoItem.dart encapsula el cuadro de cada foto individual
                        itemBuilder: (c, i) => PhotoItem(photo: photos[i]),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      case 1: // ÍNDICE 1: Buscador Lupa
        return const FotosUsuarioScreen(isSearchMode: true);
      case 2: // ÍNDICE 2: El colosal Botón Central Flotante (Cámara)
        // Pasamos un "Callback" (Función puente): Si al chaval le sale bien subir la foto,
        // _alTocarItem(0) lo fuerza a volver al Muro Inédito para ver su obra de arte recién parida.
        return FotoCreateScreen(
          onPhotoUploaded: () {
            _alTocarItem(0);
          },
        );
      case 3: // ÍNDICE 3: Área personal (Mis Fotos filtradas)
        return const FotosUsuarioScreen(isSearchMode: false);
      case 4: // ÍNDICE 4: Ajustes / Perfil del Usario
        return const PerfilScreen();
      default:
        return const Center(child: Text("Pantalla en obras"));
    }
  }

  // ==========================================
  // CONSTRUCCIÓN DEL ÁRBOL MAESTRO (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // PopScope: Parche mágico de Flutter moderno para interceptar el "Volver" táctil en Android.
    // Evita que el usuario destroce el Navigator anidado al usar el gesto nativo del teléfono.
    return PopScope(
      canPop: _canPopNow,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Si estamos viendo el Tab Inicio (0), consultamos el historial de su navegador anidado especial
        if (_selectedIndex == 0) {
          final poppedInternal = await _feedNavigatorKey.currentState!
              .maybePop();
          if (poppedInternal) {
            // Se pudo retroceder a la página anterior dentro del propio Feed. Asunto arreglado.
            return;
          }
        }

        // Si ya estamos en la base del Tab 0 o en cualquier otro Tab, autorizamos el cerrojazo total.
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
        // CABECERA GLOBAL (AppBar)
        // ==========================================
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
            // INTERRUPTOR MODO OSCURO GLOBAL
            // El Consumer huele qué tema estamos usando (Claro/Oscuro) en ThemeService
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return IconButton(
                  // Iconografía dinámica inteligente
                  icon: Icon(
                    themeService.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    themeService
                        .toggleTheme(); // Cortocircuita la fuente de luz
                  },
                  tooltip: themeService.isDarkMode
                      ? 'Desactivar Modo Oscuro'
                      : 'Activar Modo Nocturno',
                );
              },
            ),
          ],
        ),

        // ==========================================
        // LIENZO DINÁMICO (Llama al Switch de arriba)
        // ==========================================
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _construirPagina(),

        // ==========================================
        // BOTÓN FLOTANTE GIGANTE (FAB)
        // ==========================================
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Fuerza la vista 2 (Pantalla de Subir Foto)
            setState(() {
              _selectedIndex = 2;
            });
          },
          backgroundColor:
              Colors.orange, // Destaca por encima del resto grisáceo
          elevation: 4,
          child: const Icon(Icons.add_a_photo, size: 28),
        ),
        // Le indicamos dónde anclarse (Con una clase matemática artesanal abajo)
        floatingActionButtonLocation:
            const CustomFloatingActionButtonLocation(),

        // ==========================================
        // TAPETE DE NAVEGACIÓN INFERIOR (BottomAppBar)
        // ==========================================
        bottomNavigationBar: BottomAppBar(
          // CircularNotchedRectangle muerde el medio de la barra para abrazar al Botón Naranja.
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0, // Aire entre el mordisco y el botón.
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // --- MITAD IZQUIERDA ---
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(0),
                  tooltip: 'Muro Público',
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(1),
                  tooltip: 'Explorar Usuarios',
                ),

                // CRÁTER CENTRAL (Hueco vacío para que quepa el Botón Naranja suspendido arriba)
                const SizedBox(width: 40),

                // --- MITAD DERECHA ---
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(3),
                  tooltip: 'Mi GalerÍa',
                ),
                IconButton(
                  icon: Icon(
                    Icons.manage_accounts,
                    color: _selectedIndex == 4 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _alTocarItem(4),
                  tooltip: 'Panel Personal',
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
// FORMULACIÓN MATEMÁTICA DE DISEÑO (FLUTTER ENGINE UI)
// ==========================================
// Flutter no deja por defecto "hundir" los botones flotantes todo lo que queramos.
// Esta clase hereda del Motor Gráfico y fuerza mecánicamente por coordenadas (XY)
// bajar el logo naranja 30 píxeles más hacia el infierno, para que quede perfectamente encajado.
class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const CustomFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Eje X: Anchura total / 2 = Medio exacto.
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;

    // Eje Y: Coordenadas originales nativas.
    final double standardY =
        scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height / 2.0;

    // MAGIA: Sumamos +30 píxeles extra de gravedad
    return Offset(fabX, standardY + 30.0);
  }
}
