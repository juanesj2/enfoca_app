import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

// ==========================================
// REGISTRO CIVIL: CONTROL DE USUARIOS
// ==========================================
// Permite al Administrador buscar, editar roles (hacer admin a otros),
// vetar (banear temporal o permanentemente) y eliminar cuentas del sistema.

class UsersControlScreen extends StatefulWidget {
  const UsersControlScreen({super.key});

  @override
  State<UsersControlScreen> createState() => _UsersControlScreenState();
}

class _UsersControlScreenState extends State<UsersControlScreen> {
  // ==========================================
  // ESTADO INTERNO (MEMORIA A CORTO PLAZO)
  // ==========================================
  bool _isLoading = false; // Engranaje giratorio de red
  List<User> _users = []; // Toda la población mundial descargada

  // Archiva lo que el administrador teclee en el buscador:
  String _searchQuery = '';

  // Controlador especial para mover la tabla de lado a lado (Desplazamiento Horizontal)
  final ScrollController _horizontalScrollController = ScrollController();

  // ==========================================
  // MOTOR DE ARRANQUE Y APAGADO
  // ==========================================

  @override
  void initState() {
    super.initState();
    // Reclutar a todos los ciudadanos nada más abrir el panel.
    _cargarUsuarios();
  }

  @override
  void dispose() {
    // Liberar recursos de memoria al cerrar la pantalla (Como cerrar un grifo)
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // COMUNICACIONES CON EL MINISTERIO (LARAVEL)
  // ==========================================

  // --- DESCARGAR CENSO GLOBAL ---
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
          SnackBar(content: Text('Error al contactar con el padrón: $e')),
        );
      }
    }
  }

  // --- SENTENCIA DE MUERTE DE UNA CUENTA ---
  Future<void> _eliminarUsuario(int id) async {
    // Dialogo de confirmación por si se le resbala el dedo al Admin
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Erradicar ciudadano?'),
        content: const Text(
          'Esta acción no se puede deshacer. Se borrarán todos sus datos, fotos, y recuerdos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tener Piedad'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Liquidar'),
          ),
        ],
      ),
    );

    // ¿El Juez dictó veredicto de muerte?
    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthService>(
          context,
          listen: false,
        ).eliminarUsuario(id);

        await _cargarUsuarios(); // Recargar la tabla sin el difunto
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ciudadano eliminado del sistema')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al ejecutar la liquidación: $e')),
          );
        }
      }
    }
  }

  // ==========================================
  // TRIBUNAL DE MODIFICACIÓN: (BANEOS Y ROLES)
  // ==========================================
  // Muestra un formulario en ventana emergente (Modal)
  void _mostrarDialogoEdicion(User user) {
    // Clonamos datos actuales a variables temporales locales
    // Si cancela a mitad de formulario, no corrompemos nada.
    String rolSeleccionado = user.rol;
    bool vetadoSeleccionado = user.vetado;

    // El Baneo Mágico: Por defecto es permanente, pero se puede poner temporal
    bool esVetoPermanente = true;
    DateTime? fechaVetoSeleccionada;

    // StatefulBuilder es crucial: hace que el Checkbox "reaccione" solo dentro de la cajita.
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Expediente de: ${user.name}'),
            content: Column(
              mainAxisSize:
                  MainAxisSize.min, // Que el popup mida lo justo y necesario
              children: [
                // --- SELECTOR DE ROL (Dropdown) ---
                DropdownButtonFormField<String>(
                  value: rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Poder Jerárquico',
                  ),
                  // Opciones hardcodeadas (De usuario raso a semidiós)
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

                // --- BOTÓN DEL PANICO (Baneo Total) ---
                SwitchListTile(
                  title: const Text('¿Cárcel (Ban)?'),
                  subtitle: const Text(
                    'Bloquea su entrada a la app por completo',
                  ),
                  value: vetadoSeleccionado,
                  onChanged: (val) {
                    setDialogState(() => vetadoSeleccionado = val);
                  },
                ),

                // --- SI ESTÁ BANEADO, PREGUNTAMOS LA CONDENA ---
                if (vetadoSeleccionado) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Radio Cadena Perpetua
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'Cadena Perpetua',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: true,
                          groupValue:
                              esVetoPermanente, // Si coinciden, se pinta azul
                          onChanged: (val) {
                            setDialogState(() => esVetoPermanente = val!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      // Radio Castigo Temporal
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'Castigo Temporal (Fecha)',
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

                  // --- CALENDARIO DEL JUEZ ---
                  // Solo sale si elegimos "Castigo Temporal" (false)
                  if (!esVetoPermanente)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        fechaVetoSeleccionada == null
                            ? 'Abrir calendario...'
                            // Extrae solo "2024-05-12" de la mega-fecha ISO
                            : 'Libre el: ${fechaVetoSeleccionada!.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        // Invoca el calendario nativo de Android/iOS/Web
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1), // Mañana por defecto
                          ),
                          firstDate:
                              DateTime.now(), // No puedes banear en el pasado
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650), // Máximo 10 años
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

            // --- BOTONES DE ENVÍO Y CÁLCULO FINAL ---
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(), // Cierra modal
                child: const Text('Atrás'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? fechaVetoStr;

                  // Validación: Si lo banea temporalmente sin poner fecha, bloqueamos el guardado.
                  if (vetadoSeleccionado && !esVetoPermanente) {
                    if (fechaVetoSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Debes seleccionar un día de salida de prisión',
                          ),
                        ),
                      );
                      return; // Cortocircuito, no avanza
                    }
                    // Formatear la fecha al estilo SQL: "YYYY-MM-DD"
                    fechaVetoStr = fechaVetoSeleccionada!
                        .toIso8601String()
                        .split('T')[0];
                  }

                  Navigator.of(ctx).pop(); // Esconde popup
                  // Manda el cohete al servidor
                  _guardarCambiosUsuario(
                    user.id,
                    rolSeleccionado,
                    vetadoSeleccionado,
                    fechaVeto: fechaVetoStr,
                  );
                },
                child: const Text('Ejecutar Sentencia'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- TRANSICIÓN A LA BASE DE DATOS ---
  Future<void> _guardarCambiosUsuario(
    int id,
    String rol,
    bool vetado, {
    String? fechaVeto, // Argumento opcional por nombre ({})
  }) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).editarUsuario(id, rol, vetado, fechaVeto: fechaVeto);

      await _cargarUsuarios(); // Recargar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decreto administrativo aplicado con éxito'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Rebelión en el servidor: $e')));
      }
    }
  }

  // ==========================================
  // ENSAMBLAJE VISUAL (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ministerio de Identidad (Usuarios)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text('Planeta deshabitado. 0 Usuarios.'))
          // COLUMNA PRINCIPAL que dividimos en Buscador (Arriba) y Tabla (Centro)
          : Column(
              children: [
                // ==========================================
                // BARRA DE BÚSQUEDA DEL FBI
                // ==========================================
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
                    // Cada vez que pulsas una tecla, actualiza la variable "searchQuery"
                    // Lo cual dispara un setState masivo, reescribiendo la tabla en vivo.
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value
                            .toLowerCase(); // Ignorar Mayúsculas
                      });
                    },
                  ),
                ),

                // ==========================================
                // HOJA DE CÁLCULO EXTREMA (DATA TABLE)
                // ==========================================
                // "Expanded" es vital: le dice a la tabla "Ocupa todo el alto que sobre"
                Expanded(
                  // LayoutBuilder + ConstrainedBox es un truco oscuro de Flutter Web/Desktop
                  // Permite que la tabla ocupe su ancho mínimo si estamos en móvil,
                  // pero si estamos en Pantalla Panorámica, se estire a los bordes.
                  child: LayoutBuilder(
                    builder: (context, constraints) => ScrollConfiguration(
                      // Permite arrastrar la tabla lateralmente usando el Ratón (Cosas de Web)
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: Scrollbar(
                        // Barra visual inferior
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        // Primer Scroll: De Derecha a Izquierda
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            // Segundo Scroll: De Arriba Abajo
                            child: SingleChildScrollView(
                              // Datatable estándar de Material UI (Filas y Columnas rígidas)
                              child: DataTable(
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Identidad',
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
                                      'Poder',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Alerta Civil',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Acciones Legales',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],

                                // EL FILTRO MAGICO:
                                // Tomamos todos los usuarios.
                                // Con `where` revisamos si el nombre CONTIENE las letras del buscador.
                                // Con `map` transformamos al superviviente en un DataRow (Fila).
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

                                          // Celda "Rol": Un pastillero (Container) de colores. Admin es más oscuro.
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

                                          // Celda "Vetado": Semáforo Verde (Activo) y Rojo Cuidado (Vetado)
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
                                                    ? 'Muro Bloqueado'
                                                    : 'Ciudadano Libre',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Celda Botonera
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue, // Lápiz
                                                  ),
                                                  onPressed: () =>
                                                      _mostrarDialogoEdicion(
                                                        user,
                                                      ),
                                                  tooltip: 'Editar Poderes',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red, // Basura
                                                  ),
                                                  onPressed: () =>
                                                      _eliminarUsuario(user.id),
                                                  tooltip:
                                                      'Eliminar del Sistema',
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
