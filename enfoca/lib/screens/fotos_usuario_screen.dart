import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../widgets/photo_item.dart';

// Cambiamos el nombre de MisFotosScreen a FotosUsuarioScreen para que sea mas genérico
class FotosUsuarioScreen extends StatefulWidget {
  final bool isSearchMode; // Indica si estamos en modo buscador

  // Por defecto, isSearchMode es false (modo "Mis Fotos")
  const FotosUsuarioScreen({super.key, this.isSearchMode = false});

  @override
  State<FotosUsuarioScreen> createState() => _FotosUsuarioScreenState();
}

class _FotosUsuarioScreenState extends State<FotosUsuarioScreen> {
  // ********** Variables de Estado ********** //
  var _isInit = true; // Controla carga inicial
  var _isLoading = false; // Controla spinner general
  var _isSearching = false; // Controla spinner especifico de busqueda
  final _searchController =
      TextEditingController(); // Controlador del input de busqueda
  // ********** FIN Variables de Estado ********** //

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
              setState(() {
                _isLoading = false;
              });
            })
            .catchError((error) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al cargar mis fotos')),
              );
            });
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // Método para buscar fotos de un usuario
  Future<void> _buscarUsuario() async {
    final input = _searchController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    int? userId;

    // Intentamos ver si es un número (ID directo)
    if (RegExp(r'^[0-9]+$').hasMatch(input)) {
      userId = int.tryParse(input);
    } else {
      // Si no es numero, buscamos por nombre
      try {
        userId = await Provider.of<PhotoService>(
          context,
          listen: false,
        ).buscarIdUsuarioPorNombre(input);

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no encontrado')),
          );
          setState(() {
            _isSearching = false;
          });
          return;
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al buscar usuario por nombre')),
        );
        setState(() {
          _isSearching = false;
        });
        return;
      }
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor introduce un nombre o ID válido'),
        ),
      );
      setState(() {
        _isSearching = false;
      });
      return;
    }

    try {
      // Llamamos al servicio para buscar las fotos con la ID resuelta
      await Provider.of<PhotoService>(
        context,
        listen: false,
      ).obtenerFotosUsuario(userId);

      // Opcional: Limpiar el campo o cerrar teclado
      FocusScope.of(context).unfocus();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar fotos del usuario')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decidimos qué lista de fotos mostrar según el modo
    final photos = widget.isSearchMode
        ? Provider.of<PhotoService>(context).itemsUsuarioBuscado
        : Provider.of<PhotoService>(context).misItems;

    // Título de la AppBar dependiente del modo
    final appBarTitle = widget.isSearchMode
        ? 'Buscar Usuario'
        : 'Mis Fotos Subidas';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Column(
        children: [
          // ********** AREA DE BUSQUEDA (Solo visible en modo busqueda) ********** //
          if (widget.isSearchMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar usuario',
                        hintText: 'Introduce Nombre o ID',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text, // Cambiado a texto
                      onSubmitted: (_) => _buscarUsuario(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _buscarUsuario,
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Buscar'),
                  ),
                ],
              ),
            ),
          // ********** FIN AREA DE BUSQUEDA ********** //

          // ********** LISTA DE FOTOS ********** //
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    // Al recargar: si es modo búsqueda recarga la búsqueda, si no recarga mis fotos
                    onRefresh: () async {
                      if (widget.isSearchMode) {
                        if (_searchController.text.isNotEmpty)
                          await _buscarUsuario();
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
          // ********** FIN LISTA DE FOTOS ********** //
        ],
      ),
    );
  }
}
