import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/grupo_service.dart';
import 'grupo_detalle_screen.dart';

// ==========================================
// SALA DE ASOCIACIONES: MIS GRUPOS
// ==========================================
// Permite al usuario ver a qué grupos (clanes/colectivos) pertenece,
// crear nuevos grupos desde cero, o unirse a uno existente usando un código secreto.

class MisGruposScreen extends StatefulWidget {
  const MisGruposScreen({Key? key}) : super(key: key);

  @override
  _MisGruposScreenState createState() => _MisGruposScreenState();
}

class _MisGruposScreenState extends State<MisGruposScreen> {
  // Engranaje de carga para evitar que la interfaz se congele durante las peticiones de red
  bool _isLoading = true;

  // ==========================================
  // INICIO DEL MOTOR
  // ==========================================
  @override
  void initState() {
    super.initState();
    // Nada más abrir la pantalla, comprobamos a qué grupos pertenece el ciudadano
    _cargarGrupos();
  }

  // ==========================================
  // DESCARGA DE DATOS (LARAVEL)
  // ==========================================
  Future<void> _cargarGrupos() async {
    setState(() => _isLoading = true);
    try {
      // Exigimos al servidor la lista oficial de grupos en los que estoy enrolado
      await Provider.of<GrupoService>(
        context,
        listen: false,
      ).obtenerMisGrupos();
    } catch (e) {
      if (mounted) {
        // En caso de caída del servidor, sacamos un letrero temporal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fallo en las comunicaciones: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // PASAPORTE DE ENTRADA (UNIRSE A GRUPO)
  // ==========================================
  // Despliega un formulario emergente pidiendo la contraseña/código
  void _mostrarDialogoUnirse() {
    final TextEditingController codigoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alistarse a un Batallón'),
        content: TextField(
          controller: codigoCtrl,
          decoration: const InputDecoration(
            labelText: 'Pase de Acceso (Código)',
            hintText: 'Ej: alfa123omega',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Huir del formulario
            child: const Text('Retirada'),
          ),
          ElevatedButton(
            onPressed: () async {
              final codigo = codigoCtrl.text.trim();
              if (codigo.isEmpty)
                return; // Si está vacío, ni nos molestamos en hablar con Laravel

              Navigator.of(ctx).pop(); // Esconde el formulario visual

              setState(
                () => _isLoading = true,
              ); // Enciende la rueda de carga principal de la pantalla
              try {
                // Trámite de inserción en la Base de Datos
                await Provider.of<GrupoService>(
                  context,
                  listen: false,
                ).unirseGrupo(codigo);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alistamiento completado con éxito'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error en frontera: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Cruzar Puerta'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FUNDAR UNA NUEVA ASOCIACIÓN (CREAR GRUPO)
  // ==========================================
  // Despliega un formulario emergente pidiendo Nombre y Descripción
  void _mostrarDialogoCrear() {
    final TextEditingController nombreCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fundar un Grupo Oficial'),
        content: Column(
          mainAxisSize: MainAxisSize
              .min, // Que el popup ocupe solo la altura de sus hijos
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Asociación *',
              ),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Misión del grupo'),
              maxLines: 2, // Espacio para explayarse
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar Acto'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              final desc = descCtrl.text.trim();

              // Validación estricta: No podemos fundar un grupo sin nombre
              if (nombre.isEmpty) return;

              Navigator.of(ctx).pop(); // Destruye el popup

              setState(() => _isLoading = true);
              try {
                // Llamada de constructor de mundos a Laravel
                await Provider.of<GrupoService>(
                  context,
                  listen: false,
                ).crearGrupo(nombre, desc);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Grupo fundado e inscrito en los registros',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El tribunal rechazó la solicitud: $e'),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ENSAMBLAJE VISUAL (BUILD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Escolta de datos: Se chiva cada vez que la colección misGrupos cambia
    final grupos = Provider.of<GrupoService>(context).misGrupos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asociaciones Ciudadanas'),
        actions: [
          // Botón Superior Derecho para Fundar Grupos
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Fundar Grupo',
            onPressed: _mostrarDialogoCrear,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // Si tiran hacia abajo re-preguntamos a Laravel
              onRefresh: _cargarGrupos,
              child: grupos.isEmpty
                  // ==========================================
                  // PANTALLA DE SOLEDAD (Cero Grupos)
                  // ==========================================
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.group_off,
                            size: 80,
                            color: Colors.grey, // Tristeza visual
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Eres un lobo solitario. No perteneces a ningún grupo.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          // Botón Central Reducido
                          ElevatedButton.icon(
                            icon: const Icon(Icons.group_add),
                            label: const Text('Unirme por código Secreto'),
                            onPressed: _mostrarDialogoUnirse,
                          ),
                          const SizedBox(height: 40),
                          // Chivato de Ingeniería (Trace Log) por si algo falla en Base de Datos
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SelectableText(
                              Provider.of<GrupoService>(context).lastDebugInfo,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  // ==========================================
                  // CATÁLOGO DE MIS ALIANZAS
                  // ==========================================
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
                            // Logotipo Dinámico: Toma la primera letra del nombre del Grupo
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                g.nombre[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            // Nombre Oficial
                            title: Text(
                              g.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Censo del Grupo
                            subtitle: Text(
                              '${g.usuarios.length} ciudadanos enrolados',
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ), // Flecha a la derecha
                            // Si tocas el grupo, te metes a su cuartel general (Detalles)
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

      // ==========================================
      // BOTÓN FLOTANTE INFERIOR DERECHO
      // ==========================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoUnirse,
        label: const Text('Alistarse'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
