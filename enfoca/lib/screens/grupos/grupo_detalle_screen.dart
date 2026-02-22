import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/grupo.dart';
import '../../services/grupo_service.dart';
import '../../services/auth_service.dart';

class GrupoDetalleScreen extends StatelessWidget {
  final Grupo grupo;

  const GrupoDetalleScreen({Key? key, required this.grupo}) : super(key: key);

  void _copiarCodigo(BuildContext context) {
    Clipboard.setData(ClipboardData(text: grupo.codigoInvitacion));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  Future<void> _salirOEliminarGrupo(
    BuildContext context,
    bool esCreador,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esCreador ? 'Eliminar Grupo' : 'Salir del Grupo'),
        content: Text(
          esCreador
              ? '¿Estás seguro de que deseas eliminar este grupo para todos?'
              : '¿Estás seguro de que deseas salir de este grupo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              esCreador ? 'Eliminar' : 'Salir',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      if (esCreador) {
        await Provider.of<GrupoService>(
          context,
          listen: false,
        ).borrarGrupo(grupo.id);
      } else {
        await Provider.of<GrupoService>(
          context,
          listen: false,
        ).salirGrupo(grupo.id);
      }
      if (context.mounted) {
        Navigator.of(context).pop(); // Volver a la lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esCreador ? 'Grupo eliminado' : 'Has salido del grupo',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final miUsuario = Provider.of<AuthService>(context, listen: false).usuario;
    final esCreadorOMiembroA =
        grupo.creadoPor == miUsuario?.id || miUsuario?.rol == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(grupo.nombre),
        actions: [
          IconButton(
            icon: Icon(
              esCreadorOMiembroA ? Icons.delete_forever : Icons.exit_to_app,
            ),
            color: Colors.redAccent,
            tooltip: esCreadorOMiembroA ? 'Eliminar grupo' : 'Salir del grupo',
            onPressed: () => _salirOEliminarGrupo(context, esCreadorOMiembroA),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SECCIÓN SUPERIOR: CÓDIGO E INFO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.teal.shade50,
              child: Column(
                children: [
                  if (grupo.descripcion != null &&
                      grupo.descripcion!.isNotEmpty) ...[
                    Text(
                      grupo.descripcion!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Código de Invitación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _copiarCodigo(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.teal),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            grupo.codigoInvitacion,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(Icons.copy, color: Colors.teal),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SECCIÓN INFERIOR: MIEMBROS
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Miembros (${grupo.usuarios.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  ...grupo.usuarios
                      .map(
                        (u) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            u.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(u.email),
                          trailing: u.id == grupo.creadoPor
                              ? const Chip(
                                  label: Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                  backgroundColor: Colors.teal,
                                  padding: EdgeInsets.zero,
                                )
                              : null,
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
