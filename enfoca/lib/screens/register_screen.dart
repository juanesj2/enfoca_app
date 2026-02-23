import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// ==========================================
// PANTALLA DE REGISTRO
// ==========================================
// Esta interfaz pide 4 campos básicos para registrar un nuevo integrante.
// Re-utiliza la arquitectura de Form y Validation vista en Login.

class RegisterScreen extends StatefulWidget {
  // Constante estática para registrar la ruta en la tabla de direcciones (main.dart)
  static const routeName = '/register';

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ==========================================
  // ESTADO INTERNO (STATE)
  // ==========================================

  // Clave Maestra Magnética: Permite controlar todos los Inputs del Form a la vez (Validar, Resetear...)
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto: Actúan como esponjas que absorben y guardan el texto que pulsa el usuario.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Flag de Carga para transicionar entre Botón <-> Spinner circular
  var _isLoading = false;

  // ==========================================
  // LÓGICA DE NEGOCIO (POST Request UI)
  // ==========================================

  Future<void> _registrarse() async {
    // 1. Efectuar el escáner de Validación en todos los Inputs.
    // Llama a todos los `validator: (value){ ... }` programados abajo en bloque.
    if (!_formKey.currentState!.validate()) {
      return; // Si uno solo se queja, paramos aquí en seco.
    }

    // 2. Transición Visual a "Cargando..."
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Exigir la inyección de la lógica subyacente de Registro (AuthService)
      await Provider.of<AuthService>(context, listen: false).registrarse(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
      );

      // 4. ÉXITO (Status 201 Created):
      // Si llegamos a esta línea significa que no devolvió error.
      // Así que matamos esta pantalla (Registro) desapilándola del Stack,
      // para devolver al usuario al Home de la App.
      Navigator.of(context).pop();
    } catch (error) {
      // 5. FRACASO: El servidor se queja (Ej: Email ya registrado)
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fallo en el Registro'),
          // Filtrado cosmético de errores de Dart
          content: Text(
            error
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('Exception', ''),
          ),
          actions: [
            TextButton(
              child: const Text('Corregir'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Destruye el popup
              },
            ),
          ],
        ),
      );
    }

    // 6. Finalmente, devolver la vida al Otón deshabilitando el Spinner
    // Comprobamos if (mounted) porque si el paso 4 fue un éxito, el widget ya fue destruido (pop)
    // y llamar a setState() daría un NullPointer Crash violento de renderizado.
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Prevenir que el móvil colapse guardando controladores fantasma en la memoria.
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD (REDIBUJADO DE LA INTERFAZ)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Únete a Enfoca')),
      // Padding lateral y superior
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        // --- COMIENZA EL FORMULARIO RECTANGULAR ---
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Permite desplazamiento vertical infinito si el móvil es corto
            child: Column(
              children: [
                // ==========================================
                // CAMPO NOMBRE COMPLETO
                // ==========================================
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tu Apodo o Nombre Completo',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor ingresa tu seña de identidad';
                    }
                    return null;
                  },
                ),

                // ==========================================
                // CAMPO EMAIL (Formato @ )
                // ==========================================
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Institucional o Personal',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty || !value.contains('@')) {
                      return 'La dirección huele a falsificada, añade arroba (@)';
                    }
                    return null;
                  },
                ),

                // ==========================================
                // CAMPO CONTRASEÑA
                // ==========================================
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña del Baúl',
                  ),
                  obscureText: true, // Asteriscos automáticos
                  validator: (value) {
                    // Laravel suele ser exigente validando 8 caracteres mínimos
                    if (value!.isEmpty || value.length < 8) {
                      return 'Para que sea robusta necesitas 8 cifras/letras, amigo.';
                    }
                    return null;
                  },
                ),

                // ==========================================
                // CAMPO CONFIRMAR CONTRASEÑA MÁGICA
                // ==========================================
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Repite la Contraseña Mágica',
                  ),
                  obscureText: true,
                  validator: (value) {
                    // Magia Cruzada: Comparamos este input con el input que hay arriba.
                    if (value != _passwordController.text) {
                      return 'No encajan las piezas, revisa tus teclas.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // ==========================================
                // BOTÓN DE DESPEGUE CENTRALIZADO
                // ==========================================
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _registrarse,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('¡Comenzar mi viaje fotográfico!'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
