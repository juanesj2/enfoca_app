import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/photo_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';

// Aqui estamos iniciando la app, Mediante el metodo runApp estamos corriendo la clase MyApp
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Estos son los providers, un provider es un contenedor de datos que estara disponible
      // para toda la app
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PhotoService()),
      ],
      // Hacemos que el child consuma el servicio de autenticacion
      child: Consumer<AuthService>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Enfoca App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          // Si estamos autenticados, iríamos a HomeScreen
          // Por ahora, si no estamos autenticados, vamos al Login
          home: auth.isAuth ? HomeScreen() : LoginScreen(),
          routes: {
            LoginScreen.routeName: (ctx) => LoginScreen(),
            RegisterScreen.routeName: (ctx) => RegisterScreen(),
          },
        ),
      ),
    );
  }
}
