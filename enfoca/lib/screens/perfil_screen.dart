import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin_panel_screen.dart'; // Importamos la nueva pantalla
import 'grupos/mis_grupos_screen.dart'; // Importamos la pantalla de grupos
import 'logros/logros_screen.dart'; // Pantalla de logros

// ==========================================
// PANTALLA DE PERFIL Y AJUSTES DE CUENTA
// ==========================================
// Esta pantalla es puramente de lectura (StatelessWidget) ya que no manipula
// flujos de texto asíncronos en vivo como los de Login. Su estado depende enteramente
// del Provider global ('AuthService'). Si el usuario en el Provider cambia, este Widget
// se destruye y se reconstruye mágicamente él solo con los datos nuevos.

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // EXTRACCIÓN DE DATOS REACTIVOS
    // ==========================================
    // Provider.of(context) por defecto tiene "listen: true".
    // Esto significa que suscribimos esta pantalla al AuthService. Si el usuario
    // edita su perfil remotamente, o cierra sesión, este Widget entero vuelve a ejecutar su build().
    final user = Provider.of<AuthService>(context).usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil y Logros')),

      // Control de Fallos Mínimo: ¿Qué pasa si intentamos pintar la pantalla en los
      // 0.2 milisegundos que el token se ha borrado pero el Navigator no ha saltado al Login?
      body: user == null
          ? const Center(
              child: Text('Datos de sesión evanescentes. Recargando...'),
            )
          : Column(
              children: [
                Expanded(
                  // SingleChildScrollView evita que la pantalla explote (RenderFlex Overflow)
                  // si el móvil es muy pequeño y el contenido no cabe de alto.
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Todo centradito
                        children: [
                          const SizedBox(height: 20),

                          // ==========================================
                          // 1. AVATAR CIRCULAR (FOTO DE PERFIL / INICIAL)
                          // ==========================================
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              // Truco para sacar la primera letra del nombre y pasarla a Mayúscula.
                              // Ternario "? :" por si milagrosamente el nombre viene vacío (fallback a '?')
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
                          // 2. DNI / FICHA POLICIAL TÉCNICA (Tarjeta)
                          // ==========================================
                          Card(
                            elevation: 4, // Efecto Sombra (Z-Index alto)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  // ListTile es un Widget prefabricado por Google IDEAL para listas de ajustes.
                                  // Tiene "leading" (izquierda), "title" (arriba) y "subtitle" (abajo).
                                  ListTile(
                                    leading: const Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                    ),
                                    title: const Text('Identidad'),
                                    subtitle: Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Divider(), // Raya fina separadora semitransparente
                                  ListTile(
                                    leading: const Icon(
                                      Icons.email,
                                      color: Colors.blue,
                                    ),
                                    title: const Text('Correo Institucional'),
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
                          // 3. EXPOSITOR DE GALARDONES (LOGROS)
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
                                        'Palmarés Fotográfico',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),

                                  // --- CONDICIÓN TERNARIA MULTIPLE ---
                                  // ¿Tiene logros? Pinto las fichas. ¿No tiene? Pinto texto de ánimo.
                                  if (user.desafios.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20.0,
                                      ),
                                      child: Text(
                                        'Aún eres un fotógrafo novato.\n¡Levántate y sal ahí fuera a capturar el mundo!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    // Wrap es un Widget mágico: Coloca elementos en fila (Row) y cuando
                                    // ya no caben a lo ancho, hace un "retorno de carro" a la fila de abajo.
                                    Wrap(
                                      spacing:
                                          10, // Hueco Horizontal entre iconos
                                      runSpacing:
                                          10, // Hueco Vertical entre filas
                                      // Recorremos la lista de logros del usuario convirtiendo cada JSON
                                      // en un elemento visual (Chip/Botón inerte).
                                      children: user.desafios.map((desafio) {
                                        IconData iconData = Icons.star;
                                        Color iconColor = Colors.orange;

                                        // ==========================================
                                        // HEURÍSTICA DE ASIGNACIÓN DE ICONOS A CIEGAS
                                        // ==========================================
                                        // Como la base de datos de Laravel no manda qué icono debe tener,
                                        // leemos la palabra clave del título para pintar un dibujo chulo u otro.
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
                                          message: desafio
                                              .descripcion, // Sale flotando si dejas el dedo pulsado
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          showDuration: const Duration(
                                            seconds: 3,
                                          ),
                                          // Un Chip (píldora ovalada visual)
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
                // 4. PANCOPANEL INFERIOR ROTORIZADO (Menú Desplegable)
                // ==========================================
                // Lo dejamos fuera del "Expanded" principal arriba para que se ancle al final del viewport
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
                      // Truco: Quitamos las antiestéticas rayas divisorias default del ExpansionTile
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),

                      // ExpansionTile es un cajón que se abre ("Acordeón") al tocarlo
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.settings,
                          color: Colors.blueGrey,
                        ),
                        title: const Text(
                          'Sala de Máquinas',
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
                          // ==========================================
                          // 4.1 BOTÓN PRIVILEGIADO (SOLO ADMINISTRADORES)
                          // ==========================================
                          // Los 3 Puntos (...) despliegan la lista dentro de otra lista
                          if (user.rol == 'admin') ...[
                            SizedBox(
                              width:
                                  double.infinity, // Ancho 100% de lado a lado
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
                                  'Cerebro Matriz (Panel de Admin)',
                                  style: TextStyle(fontSize: 18),
                                ),
                                onPressed: () {
                                  // Empuja el Panel Admin encima en la pila
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

                          // ==========================================
                          // 4.2 BOTÓN REDUNDANTE GRUPOS (YA ACCESIBLE)
                          // ==========================================
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
                                'Explorar Círculos (Grupos)',
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

                          // ==========================================
                          // 4.3 BOTÓN DETALLES LOGROS
                          // ==========================================
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
                                'Salón de la Fama (Logros Detalle)',
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

                          // ==========================================
                          // 4.4 BOTÓN DESTRUXIVO (CERRAR SESIÓN / LOGOUT)
                          // ==========================================
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
                                'Huida de Emergencia (Cerrar Sesión)',
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed: () {
                                // Llamar al servicio y aniquilar el Token de memoria y disco (SharedPreferences).
                                // Automáticamente el 'main.dart' lo detectará gracias al notifyListeners()
                                // y expulsará al usuario a la Login Screen sin ningún Navigator manual aquí.
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
