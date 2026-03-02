import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/photo_service.dart';
import 'services/grupo_service.dart';
import 'services/desafio_service.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';

// Inicio de la aplicación
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Configuración de los providers para la gestión del estado
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PhotoService()),
        ChangeNotifierProvider(create: (_) => GrupoService()),
        ChangeNotifierProvider(create: (_) => DesafioService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<AuthService>(
        builder: (ctx, auth, _) => Consumer<ThemeService>(
          builder: (ctx, themeService, _) => MaterialApp(
            title: 'App Enfoca',

            // Configuración del tema claro
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),

            // Configuración del tema oscuro
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),

            // Usamos el modo de tema guardado en el servicio
            themeMode: themeService.themeMode,

            // Navegación: si está logueado va a Home, si no a Login
            home: auth.estaAutenticado ? HomeScreen() : LoginScreen(),

            // Rutas principales
            routes: {
              LoginScreen.routeName: (ctx) => LoginScreen(),
              RegisterScreen.routeName: (ctx) => RegisterScreen(),
            },
          ),
        ),
      ),
    );
  }
}
