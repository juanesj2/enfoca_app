import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// ==========================================
// PANTALLA DE LOGIN
// ==========================================

class LoginScreen extends StatefulWidget {
  // Constante para la ruta de navegación
  static const routeName = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================
  // ESTADO (STATE)
  // ==========================================
  final _formKey = GlobalKey<FormState>(); // Clave para validar el formulario

  // Controladores de texto para leer los inputs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isLoading = false; // Controla el spinner de carga

  // ==========================================
  // LÓGICA DE NEGOCIO
  // ==========================================

  Future<void> _iniciarSesion() async {
    // 1. Validamos el formulario (revisa los validators de los TextFormFields)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Activamos el modo carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Llamamos al servicio de autenticación
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).iniciarSesion(_emailController.text, _passwordController.text);

      // Si el login es exitoso, main.dart detectará el cambio de estado
      // y nos llevará al Home automáticamente.
    } catch (error) {
      // 4. Si algo falla, mostramos una alerta
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          // Limpiamos el mensaje de excepción para que sea más amigable
          content: Text(
            error
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('Exception', ''),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Cerramos el diálogo
              },
            ),
          ],
        ),
      );
      // Desactivamos la carga para permitir reintentar
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // BUILD (CONSTRUCCIÓN DE LA UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // El cuerpo se extiende detrás del AppBar
      backgroundColor:
          Colors.transparent, // Opcional, si hubiera imagen de fondo

      appBar: AppBar(title: const Text('Iniciar Sesión')),

      // ==========================================
      // CUERPO DEL FORMULARIO
      // ==========================================
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24.0),
            elevation: 8, // Sombra
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey, // Conectamos la validación
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Ocupa solo el espacio necesario
                  children: [
                    // ==========================================
                    // LOGO
                    // ==========================================
                    Image.network(
                      'https://raw.githubusercontent.com/juanesj2/Enfoca_ProyectoFinal/refs/heads/main/public/imagenes/logo_ENFOKA-sin-fondo.png',
                      height: 250,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100),
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // INPUT EMAIL
                    // ==========================================
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null; // Null significa "sin error"
                      },
                    ),

                    // ==========================================
                    // INPUT CONTRASEÑA
                    // ==========================================
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      obscureText: true, // Oculta el texto
                      validator: (value) {
                        if (value!.isEmpty || value.length < 5) {
                          return 'Contraseña muy corta';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // BOTÓN DE ACCIÓN
                    // ==========================================
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _iniciarSesion,
                        child: const Text('Entrar'),
                      ),

                    // ==========================================
                    // ENLACE A REGISTRO
                    // ==========================================
                    const SizedBox(height: 10),
                    TextButton(
                      child: const Text('¿No tienes cuenta? Regístrate'),
                      onPressed: () {
                        // Navegamos a la pantalla de registro
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
