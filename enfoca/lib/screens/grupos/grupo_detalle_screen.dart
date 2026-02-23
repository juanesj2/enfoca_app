import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/grupo.dart';
import '../../services/grupo_service.dart';
import '../../services/auth_service.dart';

// ==========================================
// CUARTEL GENERAL: DETALLES DEL GRUPO
// ==========================================
// Esta pantalla disecciona la anatomía de un solo grupo.
// Muestra el código de invitación (para que la gente se una),
// la descripción oficial, y el censo completo de miembros actuales.

class GrupoDetalleScreen extends StatelessWidget {
  final Grupo grupo; // Recibimos el grupo entero por parámetro (Constructor)

  const GrupoDetalleScreen({Key? key, required this.grupo}) : super(key: key);

  // ==========================================
  // UTILIDAD: BOTÓN DE COPIADO
  // ==========================================
  // Copia el texto al portapapeles invisible del sistema operativo del móvil
  // para que el usuario pueda ir a WhatsApp y darle a "Pegar".
  void _copiarCodigo(BuildContext context) {
    Clipboard.setData(ClipboardData(text: grupo.codigoInvitacion));

    // Mostramos un mensajito temporal abajo para confirmar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles. ¡Pégalo en WhatsApp!'),
      ),
    );
  }

  // ==========================================
  // ACCIÓN DESTORA: BORRAR O ABANDONAR
  // ==========================================
  Future<void> _salirOEliminarGrupo(
    BuildContext context,
    bool esCreador, // Determina si destruye la alianza entera o solo deserta
  ) async {
    // 1. Desplegamos Popup de Advertencia
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          esCreador ? 'Disolver Grupo Oficial' : 'Desertar del Grupo',
        ),
        content: Text(
          esCreador
              ? '¿Estás completamente seguro de disolver este grupo? Desaparecerá para todos los miembros.'
              : '¿Deseas renunciar a tu asiento en esta asociación ciudadana?',
        ),
        actions: [
          // Botón Vida
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          // Botón Muerte
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              esCreador ? 'Eliminar Definitivamente' : 'Abandonar Nave',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // ¿El tribunal falló en contra? Abortamos misión.
    if (confirmar != true) return;

    try {
      // 2. Ejecutar la acción contra la Base de Datos
      if (esCreador) {
        // La bomba nuclear que disuelve la alianza
        await Provider.of<GrupoService>(
          context,
          listen: false,
        ).borrarGrupo(grupo.id);
      } else {
        // La puerta pequeña por la que te vas sigilosamente
        await Provider.of<GrupoService>(
          context,
          listen: false,
        ).salirGrupo(grupo.id);
      }

      if (context.mounted) {
        // En ambos casos, regresamos a la pantalla anterior (Mis Grupos)
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esCreador
                  ? 'Asociación disuelta.'
                  : 'Has abandonado la asociación.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fallo en la burocracia: $e')));
      }
    }
  }

  // ==========================================
  // DISEÑO VISUAL Y ENSAMBLAJE (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Escaneamos quién es el usuario que está usando el teléfono AHORA MISMO
    final miUsuario = Provider.of<AuthService>(context, listen: false).usuario;

    // REGLA DE PRIVILEGIOS:
    // Eres dios (Puedes borrar el grupo entero) SI:
    // 1. Eres el Presidente Original (Tu ID coincide con la del creador)
    // 2. Eres un Administrador Global de la App (Rol 'admin')
    final esCreadorOMiembroA =
        grupo.creadoPor == miUsuario?.id || miUsuario?.rol == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(grupo.nombre),
        actions: [
          // Botón Superior Derecho Peligroso (Basura Roja) o Salida (Puerta)
          IconButton(
            icon: Icon(
              esCreadorOMiembroA ? Icons.delete_forever : Icons.exit_to_app,
            ),
            color: Colors.redAccent,
            tooltip: esCreadorOMiembroA ? 'Eliminar alianza' : 'Desertar',
            onPressed: () => _salirOEliminarGrupo(context, esCreadorOMiembroA),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // SECCIÓN SUPERIOR: IDENTIDAD Y CÓDIGO CAJA FUERTE
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.teal.shade50, // Fondo suave para destacar
              child: Column(
                children: [
                  // -- 1. DECLARACIÓN DE INTENCIONES (Descripción) --
                  // Solo se dibuja si el grupo tiene alguna y no está vacía
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

                  // -- 2. EL PASE DORADO (Código) --
                  const Text(
                    'Llave de Acceso',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 'GestureDetector' hace que toda la caja blanca sea un botón invisible
                  // que dispara la acción de Copiar.
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
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Esquinas redondeadas
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                          ), // Sombra ligera
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize
                            .min, // Que la caja no se estire más de lo necesario
                        children: [
                          Text(
                            grupo.codigoInvitacion,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing:
                                  2, // Separa los caracteres para mejor lectura
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(
                            Icons.copy,
                            color: Colors.teal,
                          ), // Icono Papeles
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // SECCIÓN INFERIOR: CENSO DE COMPAÑEROS
            // ==========================================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- TÍTULO DEL CENSO (Miembros Totales) --
                  Text(
                    'Legionario/as (${grupo.usuarios.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(), // Raya separadora gris
                  // -- GENERADOR DE FILAS (Mapeo) --
                  // Recorremos la lista de usuarios del propio objeto Grupo
                  // Los tres puntos (...) "desempaquetan" la lista final en el padre (Column).
                  ...grupo.usuarios
                      .map(
                        (u) => ListTile(
                          contentPadding: EdgeInsets.zero,

                          // Avatar de contacto genérico por cada ciudadano
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

                          // -- ETIQUETADOR DE CORONAS --
                          // Si es el Presi, se le pinta la placa de Sheriff
                          trailing: u.id == grupo.creadoPor
                              ? const Chip(
                                  label: Text(
                                    'Presidente', // Placa
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                  backgroundColor: Colors.teal,
                                  padding: EdgeInsets.zero,
                                )
                              : null, // Si es un pringado, nada.
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
