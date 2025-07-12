import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class VisitorProfilePage extends StatefulWidget {
  const VisitorProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _VisitorProfilePageState();
}




class _VisitorProfilePageState extends State<VisitorProfilePage> {

  late TextEditingController emailController;
  late TextEditingController nombreController;
  late TextEditingController apellidoController;
  late TextEditingController rolController;
  
  bool _datosCargados = false;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController();
    nombreController = TextEditingController();
    apellidoController = TextEditingController();
    rolController = TextEditingController();

    _getProfileData();
  }

  final supabase = Supabase.instance.client;

  void _getProfileData() async {
    try
    {
      final userId = supabase.auth.currentSession?.user.id;

      if (userId == null) return;

      final List<dynamic> response = await supabase
        .from("users")
        .select('*')
        .eq('id', userId)
        .limit(1);

      if (response.isNotEmpty)
      {
        final user = response.first;

        setState(() {
          emailController.text = user['email'] ?? '';
          nombreController.text = user['name'] ?? '';
          apellidoController.text = user['lastName'] ?? '';
          rolController.text = user['role'] ?? '';
          _datosCargados = true;
        });
      }

      
    }
    catch(e)
    {
      throw("Error al obtener los datos del perfil");
    }
  }

  String capitalizarPrimeraLetra(String valor)
  {
    if (valor.isEmpty) return "";
    var dato = valor[0].toUpperCase() + valor.substring(1).toLowerCase();
    return dato.trim();
  }

  Future<void> updateUsersData() async {
    try
    {
      final nombre = capitalizarPrimeraLetra(nombreController.text);
      final apellido = capitalizarPrimeraLetra(apellidoController.text);

      if (nombre == "" || apellido == "")
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Debe enviar su apellido y nombre"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await supabase
        .from("users")
        .update({
          'name': nombre,
          'lastName': apellido
        })
        .eq('id', '${supabase.auth.currentUser?.id}');
      

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sus datos se actualizaron exitosamente"),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }
    catch(e)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al actualizar sus datos ${e}"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  @override
  void dispose() {
    emailController.dispose();
    nombreController.dispose();
    apellidoController.dispose();
    rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if (!_datosCargados)
    {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 254, 247, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 225, 31, 28),
        title: const Text("Perfil de visitante"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted)
              {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            }
          )
        ],
      ),

      body:
        Padding(
          padding: EdgeInsetsGeometry.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      "Email", 
                      style: TextStyle()
                    ),
                  ),
                  TextField(
                    controller: emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.transparent)
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Color.fromARGB(255, 152, 183, 223), width: 2)
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                      )


                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 15),
                    child: Text("Rol")
                  ),
                  TextField(
                    controller: rolController,
                    readOnly: true,
                    decoration: InputDecoration(
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.transparent)
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Color.fromARGB(255, 152, 183, 223), width: 2)
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                      )
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 15),
                    child: Text("Nombre")
                  ),
                  TextField(
                    controller: nombreController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                    ],
                    decoration: InputDecoration(
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.transparent)
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Color.fromARGB(255, 152, 183, 223), width: 2)
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                      )
                    ),

                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 15),
                    child: Text("Apellido")
                  ),
                  TextField(
                    controller: apellidoController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                    ],
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.transparent)
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Color.fromARGB(255, 152, 183, 223), width: 2)
                      ),

                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(25)
                      )

                    ),

                  )
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children:[
                    ElevatedButton(
                      onPressed: () {updateUsersData();},
                      style:ButtonStyle(),
                      child: Text("Actualizar datos")
                    ),
                  ]
                )
              )
            ],
          ),
        )
    );
  }
}