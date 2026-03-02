import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/grupo_service.dart';
import 'grupo_detalle_screen.dart';

// Pantalla para ver mis grupos, crear uno nuevo o unirme con un código
class MisGruposScreen extends StatefulWidget {
  const MisGruposScreen({super.key});

  @override
  State<MisGruposScreen> createState() => _MisGruposScreenState();
}

class _MisGruposScreenState extends State<MisGruposScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<GrupoService>(
        context,
        listen: false,
      ).obtenerMisGrupos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarDialogoUnirse() {
    final TextEditingController codigoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unirse a un Grupo'),
        content: TextField(
          controller: codigoCtrl,
          decoration: const InputDecoration(
            labelText: 'Código del grupo',
            hintText: 'Ej: alfa123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final codigo = codigoCtrl.text.trim();
              if (codigo.isEmpty) return;

              Navigator.of(ctx).pop();

              setState(() => _isLoading = true);
              try {
                await Provider.of<GrupoService>(
                  context,
                  listen: false,
                ).unirseGrupo(codigo);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Te has unido al grupo correctamente.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al unirse: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrear() {
    final TextEditingController nombreCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear nuevo grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del grupo *',
              ),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              final desc = descCtrl.text.trim();

              if (nombre.isEmpty) return;

              Navigator.of(ctx).pop();

              setState(() => _isLoading = true);
              try {
                await Provider.of<GrupoService>(
                  context,
                  listen: false,
                ).crearGrupo(nombre, desc);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grupo creado correctamente.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear el grupo: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = Provider.of<GrupoService>(context).misGrupos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Crear Grupo',
            onPressed: _mostrarDialogoCrear,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarGrupos,
              child: grupos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.group_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No perteneces a ningún grupo.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.group_add),
                            label: const Text('Unirme con un código'),
                            onPressed: _mostrarDialogoUnirse,
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SelectableText(
                              Provider.of<GrupoService>(context).lastDebugInfo,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.transparent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: grupos.length,
                      itemBuilder: (ctx, i) {
                        final g = grupos[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                g.nombre[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              g.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${g.usuarios.length} miembros'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) =>
                                      GrupoDetalleScreen(grupo: g),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoUnirse,
        label: const Text('Unirme'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
