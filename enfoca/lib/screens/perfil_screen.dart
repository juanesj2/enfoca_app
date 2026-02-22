import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin_panel_screen.dart'; // Importamos la nueva pantalla
import 'grupos/mis_grupos_screen.dart'; // Importamos la pantalla de grupos
import 'logros/logros_screen.dart'; // Pantalla de logros

// ==========================================
// PANTALLA DE PERFIL DE USUARIO
// ==========================================

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario del AuthService
    // listen: true es el valor por defecto, así que se redibujará si cambia el usuario
    final user = Provider.of<AuthService>(context).usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: user == null
          ? const Center(
              child: Text('No se ha encontrado información del usuario.'),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // ==========================================
                          // AVATAR DE USUARIO
                          // ==========================================
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ==========================================
                          // TARJETA DE INFORMACIÓN
                          // ==========================================
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  // Nombre
                                  ListTile(
                                    leading: const Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                    ),
                                    title: const Text('Nombre'),
                                    subtitle: Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  // Email
                                  ListTile(
                                    leading: const Icon(
                                      Icons.email,
                                      color: Colors.blue,
                                    ),
                                    title: const Text('Correo Electrónico'),
                                    subtitle: Text(
                                      user.email,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ==========================================
                          // SECCIÓN DE LOGROS (DESAFÍOS)
                          // ==========================================
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.emoji_events,
                                        color: Colors.amber,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Mis Logros',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  if (user.desafios.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20.0,
                                      ),
                                      child: Text(
                                        'Aún no has desbloqueado ningún logro.\n¡Sigue usando la app para conseguirlos!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: user.desafios.map((desafio) {
                                        IconData iconData = Icons.star;
                                        Color iconColor = Colors.orange;

                                        // Asignar íconos basados en el título
                                        if (desafio.titulo.contains('Primer'))
                                          iconData = Icons.looks_one;
                                        else if (desafio.titulo.contains(
                                          'Cinco',
                                        ))
                                          iconData = Icons.looks_5;
                                        else if (desafio.titulo.contains(
                                          'gusta',
                                        )) {
                                          iconData = Icons.favorite;
                                          iconColor = Colors.red;
                                        } else if (desafio.titulo.contains(
                                          'Popular',
                                        )) {
                                          iconData =
                                              Icons.local_fire_department;
                                          iconColor = Colors.deepOrange;
                                        } else if (desafio.titulo.contains(
                                          'Social',
                                        )) {
                                          iconData = Icons.forum;
                                          iconColor = Colors.blue;
                                        } else if (desafio.titulo.contains(
                                          'Colecc',
                                        ))
                                          iconData = Icons.diamond;

                                        return Tooltip(
                                          message: desafio.descripcion,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          showDuration: const Duration(
                                            seconds: 3,
                                          ),
                                          child: Chip(
                                            elevation: 2,
                                            backgroundColor: Colors.white,
                                            avatar: Icon(
                                              iconData,
                                              color: iconColor,
                                            ),
                                            label: Text(
                                              desafio.titulo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                // ==========================================
                // MENÚ DESPLEGABLE DE OPCIONES
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.settings,
                          color: Colors.blueGrey,
                        ),
                        title: const Text(
                          'Opciones de Mi Cuenta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        children: [
                          // Botón Panel de Administración (Solo visible para admins)
                          if (user.rol == 'admin') ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text(
                                  'Panel de administración',
                                  style: TextStyle(fontSize: 18),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminPanelScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                          // Botón Mis Grupos
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.group),
                              label: const Text(
                                'Mis Grupos',
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MisGruposScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Botón Mis Logros
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.emoji_events),
                              label: const Text(
                                'Mis Logros',
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LogrosScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Botón de Cerrar Sesión
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.logout),
                              label: const Text(
                                'Cerrar Sesión',
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed: () {
                                Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                ).cerrarSesion();
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
