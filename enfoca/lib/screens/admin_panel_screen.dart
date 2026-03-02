import 'package:flutter/material.dart';
import 'admin/users_control_screen.dart';
import 'admin/photos_control_screen.dart';
import 'admin/reports_control_screen.dart';

// Pantalla del panel de administración
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _AdminCard(
              icon: Icons.group,
              title: 'Control de Usuarios',
              description:
                  'Gestiona todos los usuarios. Visualiza, edita o elimínalos.',
              buttonText: 'IR A USUARIOS',
              buttonColor: Colors.blueAccent,
              iconColor: Colors.blueAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UsersControlScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            _AdminCard(
              icon: Icons.camera_alt,
              title: 'Control de Fotografías',
              description:
                  'Gestiona las fotografías subidas. Ve, edita o elimina fotos.',
              buttonText: 'IR A FOTOGRAFÍAS',
              buttonColor: Colors.amber,
              iconColor: Colors.amber,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhotosControlScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            _AdminCard(
              icon: Icons.flag_rounded,
              title: 'Control de Reportes',
              description: 'Revisar los reportes de contenido.',
              buttonText: 'IR A REPORTES',
              buttonColor: const Color.fromARGB(255, 255, 0, 0),
              iconColor: const Color.fromARGB(255, 255, 7, 7),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsControlScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final Color buttonColor;
  final Color iconColor;
  final VoidCallback onPressed;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.buttonColor,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Icon(icon, size: 60, color: iconColor),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
