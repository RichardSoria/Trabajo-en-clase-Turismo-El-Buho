import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mi_supabase_flutter/tabs/publicador_tabs.dart';
import 'package:mi_supabase_flutter/tabs/visitante_tabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _obscurePassword = true;
  bool _cargando = false;


  void _showSnackBar(String message, {bool error = false}) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Correo y contraseña obligatorios.', error: true);
      return;
    }

    setState(() => _cargando = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // Obtener el rol directamente
        final data = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single();

        final String role = data['role'];

        

        // Redirigir según el rol
        if (!mounted) return;

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
          _showSnackBar('Rol desconocido: $role', error: true);
        }
      } else {
        _showSnackBar('Credenciales incorrectas.', error: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', error: true);
    } finally {

      //Salía error, porque el navigator ejecutado en el try elimina el contexto, y al hacerlo
      //se elimina el estado de esta página. Por lo que, al intentar setear algo que no existe
      //salía error.
      //setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.grey[100],
      /*appBar: AppBar(
        title: const Text('El Búho - Iniciar Sesión'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),*/
      body: Stack(
        children: [
          Positioned.fill(
            
            child: Container(color: Color.fromARGB(255, 152, 183, 223)),
            //child: Container(color: Color.fromARGB(255, 22, 36, 62)),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.40,
              child: Image.asset(
                //"assets/images/always-grey.png",
                "assets/images/arabesque.png",

                fit: BoxFit.none,
                repeat: ImageRepeat.repeat,
                ),
            ),
          ),
          /*
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 200,
              height: 200,
              color: Colors.white,
              child: SvgPicture.asset("assets/images/logoApp.svg"),
            ),
          ),*/
          
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.person, size: 80, color:Color.fromARGB(255, 73, 69, 79),),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          cursorColor: Colors.black,
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            labelText: 'Contraseña',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _cargando
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                onPressed: login,
                                icon: const Icon(Icons.login),
                                label: const Text('Iniciar sesión'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(255, 225, 31, 28),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const SignUpPage()),
                            );
                          },
                          child: const Text(
                            '¿No tienes cuenta? Regístrate aquí',
                            style: TextStyle(
                              color: Color.fromARGB(255, 225, 31, 28)
                            ),
                            ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ]
      )
    );
  }
}
