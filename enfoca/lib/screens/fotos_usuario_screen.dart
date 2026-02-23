import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../widgets/photo_item.dart';

// ==========================================
// PANTALLA POLIVALENTE: BUSCADOR GLOBAL Y MIS FOTOS
// ==========================================
// Este Widget es un "Dos en Uno". Se usa tanto para mostrar las fotos
// que ha subido el usuario actual (Modo Mis Fotos), como para invocar
// un buscador masivo con filtros por todo el Backend (Modo Búsqueda).

class FotosUsuarioScreen extends StatefulWidget {
  // Bandera física. Si es True: Se pinta el campo de texto y la Lupa.
  // Si es False: Se oculta toda la cabecera de búsqueda y solo trae "Mis Fotos".
  final bool isSearchMode;

  // Constructor: Por defecto asume que es la pantalla inofensiva de "Mis Fotos".
  const FotosUsuarioScreen({super.key, this.isSearchMode = false});

  @override
  State<FotosUsuarioScreen> createState() => _FotosUsuarioScreenState();
}

class _FotosUsuarioScreenState extends State<FotosUsuarioScreen> {
  // ==========================================
  // ESTADO INTERNO (VARIABLES MUTABLES)
  // ==========================================
  var _isInit =
      true; // Trampa de encendido para evitar bucles infinitos en build().
  var _isLoading =
      false; // "Cargando" gigante que ocupa toda la pantalla de inicio.
  var _isSearching =
      false; // "Cargando" chiquitito que solo sale dentro del botón Buscar.
  String _tipoBusqueda =
      'usuario'; // Opción seleccionada por defecto en el Desplegable.

  // Mando a distancia (Controlador) para leer lo que ha escrito el usuario.
  final _searchController = TextEditingController();

  // ==========================================
  // HOOKS DE MONTAJE Y DESCARGA INICIAL
  // ==========================================

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // ¿Es la Pestaña de Búsqueda? NO HAGAS NADA. Espera a que escriban.
      // ¿Es la Pestaña de Mis Fotos? Arranca los motores y haz un SELECT a la Base de Datos.
      if (!widget.isSearchMode) {
        setState(() {
          _isLoading = true; // Baja el telón
        });
        Provider.of<PhotoService>(context)
            .obtenerMisFotos()
            .then((_) {
              if (mounted) {
                setState(() {
                  _isLoading = false; // Sube el telón
                });
              }
            })
            .catchError((error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                // Fallback (Ej. Base de datos caída)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al procesar el archivo fotográfico'),
                  ),
                );
              }
            });
      }
    }
    _isInit = false; // Cierra la puerta para que no se vuelva a ejecutar
    super.didChangeDependencies();
  }

  // ==========================================
  // MOTOR DE CONSULTAS AL SERVIDOR (REST API)
  // ==========================================

  // Se dispara al apretar el botón [Buscar] o pulsar "Enter" en el teclado táctil móvil.
  Future<void> _realizarBusqueda() async {
    final input = _searchController.text
        .trim(); // Cogemos el texto y le quitamos espacios fantasmas
    if (input.isEmpty)
      return; // Si buscan "nada", abortamos. No queremos quemar al servidor.

    setState(() {
      _isSearching = true; // Encendemos el mini-Loader azul del botón
    });

    try {
      // --- RAMA 1: BÚSQUEDA HUMANA (Por Nombre de Usuario o por ID Exacto) ---
      if (_tipoBusqueda == 'usuario') {
        int? userId;
        String? userName;

        // RegExp (Expresión Regular): Comprueba si el texto ingresado SOLO contiene números.
        if (RegExp(r'^[0-9]+$').hasMatch(input)) {
          // Es un DNI/ID matemático
          userId = int.tryParse(input);
        } else {
          // Es un texto humano (Ej. "Juan").
          // Hacemos una precondición: Llamamos a Laravel para preguntar
          // "¿Existe algún usuario con este nombre?". Y Laravel devuelve su Ficha Completa.
          final user = await Provider.of<PhotoService>(
            context,
            listen: false,
          ).buscarUsuarioPorNombre(input);

          if (user != null) {
            userId = user.id; // ¡BINGO! Extraemos su matrícula interna.
            userName = user.name;
          }
        }

        // Si después de todo, no tenemos ningún ID numérico, el perfil no existe.
        if (userId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fantasma digital: Usuario no encontrado'),
              ),
            );
            setState(() => _isSearching = false);
          }
          return;
        }

        // Ya sea por ID o porque lo tradujimos mediante su Nombre, solicitamos
        // que nos descargue toda la galería personal de ESE usuario específico.
        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).obtenerFotosUsuario(userId, forcedUserName: userName);
      }
      // --- RAMA 2: BÚSQUEDA ALGORÍTMICA (Metadatos: ISO, Textos, Fechas) ---
      else {
        // Ejecutamos el motor de inteligencia avanzada de Laravel que cruza múltiples tablas.
        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).buscarFotosAvanzado(_tipoBusqueda, input);
      }

      // UX Perfection: Si todo salió bien, cerramos el teclado táctil de Android/iOS
      // automáticamente para que la pantalla quede limpia y deje ver los resultados (Unfocus).
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de comunicaciones al sondear resultados.'),
          ),
        );
      }
    } finally {
      // Pase lo que pase (éxito o explosión nuclear del PHP), apagamos la ruletita.
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // ==========================================
  // ARQUITECTURA GRÁFICA (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Ternario de asignación: Si estoy buscando actúo de una forma, si es "Mis fotos" de otra.
    // Provider trae de la RAM de la app la matriz de elementos que toca pintar.
    final photos = widget.isSearchMode
        ? Provider.of<PhotoService>(context).itemsUsuarioBuscado
        : Provider.of<PhotoService>(context).misItems;

    // Dinamismo de Título Superior
    final appBarTitle = widget.isSearchMode
        ? 'Radar de Búsqueda'
        : 'Mi Galería Fotográfica';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Column(
        children: [
          // ==========================================
          // 1. CONSOLA DE BÚSQUEDA SUPERIOR (Condicional)
          // ==========================================
          // La cláusula 'if' en Flutter dentro de una Lista (Column) inyecta Widgets
          // dinámicamente. Todo esto NO EXISTE si estás viendo tus propias fotos.
          if (widget.isSearchMode)
            Padding(
              // "Padding" en Flutter es el equivalente al "Margin/Padding" de CSS
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // --- FILA 1: Menú Desplegable (Criterio Selectivo) ---
                  Row(
                    children: [
                      const Text(
                        'Criterio Múltiple:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        // DropdownButton es la clásica lista que cae hacia abajo al clicar (HTML Select)
                        child: DropdownButton<String>(
                          value:
                              _tipoBusqueda, // Valor reactivo atado al estado
                          isExpanded: true, // Se estira 100% el ancho
                          items: const [
                            DropdownMenuItem(
                              value: 'usuario',
                              child: Text('Individuo (Nickname o IDNumérico)'),
                            ),
                            DropdownMenuItem(
                              value: 'texto',
                              child: Text('Análisis Semántico (Título/Letra)'),
                            ),
                            DropdownMenuItem(
                              value: 'iso',
                              child: Text(
                                'Sensibilidad Lumínica (ISO 100-3200)',
                              ), // Solo números
                            ),
                            DropdownMenuItem(
                              value: 'fecha',
                              child: Text('Efeméride (Formato YYYY-MM-DD)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              // Al cambiar de categoría, repinta para cambiar los hintTexts
                              setState(() => _tipoBusqueda = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- FILA 2: Input de Texto y Botón Lanzador ---
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              _searchController, // Enchufamos la tubería de datos
                          decoration: InputDecoration(
                            labelText: 'Patrón a trazar',
                            // Placeholder Adaptativo (Cambia según el Dropdown)
                            hintText: _tipoBusqueda == 'fecha'
                                ? 'Ej: 2025-05-18'
                                : 'Inserte coordenadas semánticas...',
                            prefixIcon: const Icon(Icons.saved_search),
                            border:
                                const OutlineInputBorder(), // Enmarca la caja de texto
                          ),
                          // Inteligencia del teclado móvil nativo. Si buscan ISO, lanza el
                          // teclado numérico (123). Si buscan Usuario, saca el alfanumérico (QWERTY).
                          keyboardType: _tipoBusqueda == 'iso'
                              ? TextInputType.number
                              : TextInputType.text,
                          // Si el chaval es impaciente y le da al Intro del Teclado móvil...
                          onSubmitted: (_) => _realizarBusqueda(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // BOTÓN DISPARADOR PRINCIPAL
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        // "Null" deshabilita físicamente el botón para evitar doble-clicks salvajes
                        onPressed: _isSearching ? null : _realizarBusqueda,
                        // ¿Está buscando? Saca spinner chiquitito. ¿No? Saca texto normal.
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Rastrear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ==========================================
          // 2. PARRILLA RESULTANTE DE IMÁGENES
          // ==========================================
          // Expanded se traga el 100% de los píxeles blancos que quedan libres hasta abajo.
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Cargando masivo central
                : RefreshIndicator(
                    // Alambramos el refresco pull-to-down.
                    // Si tira de la cuerda en "Búsqueda": Vuelve a escupir la misma búsqueda.
                    // Si tira de la cuerda en "Mis Fotos": Actualiza sus propias fotos en vivo.
                    onRefresh: () async {
                      if (widget.isSearchMode) {
                        if (_searchController.text.isNotEmpty)
                          await _realizarBusqueda();
                      } else {
                        await Provider.of<PhotoService>(
                          context,
                          listen: false,
                        ).obtenerMisFotos();
                      }
                    },
                    // ¿El backend devolvió una lista en blanco? []
                    child: photos.isEmpty
                        ? Center(
                            child: Text(
                              widget.isSearchMode
                                  ? 'La central de datos confirmó cero coincidencias.'
                                  : 'Inventario Fotográfico Inmaculado.',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        // Bucle iterativo perezoso (ListView.builder). Crea la "Card" de la foto una a una.
                        : ListView.builder(
                            itemCount: photos.length,
                            itemBuilder: (ctx, i) =>
                                PhotoItem(photo: photos[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
