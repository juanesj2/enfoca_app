<div align="center">
  <img src="https://raw.githubusercontent.com/juanesj2/Enfoca_ProyectoFinal/refs/heads/main/public/imagenes/logo_ENFOKA-sin-fondo.png" alt="Enfoca Logo" width="200"/>
  <h1>📸 Enfoca App</h1>
  <p><em>Explora, captura y comparte tu mundo.</em></p>
</div>

---

## 🚀 Sobre el Proyecto

**Enfoca** es el cliente móvil oficial para la plataforma homónima, desarrollado como Trabajo de Fin de Grado (TFG) para el ciclo de Desarrollo de Aplicaciones Multiplataforma (DAM).

La aplicación se comunica de forma asíncrona con un **Backend robusto en Laravel**, el cual actúa como API REST centralizada para dar servicio simultáneo tanto a la versión web como a esta aplicación móvil.

## 🛠️ Stack Tecnológico

- **Frontend Móvil:** Flutter & Dart
- **Gestión de Estado:** Provider
- **Mapas y Geolocalización:** Flutter Map (OpenStreetMap)
- **Backend Core:** Laravel (PHP) + MySQL

## ✨ Características Principales

- 🗺️ **Mapeo Interactivo:** Geolocalización integrada para fijar exactamente dónde se capturó cada instante.
- 👥 **Sistema de Grupos:** Creación de comunidades privadas accesibles mediante códigos de invitación.
- 🏆 **Gamificación (Logros):** Sistema de recompensas y desafíos para incentivar la participación.
- 🛡️ **Administración:** Panel de control de roles (Admin/User), reportes y moderación (sistema de vetos).
- 🌓 **Diseño Adaptativo:** Temas claro y oscuro con una estética cuidada y natural.

## ⚙️ Despliegue Local (Getting Started)

Pasos básicos para levantar el cliente en un entorno de desarrollo:

1. Clona este repositorio en tu máquina local.
2. Asegúrate de tener instalado el **Flutter SDK** (junto con Android Studio o Xcode según tu SO).
3. Instala las dependencias necesarias:
   ```bash
   flutter pub get
   ```
4. Configura el endpoint del servidor. Verifica que las URLs en los archivos `_service.dart` apuntan a tu API de Laravel local o remota.
5. Lanza la aplicación en tu emulador o dispositivo físico:
   ```bash
   flutter run
   ```

## 📝 TODO

> Lista de tareas pendientes o en desarrollo activo:

- [ ] Añadir / Conectar las notificaciones push.
- [ ] Refactorizar el manejo de errores globales.
- [ ] Optimizar la carga de imágenes en el Feed.

---

<div align="center">
  <i>Desarrollado con pasión para el TFG de DAM.</i>
</div>
