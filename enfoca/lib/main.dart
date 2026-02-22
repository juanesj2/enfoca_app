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

// ==========================================
// PUNTO DE ENTRADA (ENTRY POINT)
// ==========================================

// Aquí estamos iniciando la app. Mediante el método runApp estamos corriendo la clase MyApp
void main() {
  runApp(const MyApp());
}

// ==========================================
// CLASE PRINCIPAL (MAIN CLASS)
// ==========================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ==========================================
  // CONSTRUCCIÓN DE LA UI (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ==========================================
      // PROVIDERS (GESTOR DE ESTADO)
      // ==========================================

      // Estos son los providers, un provider es un contenedor de datos que estará disponible
      // para toda la app.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PhotoService()),
        ChangeNotifierProvider(create: (_) => GrupoService()),
        ChangeNotifierProvider(create: (_) => DesafioService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      // Hacemos que el child consuma el servicio de autenticación
      child: Consumer<AuthService>(
        builder: (ctx, auth, _) => Consumer<ThemeService>(
          builder: (ctx, themeService, _) => MaterialApp(
            // Título de la aplicación
            title: 'App Enfoca',

            // ==========================================
            // TEMA (THEME) - CLARO Y OSCURO
            // ==========================================
            // Aquí configuramos cómo se ven ambos temas en toda la app.

            // 1. Tema Claro: Colores predeterminados basados en morado.
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),

            // 2. Tema Oscuro: Mismos colores base pero adaptados a fondos negros/grises oscuros para no dañar la vista.
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),

            // 3. Selección de Tema: Usamos la variable del themeService.
            // Esto le dice a Flutter exactamente qué tema usar en tiempo real (Claro u Oscuro).
            themeMode: themeService.themeMode,

            // ==========================================
            // ENRUTAMIENTO (ROUTING)
            // ==========================================

            // Si estamos autenticados, iríamos a HomeScreen
            // Por ahora, si no estamos autenticados, vamos al Login
            home: auth.estaAutenticado ? HomeScreen() : LoginScreen(),

            // Rutas nombradas para navegación
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
