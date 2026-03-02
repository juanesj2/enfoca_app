import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/photo_service.dart';
import '../widgets/photo_item.dart';

// Pantalla que muestra las fotos del usuario o los resultados de búsqueda.

class FotosUsuarioScreen extends StatefulWidget {
  // Indica si la pantalla está en modo búsqueda o modo "Mis Fotos".
  final bool isSearchMode;

  const FotosUsuarioScreen({super.key, this.isSearchMode = false});

  @override
  State<FotosUsuarioScreen> createState() => _FotosUsuarioScreenState();
}

class _FotosUsuarioScreenState extends State<FotosUsuarioScreen> {
  var _isInit = true;
  var _isLoading = false;
  var _isSearching = false;
  String _tipoBusqueda = 'usuario';

  final _searchController = TextEditingController();

  // ==========================================
  // ESTADO Y CICLO DE VIDA
  // ==========================================

  @override
  void didChangeDependencies() {
    if (_isInit) {
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
                  const SnackBar(content: Text('Error al cargar las fotos')),
                );
              }
            });
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // ==========================================
  // LÓGICA DE BÚSQUEDA
  // ==========================================

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

        if (RegExp(r'^[0-9]+$').hasMatch(input)) {
          userId = int.tryParse(input);
        } else {
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

        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).obtenerFotosUsuario(userId, forcedUserName: userName);
      } else {
        await Provider.of<PhotoService>(
          context,
          listen: false,
        ).buscarFotosAvanzado(_tipoBusqueda, input);
      }

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al realizar la búsqueda.')),
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
  // INTERFAZ DE USUARIO
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final photos = widget.isSearchMode
        ? Provider.of<PhotoService>(context).itemsUsuarioBuscado
        : Provider.of<PhotoService>(context).misItems;

    final appBarTitle = widget.isSearchMode ? 'Búsqueda' : 'Mis Fotos';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
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
                              child: Text('Título o descripción'),
                            ),
                            DropdownMenuItem(value: 'iso', child: Text('ISO')),
                            DropdownMenuItem(
                              value: 'fecha',
                              child: Text('Fecha (YYYY-MM-DD)'),
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
                                ? 'Ej: 2025-05-18'
                                : 'Escribe aquí...',
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSearching ? null : _realizarBusqueda,
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Buscar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // --- LISTA DE FOTOS ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
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
                                  ? 'La central de datos confirmó cero coincidencias.'
                                  : 'Inventario Fotográfico Inmaculado.',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
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
