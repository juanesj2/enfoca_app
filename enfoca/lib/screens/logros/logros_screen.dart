import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/desafio_service.dart';

// Pantalla para mostrar los logros y desafíos del usuario
class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarLogros();
  }

  Future<void> _cargarLogros() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<DesafioService>(context, listen: false).cargarTodo();
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

  @override
  Widget build(BuildContext context) {
    final ds = Provider.of<DesafioService>(context);
    final todos = ds.todosLosDesafios;
    final conseguidosId = ds.misDesafios.map((e) => e.id).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Logros'),
        backgroundColor: Colors.tealAccent.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarLogros,
              child: todos.isEmpty
                  ? Center(
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
                            'Vuelve a intentarlo más tarde.',
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
                      padding: const EdgeInsets.all(15),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: todos.length,
                      itemBuilder: (ctx, i) {
                        final desafio = todos[i];
                        final bool completado = conseguidosId.contains(
                          desafio.id,
                        );

                        IconData iconData = Icons.emoji_events;
                        if (desafio.titulo.contains('Primer')) {
                          iconData = Icons.looks_one;
                        } else if (desafio.titulo.contains('Cinco')) {
                          iconData = Icons.looks_5;
                        } else if (desafio.titulo.toLowerCase().contains(
                          'gusta',
                        )) {
                          iconData = Icons.favorite;
                        } else if (desafio.titulo.toLowerCase().contains(
                          'popular',
                        )) {
                          iconData = Icons.local_fire_department;
                        } else if (desafio.titulo.toLowerCase().contains(
                          'social',
                        )) {
                          iconData = Icons.forum;
                        } else if (desafio.titulo.toLowerCase().contains(
                          'colecc',
                        )) {
                          iconData = Icons.diamond;
                        }

                        return Card(
                          elevation: completado ? 4 : 1,
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
                                Icon(
                                  iconData,
                                  size: 48,
                                  color: completado
                                      ? Colors.teal.shade800
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
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
                                if (completado)
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
