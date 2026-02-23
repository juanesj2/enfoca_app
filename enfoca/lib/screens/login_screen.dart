import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// ==========================================
// PANTALLA DE INICIO DE SESIÓN (LOGIN)
// ==========================================
// Esta es la primera barrera de entrada a la aplicación.
// Recoge un Email y una Contraseña, y los envía al AuthService para conseguir un Token.

class LoginScreen extends StatefulWidget {
  // Constante para la ruta de navegación nombrada en main.dart
  static const routeName = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================
  // ESTADO Y CONTROLADORES (STATE)
  // ==========================================

  // Llave Maestra del Formulario. Nos permite acceder desde el código
  // al estado colectivo de todas las cajas de texto y disparar sus validaciones.
  final _formKey = GlobalKey<FormState>();

  // Tubos de conexión: Leen y escriben en tiempo real lo que el usuario teclea
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Bandera de carga: Cambia a 'true' cuando estamos esperando respuesta de Internet,
  // y hace que el botón de Login desaparezca y muestre un Spinner giratorio.
  var _isLoading = false;

  // ==========================================
  // LÓGICA DE NEGOCIO (EVENTOS)
  // ==========================================

  // Disparado al pulsar el botón "Entrar"
  Future<void> _iniciarSesion() async {
    // 1. Validamos el formulario completo.
    // Esto ejecuta la función 'validator' de cada TextFormField.
    // Si alguno falla (ej: password muy corta o email sin arroba), esto devuelve false.
    if (!_formKey.currentState!.validate()) {
      return; // Cortocircuito: No hacemos la petición a Internet si los datos están mal.
    }

    // 2. Activamos la Animación de Carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Llamada Asíncrona al puente de red (AuthService)
      // listen: false es obligatorio cuando llamamos a funciones del Provider
      // fuera de un método Build (estamos dentro de un callback de botón).
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).iniciarSesion(_emailController.text, _passwordController.text);

      // Si todo fue bien (Status 200 OK de Laravel):
      // No necesitamos hacer Navigator.push(), ya que el `main.dart`
      // está escuchando (Consumer) los cambios del AuthService y al detectar
      // que ahora el token existe, redibujará la app mostrándonos el HomeScreen de golpe.
    } catch (error) {
      // 4. Fallo Categórico (Ej: Contraseña mala o Servidor caído)
      // Mostramos un Cuadro de Diálogo Flotante (Popup)
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Credenciales Rechazadas'),
          // Limpiamos la basura del mensaje de Dart para que se lea como humano:
          content: Text(
            error
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('Exception', ''),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Destruye el Popup flotante
              },
            ),
          ],
        ),
      );
    }

    // 5. Pase lo que pase, si llegamos aquí (normalmente por error),
    // desactivamos el Spinner de carga para dejar al usuario re-intentarlo.
    // Nota: Si fue éxito rotundo, este código ni se ve porque el Navigator cambia de pantalla.
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Prevención de Fugas de Memoria (Memory Leaks)
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD (CONSTRUCCIÓN DEL ÁRBOL VISUAL)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Truco de UI: Hace que el gradiente/fondo invada el espacio de la barra superior
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(title: const Text('Iniciar Sesión')),

      // ==========================================
      // CUERPO CENTRAL (Center widget lo centra en X e Y)
      // ==========================================
      body: Center(
        child: SingleChildScrollView(
          // Permite hacer scroll si sale el teclado nativo del móvil y tapa la pantalla
          child: Card(
            margin: const EdgeInsets.all(24.0),
            elevation: 8, // Da un efecto de levitación material design
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),

              // ==========================================
              // INICIO DEL FORMULARIO
              // ==========================================
              child: Form(
                key: _formKey, // Enlazamos el estado con la UI
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Se encoge a su contenido, no abarca todo el alto
                  children: [
                    // --- LOGO SUPERIOR ---
                    Image.network(
                      'https://raw.githubusercontent.com/juanesj2/Enfoca_ProyectoFinal/refs/heads/main/public/imagenes/logo_ENFOKA-sin-fondo.png',
                      height: 250,
                      // Fallback si GitHub se cae o no hay Wifi:
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100),
                    ),
                    const SizedBox(height: 20),

                    // --- INPUT EMAIL ---
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                      ),
                      keyboardType: TextInputType
                          .emailAddress, // Muestra el teclado con la @ rápido en el móvil
                      // Regla de Negocio
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Email no válido, debe contener @';
                        }
                        return null; // Null en Dart = OK, Validado
                      },
                    ),

                    // --- INPUT CONTRASEÑA ---
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      obscureText: true, // Pone asteriscos/puntos *****
                      validator: (value) {
                        if (value!.isEmpty || value.length < 5) {
                          return 'Tu contraseña debe medir al menos 5 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- MODO MULTIVERSO: SPINNER VS BOTÓN ---
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _iniciarSesion,
                        child: const Text('Entrar'),
                      ),

                    // --- BOTÓN SECUNDARIO (TEXTBUTTON) ---
                    const SizedBox(height: 10),
                    TextButton(
                      child: const Text('¿No tienes cuenta? Únete a Enfoca'),
                      onPressed: () {
                        // Empuja (Push) una nueva pantalla al historial de navegación.
                        // Arriba a la izquierda aparecerá la clásica flechita 'Back' para volver aquí.
                        Navigator.of(context).pushNamed('/register');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
