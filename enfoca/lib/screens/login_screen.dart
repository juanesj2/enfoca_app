import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// LoginScreen es un StatefulWidget porque necesita mantener "estado" (memoria).
class LoginScreen extends StatefulWidget {
  // Constante para la ruta de navegacion
  static const routeName = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ********** Variables de Estado ********** //
  final _formKey = GlobalKey<FormState>(); // Clave para validar el formulario

  // Controladores de texto para leer los inputs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isLoading = false; // Controla el spinner de carga
  // ********** FIN Variables de Estado ********** //

  // ********** Logica de Login ********** //
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
          title: Text('Error'),
          // Limpiamos el mensaje de excepcion para que sea mas amigable
          content: Text(error.toString().replaceAll('Exception: ', '')),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
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
  // ********** FIN Logica de Login ********** //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // El cuerpo se extiende detras del AppBar
      backgroundColor: Colors.transparent,

      appBar: AppBar(title: Text('Login')),

      // ********** Cuerpo del Formulario ********** //
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
                key: _formKey, // Conectamos la validacion
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Ocupa solo el espacio necesario
                  children: [
                    // ********** Logo ********** //
                    Image.network(
                      'https://raw.githubusercontent.com/juanesj2/Enfoca_ProyectoFinal/refs/heads/main/public/imagenes/logo_ENFOKA-sin-fondo.png',
                      height: 250,
                    ),
                    SizedBox(height: 20),

                    // ********** Input Email ********** //
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null; // Null significa "sin error"
                      },
                    ),

                    // ********** Input Contraseña ********** //
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Contraseña'),
                      obscureText: true, // Oculta el texto
                      validator: (value) {
                        if (value!.isEmpty || value.length < 5) {
                          return 'Contraseña muy corta';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // ********** Botón de Acción ********** //
                    if (_isLoading)
                      CircularProgressIndicator()
                    else
                      ElevatedButton(
                        child: Text('Entrar'),
                        onPressed: _iniciarSesion,
                      ),

                    // ********** Enlace a Registro ********** //
                    SizedBox(height: 10),
                    TextButton(
                      child: Text('¿No tienes cuenta? Regístrate'),
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
      // ********** FIN Cuerpo ********** //
    );
  }
}
