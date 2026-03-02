import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

// Pantalla para la gestión de usuarios por el administrador
class UsersControlScreen extends StatefulWidget {
  const UsersControlScreen({super.key});

  @override
  State<UsersControlScreen> createState() => _UsersControlScreenState();
}

class _UsersControlScreenState extends State<UsersControlScreen> {
  bool _isLoading = false;
  List<User> _users = [];
  String _searchQuery = '';
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final users = await authService.obtenerUsuarios();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los usuarios: $e')),
        );
      }
    }
  }

  Future<void> _eliminarUsuario(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar usuario?'),
        content: const Text(
          'Esta acción no se puede deshacer. Se borrarán todos sus datos y fotografías.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthService>(
          context,
          listen: false,
        ).eliminarUsuario(id);

        await _cargarUsuarios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado correctamente')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el usuario: $e')),
          );
        }
      }
    }
  }

  void _mostrarDialogoEdicion(User user) {
    String rolSeleccionado = user.rol;
    bool vetadoSeleccionado = user.vetado;

    bool esVetoPermanente = true;
    DateTime? fechaVetoSeleccionada;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Editar usuario: ${user.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol del usuario',
                  ),
                  items: ['usuario', 'admin'].map((rol) {
                    return DropdownMenuItem(
                      value: rol,
                      child: Text(rol.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => rolSeleccionado = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('¿Vetar usuario?'),
                  subtitle: const Text('Bloquea su acceso a la app'),
                  value: vetadoSeleccionado,
                  onChanged: (val) {
                    setDialogState(() => vetadoSeleccionado = val);
                  },
                ),
                if (vetadoSeleccionado) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'Permanente',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: true,
                          groupValue: esVetoPermanente,
                          onChanged: (val) {
                            setDialogState(() => esVetoPermanente = val!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'Temporal (Fecha)',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: false,
                          groupValue: esVetoPermanente,
                          onChanged: (val) {
                            setDialogState(() => esVetoPermanente = val!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  if (!esVetoPermanente)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        fechaVetoSeleccionada == null
                            ? 'Seleccionar fecha...'
                            : 'Hasta el: ${fechaVetoSeleccionada!.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (date != null) {
                          setDialogState(() => fechaVetoSeleccionada = date);
                        }
                      },
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? fechaVetoStr;

                  if (vetadoSeleccionado && !esVetoPermanente) {
                    if (fechaVetoSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona una fecha de fin de veto'),
                        ),
                      );
                      return;
                    }
                    fechaVetoStr = fechaVetoSeleccionada!
                        .toIso8601String()
                        .split('T')[0];
                  }

                  Navigator.of(ctx).pop();
                  _guardarCambiosUsuario(
                    user.id,
                    rolSeleccionado,
                    vetadoSeleccionado,
                    fechaVeto: fechaVetoStr,
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardarCambiosUsuario(
    int id,
    String rol,
    bool vetado, {
    String? fechaVeto,
  }) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).editarUsuario(id, rol, vetado, fechaVeto: fechaVeto);

      await _cargarUsuarios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar cambios: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text('No hay usuarios registrados.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar por nombre o correo...',
                      prefixIcon: const Icon(Icons.person_search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Nombre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Correo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Rol',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Estado',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Acciones',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _users
                                    .where(
                                      (u) =>
                                          u.name.toLowerCase().contains(
                                            _searchQuery,
                                          ) ||
                                          u.email.toLowerCase().contains(
                                            _searchQuery,
                                          ),
                                    )
                                    .map((user) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(user.name)),
                                          DataCell(Text(user.email)),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: user.rol == 'admin'
                                                    ? Colors.blueGrey
                                                    : Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                user.rol,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: user.vetado
                                                    ? Colors.red
                                                    : Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                user.vetado
                                                    ? 'Vetado'
                                                    : 'Activo',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed: () =>
                                                      _mostrarDialogoEdicion(
                                                        user,
                                                      ),
                                                  tooltip: 'Editar',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _eliminarUsuario(user.id),
                                                  tooltip: 'Eliminar',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
