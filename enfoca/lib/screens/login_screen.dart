import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// Pantalla de inicio de sesión.

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isLoading = false;

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).iniciarSesion(_emailController.text, _passwordController.text);
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Credenciales Rechazadas'),
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
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(title: const Text('Iniciar Sesión')),

      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24.0),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),

              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://raw.githubusercontent.com/juanesj2/Enfoca_ProyectoFinal/refs/heads/main/public/imagenes/logo_ENFOKA-sin-fondo.png',
                      height: 250,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Email no válido, debe contener @';
                        }
                        return null;
                      },
                    ),

                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty || value.length < 5) {
                          return 'Tu contraseña debe medir al menos 5 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _iniciarSesion,
                        child: const Text('Entrar'),
                      ),

                    const SizedBox(height: 10),
                    TextButton(
                      child: const Text('¿No tienes cuenta? Únete a Enfoca'),
                      onPressed: () {
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
