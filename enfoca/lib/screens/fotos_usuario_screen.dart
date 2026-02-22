import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../widgets/photo_item.dart';

// ==========================================
// PANTALLA DE FOTOS DE USUARIO (BÚSQUEDA Y MIS FOTOS)
// ==========================================

class FotosUsuarioScreen extends StatefulWidget {
  final bool isSearchMode; // Indica si estamos en modo buscador

  // Por defecto, isSearchMode es false (modo "Mis Fotos")
  const FotosUsuarioScreen({super.key, this.isSearchMode = false});

  @override
  State<FotosUsuarioScreen> createState() => _FotosUsuarioScreenState();
}

class _FotosUsuarioScreenState extends State<FotosUsuarioScreen> {
  // ==========================================
  // ESTADO (STATE)
  // ==========================================
  var _isInit = true; // Controla carga inicial
  var _isLoading = false; // Controla spinner general
  var _isSearching = false; // Controla spinner específico de búsqueda
  String _tipoBusqueda = 'usuario'; // Tipo de búsqueda seleccionado
  final _searchController =
      TextEditingController(); // Controlador del input de búsqueda

  // ==========================================
  // CICLO DE VIDA
  // ==========================================

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // Solo cargamos automáticamente si NO es modo búsqueda (es decir, "Mis Fotos")
      if (!widget.isSearchMode) {
        setState(() {
          _isLoading = true;
        });
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al cargar mis fotos')),
                );
              }
            });
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // ==========================================
  // MÉTODOS DE BÚSQUEDA
  // ==========================================

  // Método para buscar fotos
  Future<void> _realizarBusqueda() async {
    final input = _searchController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      if (_tipoBusqueda == 'usuario') {
        int? userId;
        String? userName;

        // Intentamos ver si es un número (ID directo)
        if (RegExp(r'^[0-9]+$').hasMatch(input)) {
          userId = int.tryParse(input);
        } else {
          // Si no es número, buscamos por nombre
          final user = await Provider.of<PhotoService>(
            context,
            listen: false,
          ).buscarUsuarioPorNombre(input);
          if (user != null) {
            userId = user.id;
            userName = user.name;
          }
        }

        if (userId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuario no encontrado')),
            );
            setState(() => _isSearching = false);
          }
          return;
        }

        // Llamamos al servicio original
        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).obtenerFotosUsuario(userId, forcedUserName: userName);
      } else {
        // Usamos la nueva búsqueda avanzada global
        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).buscarFotosAvanzado(_tipoBusqueda, input);
      }

      // Opcional: Limpiar el campo o cerrar teclado
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar resultados de búsqueda'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Decidimos qué lista de fotos mostrar según el modo
    final photos = widget.isSearchMode
        ? Provider.of<PhotoService>(context).itemsUsuarioBuscado
        : Provider.of<PhotoService>(context).misItems;

    // Título de la AppBar dependiente del modo
    final appBarTitle = widget.isSearchMode ? 'Buscador' : 'Mis Fotos Subidas';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Column(
        children: [
          // ==========================================
          // ÁREA DE BÚSQUEDA (SOLO VISIBLE EN MODO BÚSQUEDA)
          // ==========================================
          if (widget.isSearchMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Buscar por:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _tipoBusqueda,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'usuario',
                              child: Text('Usuario (Nombre o ID)'),
                            ),
                            DropdownMenuItem(
                              value: 'texto',
                              child: Text('Título o Descripción'),
                            ),
                            DropdownMenuItem(
                              value: 'iso',
                              child: Text('ISO (Ej: 100, 400)'),
                            ),
                            DropdownMenuItem(
                              value: 'fecha',
                              child: Text('Fecha (AAAA-MM-DD)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _tipoBusqueda = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Término de búsqueda',
                            hintText: _tipoBusqueda == 'fecha'
                                ? '2025-10-31'
                                : 'Introduce tu búsqueda...',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: _tipoBusqueda == 'iso'
                              ? TextInputType.number
                              : TextInputType.text,
                          onSubmitted: (_) => _realizarBusqueda(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _realizarBusqueda,
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Buscar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ==========================================
          // LISTA DE FOTOS
          // ==========================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    // Al recargar: si es modo búsqueda recarga la búsqueda, si no recarga mis fotos
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
                    child: photos.isEmpty
                        ? Center(
                            child: Text(
                              widget.isSearchMode
                                  ? 'No hay resultados. Este usuario no ha subido nada.'
                                  : 'No has subido ninguna foto todavía.',
                            ),
                          )
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
