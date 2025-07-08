// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'publisher_page.dart';
import 'visitor_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jqoabinjonqgedgbrryi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impxb2FiaW5qb25xZ2VkZ2JycnlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NTkzNDAsImV4cCI6MjA2NDAzNTM0MH0.Ixtfn8U6F8gC-g5zS9w2V2tqvRZwrnojoJSLcG5P2LU',
  );
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBWJiYEAKabqS5IbNh2FQSdXAiqg48TO5k",
      authDomain: "flutter-firebase-2e515.firebaseapp.com",
      projectId: "flutter-firebase-2e515",
      storageBucket: "flutter-firebase-2e515.firebasestorage.app",
      messagingSenderId: "31816417250",
      appId: "1:31816417250:web:a37f2d45b25ae07ebfc3bb",
      measurementId: "G-JYG08PBL2Q",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '"El Búho" Turismo Ciudadano Ecuador',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> verificarYRedirigirSegunRol(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      final String role = data['role'];

      if (role == 'publicador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TurismosPage()),
        );
      } else if (role == 'visitante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LugaresVisitantePage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Rol desconocido: $role')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar perfil: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // Esperar al siguiente frame para redirigir correctamente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            verificarYRedirigirSegunRol(context);
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
