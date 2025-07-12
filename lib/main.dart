import 'package:flutter/material.dart';
import 'package:mi_supabase_flutter/tabs/publicador_tabs.dart';
import 'package:mi_supabase_flutter/tabs/visitante_tabs.dart';
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
      storageBucket: "flutter-firebase-2e515.appspot.com",
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
      debugShowCheckedModeBanner: false,
      title: 'El Búho Turismo',
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _verificarYRedirigir();
      }
    });
  }

  void _checkSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _verificarYRedirigir();
    } else {
      setState(() => _checkingSession = false);
    }
  }

  Future<void> _verificarYRedirigir() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    final String role = data?['role'] ?? '';
    if (role == 'publicador') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PublicadorTabs()),
        (route) => false,
      );
    } else if (role == 'visitante') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VisitanteTabs()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol desconocido o no asignado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _checkingSession
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : const LoginPage();
  }
}
