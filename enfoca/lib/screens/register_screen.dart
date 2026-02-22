import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// ==========================================
// PANTALLA DE REGISTRO
// ==========================================

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ==========================================
  // ESTADO (STATE)
  // ==========================================
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  var _isLoading = false;

  // ==========================================
  // LÓGICA DE NEGOCIO
  // ==========================================

  Future<void> _registrarse() async {
    // 1. Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Activar carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Llamada al servicio para registrar
      await Provider.of<AuthService>(context, listen: false).registrarse(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
      );
      // 4. Si va bien, volvemos atrás (o al home si la navegación así lo gestiona)
      Navigator.of(context).pop();
    } catch (error) {
      // 5. Manejo de errores
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ocurrió un error'),
          content: Text(
            error
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('Exception', ''),
          ),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }

    // 6. Desactivar carga (si hubo error, si hubo éxito ya navegamos fuera)
    if (mounted) {
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
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ==========================================
                // CAMPO NOMBRE
                // ==========================================
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),

                // ==========================================
                // CAMPO EMAIL
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
                    return null;
                  },
                ),

                // ==========================================
                // CAMPO CONTRASEÑA
                // ==========================================
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),

                // ==========================================
                // CAMPO CONFIRMAR CONTRASEÑA
                // ==========================================
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
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
                const SizedBox(height: 20),

                // ==========================================
                // BOTÓN DE REGISTRO
                // ==========================================
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _registrarse,
                    child: const Text('Registrarse'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
