import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/desafio_service.dart';

// ==========================================
// SALÓN DE LA FAMA: PANTALLA DE LOGROS
// ==========================================
// Esta pantalla muestra todos los desafíos disponibles en la aplicación.
// Compara la lista total con los logros que el usuario ya ha desbloqueado,
// iluminando los conseguidos y ensombreciendo los pendientes.

class LogrosScreen extends StatefulWidget {
  const LogrosScreen({Key? key}) : super(key: key);

  @override
  _LogrosScreenState createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  // ==========================================
  // ESTADO INTERNO
  // ==========================================
  bool _isLoading = true; // Rueda de carga inicial

  // ==========================================
  // CICLO DE VIDA (MOTOR)
  // ==========================================
  @override
  void initState() {
    super.initState();
    // Nada más abrir la pantalla, pedimos los datos al servidor
    _cargarLogros();
  }

  // ==========================================
  // COMUNICACIÓN CON EL SERVIDOR
  // ==========================================
  Future<void> _cargarLogros() async {
    setState(() => _isLoading = true);
    try {
      // El "provider" hace la llamada mágica a Laravel a través de DesafioService
      // "cargarTodo()" descarga tanto el catálogo total como los del usuario actual.
      await Provider.of<DesafioService>(context, listen: false).cargarTodo();
    } catch (e) {
      if (mounted) {
        // Tolerancia a fallos: Si internet se corta, avisamos con un banner inferior
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    } finally {
      if (mounted) {
        // Pase lo que pase, apagamos la rueda de carga
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // DISEÑO VISUAL (BUILD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Nos suscribimos a los datos del servicio de desafíos
    final ds = Provider.of<DesafioService>(context);

    // 1. Catálogo completo de logros posibles en el juego
    final todos = ds.todosLosDesafios;

    // 2. Extraemos ÚNICAMENTE las IDs de los logros que el usuario YA TIENE.
    // Usamos ".toSet()" para hacer búsquedas súper rápidas luego.
    final conseguidosId = ds.misDesafios.map((e) => e.id).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Logros'),
        backgroundColor: Colors.tealAccent.shade700, // Verde trofeo
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // Si el usuario arrastra hacia abajo, vuelve a forzar la descarga de datos
              onRefresh: _cargarLogros,
              child: todos.isEmpty
                  ? Center(
                      // PANTALLA VACÍA: Si no hay logros programados en la BD
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No hay logros disponibles.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Vuelve a cargar o comprueba el servidor.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _cargarLogros,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recargar'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      // MATRIZ DE DE TROFEOS (2 columnas)
                      padding: const EdgeInsets.all(15),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 trofeos por cada fila
                            crossAxisSpacing:
                                15, // Espacio horizontal entre columnas
                            mainAxisSpacing: 15, // Espacio vertical entre filas
                            childAspectRatio:
                                0.85, // Proporción (Un poco más alto que ancho)
                          ),
                      itemCount:
                          todos.length, // Rellenar con todos los del sistema
                      itemBuilder: (ctx, i) {
                        final desafio =
                            todos[i]; // El trofeo que estamos pintando

                        // ¿Lo tiene el usuario? (Compara su ID contra la lista de conseguidos)
                        final bool completado = conseguidosId.contains(
                          desafio.id,
                        );

                        // ==========================================
                        // LÓGICA DE ICONOGRAFÍA DINÁMICA
                        // ==========================================
                        // Buscamos palabras clave en el título para ponerle un icono acorde.
                        IconData iconData =
                            Icons.emoji_events; // Copa por defecto
                        if (desafio.titulo.contains('Primer')) {
                          iconData = Icons.looks_one;
                        } else if (desafio.titulo.contains('Cinco')) {
                          iconData = Icons.looks_5;
                        } else if (desafio.titulo.contains('gusta')) {
                          iconData = Icons.favorite;
                        } else if (desafio.titulo.contains('Popular')) {
                          iconData = Icons.local_fire_department;
                        } else if (desafio.titulo.contains('Social')) {
                          iconData = Icons.forum;
                        } else if (desafio.titulo.contains('Colecc')) {
                          iconData = Icons.diamond;
                        }

                        // ==========================================
                        // CARTA INDIVIDUAL DEL TROFEO
                        // ==========================================
                        return Card(
                          // Sombra mayor si lo tienes, plano si está bloqueado
                          elevation: completado ? 4 : 1,

                          // Color vivo si lo tienes, gris pálido si está bloqueado
                          color: completado
                              ? Colors.tealAccent.shade100
                              : Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // EL ICONO DEL TROFEO
                                Icon(
                                  iconData,
                                  size: 48,
                                  color: completado
                                      ? Colors.teal.shade800
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),

                                // TÍTULO DEL LOGRO (Ej: "Primeros Pasos")
                                Text(
                                  desafio.titulo,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: completado
                                        ? Colors.teal.shade900
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // DESCRIPCIÓN EXPLICATIVA (Ej: "Sube tu primera foto")
                                // Expanded+Scroll para que no rompa el diseño si el texto es muy largo
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      desafio.descripcion,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: completado
                                            ? Colors.teal.shade800
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),

                                // ==========================================
                                // ETIQUETA INFERIOR DE ESTADO
                                // ==========================================
                                if (completado)
                                  // Cartel Mágico "Conseguido"
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.teal.shade800,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Conseguido',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  // Candado Frío "Bloqueado"
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock,
                                          size: 16,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Bloqueado',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
