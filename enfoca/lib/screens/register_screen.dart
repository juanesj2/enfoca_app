import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ********** Variables de Estado ********** //
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  var _isLoading = false;
  // ********** FIN Variables de Estado ********** //

  // ********** Logica de Registro ********** //
  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Llamada al servicio para registrar
      await Provider.of<AuthService>(context, listen: false).registrarse(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
      );
      // Si va bien, volvemos atras (o al home)
      Navigator.of(context).pop();
    } catch (error) {
      // Manejo de errores
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Ocurrió un error'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
  // ********** FIN Logica de Registro ********** //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ********** Nombre ********** //
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),

                // ********** Email ********** //
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty || !value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),

                // ********** Contraseña ********** //
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),

                // ********** Confirmar Contraseña ********** //
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // ********** Botón de Registro ********** //
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    child: Text('Registrarse'),
                    onPressed: _registrarse,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
