# 📍 Turismo El Búho - App Móvil Flutter

**Turismo El Búho** es una aplicación móvil construida en Flutter que promueve el turismo ciudadano en Ecuador, permitiendo registrar, visualizar y reseñar lugares turísticos a través de un sistema de microblog.

## 🚀 Tecnologías usadas

- Flutter (SDK de interfaz multiplataforma)
- Supabase (Autenticación, base de datos, almacenamiento)
- Firebase (Analytics y notificaciones futuras)
- Dart (lenguaje principal de desarrollo)

## 👥 Perfiles de Usuario

### Visitante
- Ver todos los lugares turísticos
- Leer reseñas de otros usuarios

### Publicador
- Crear nuevos lugares turísticos
- Subir hasta 5 imágenes por lugar
- Editar y eliminar sus publicaciones
- Responder reseñas

## 🧩 Funcionalidades

- **Autenticación con Supabase:** Registro, login, verificación por correo
- **Deep linking:** Redirección automática desde enlaces de verificación
- **CRUD completo** para sitios turísticos
- **Gestión de imágenes:** Subida a Supabase Storage y visualización modal
- **Sistema de reseñas:** Comentarios y respuestas por lugar
- **Interfaz adaptable:** Diseño con Material UI personalizado

## 📸 Capturas de pantalla

![IMG-20250724-WA0006](https://github.com/user-attachments/assets/b7bad50b-dc55-482d-97c4-b964bcdd2392)
![IMG-20250724-WA0005](https://github.com/user-attachments/assets/2cf8e35b-efad-4cae-9ece-dc88b606e774)
![IMG-20250724-WA0014](https://github.com/user-attachments/assets/2696e9e5-6400-46ad-883a-184ccc9a2f08)
![IMG-20250724-WA0013](https://github.com/user-attachments/assets/41d2cdf7-e278-4ae5-a74b-a61fa337de36)
![IMG-20250724-WA0012](https://github.com/user-attachments/assets/ff4e410e-a7dc-425c-815e-1e83cc734008)
![IMG-20250724-WA0011](https://github.com/user-attachments/assets/9ee0e431-44c6-436c-922a-0e5ee4dd6dd0)
![IMG-20250724-WA0010](https://github.com/user-attachments/assets/76c5c3ec-1405-4e21-b33a-f99011dd44f3)
![IMG-20250724-WA0009](https://github.com/user-attachments/assets/39ad8ab5-165c-4d29-ba22-ad31f07887c4)
![IMG-20250724-WA0008](https://github.com/user-attachments/assets/2f3018ae-6843-4719-9e18-f3a80a48db03)
![IMG-20250724-WA0007](https://github.com/user-attachments/assets/cd2f1140-aed2-4072-a8b1-5666a0e07260)


## 🔐 Seguridad y control

- Roles gestionados directamente desde Supabase (publicador / visitante)
- Acceso restringido a funcionalidades según el tipo de cuenta
- Validaciones de campos y carga segura de imágenes

## 📦 Cómo compilar el APK

```bash
flutter build apk --release
