import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'resenas_page.dart';

class TurismosPage extends StatefulWidget {
  const TurismosPage({super.key});

  @override
  State<TurismosPage> createState() => _TurismosPageState();
}

class _TurismosPageState extends State<TurismosPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  final TextEditingController provinciaController = TextEditingController();
  final TextEditingController ciudadController = TextEditingController();

  final List<Uint8List> fotosBytes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final uuid = const Uuid();

  Future<void> _pickImages() async {
    final origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Seleccionar de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (origen == null) return;

    if (origen == ImageSource.camera) {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (fotosBytes.length < 5) {
            fotosBytes.add(bytes);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Máximo 5 imágenes permitidas.')),
            );
          }
        });
      }
    } else if (origen == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 100,
      );

      if (pickedFiles != null) {
        if (pickedFiles.length + fotosBytes.length <= 5) {
          for (var pickedFile in pickedFiles) {
            final bytes = await pickedFile.readAsBytes();
            setState(() {
              fotosBytes.add(bytes);
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Puedes subir entre 1 y 5 imágenes.')),
          );
        }
      }
    }
  }

  Future<List<String>> _subirImagenesASupabase() async {
    final storage = Supabase.instance.client.storage.from('turismo');
    final List<String> urls = [];

    for (var i = 0; i < fotosBytes.length; i++) {
      final String fileName = 'img_${uuid.v4()}.jpg';

      final String? path = await storage.uploadBinary(
        fileName,
        fotosBytes[i],
        fileOptions: const FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      if (path != null && path.isNotEmpty) {
        final publicUrl = storage.getPublicUrl(fileName);
        urls.add(publicUrl);
      } else {
        throw Exception(
          'Error al subir imagen: No se pudo obtener la ruta del archivo subido.',
        );
      }
    }

    return urls;
  }

  Future<void> _guardarTurismo() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios.'),
        ),
      );
      return;
    }

    if (fotosBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos una foto.')),
      );
      return;
    }

    final confirmado = await _confirmarGuardarLugar();
    if (!confirmado) return;

    // Mostrar spinner mientras se guarda
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final lat = double.tryParse(latController.text) ?? 0.0;
      final lng = double.tryParse(lngController.text) ?? 0.0;
      final ubicacion = GeoPoint(lat, lng);

      final urls = await _subirImagenesASupabase();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select('name, lastName')
          .eq('id', user.id)
          .single();

      final String autorNombre = '${data['name']} ${data['lastName']}';

      await FirebaseFirestore.instance.collection('turismo').add({
        'autor': autorNombre,
        'nombre': nombreController.text,
        'descripcion': descripcionController.text,
        'latitud': lat,
        'longitud': lng,
        'fotografias': urls,
        'provincia': provinciaController.text,
        'ciudad': ciudadController.text,
        'ubicacion': ubicacion,
        'fecha': Timestamp.now(),
      });

      Navigator.pop(context); // Cierra el spinner

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lugar turístico guardado exitosamente.')),
      );

      _clearForm();
    } catch (e) {
      Navigator.pop(context); // Cierra el spinner
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _clearForm() {
    nombreController.clear();
    descripcionController.clear();
    latController.clear();
    lngController.clear();
    provinciaController.clear();
    ciudadController.clear();
    setState(() {
      fotosBytes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 22, 36, 62),
        foregroundColor: Colors.white,
        title: const Text('Lugares Turístico'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(nombreController, 'Nombre del Lugar'),
              const SizedBox(height: 12),
              _buildTextField(
                descripcionController,
                'Descripción',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildTextField(latController, 'Latitud', isNumber: true),
              const SizedBox(height: 8),
              _buildTextField(lngController, 'Longitud', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(provinciaController, 'Provincia'),
              const SizedBox(height: 12),
              _buildTextField(ciudadController, 'Ciudad'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Seleccionar Fotografías'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: fotosBytes.map((bytes) {
                  return Image.memory(
                    bytes,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _guardarTurismo,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Lugar'),
              ),
              const Divider(height: 40),
              const Text(
                'Lugares turísticos guardados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('turismo')
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text(
                      'Aún no hay lugares turísticos registrados.',
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;

                      final nombre = data['nombre'] ?? '';
                      final descripcion = data['descripcion'] ?? '';
                      final ciudad = data['ciudad'] ?? '';
                      final provincia = data['provincia'] ?? '';
                      final autor = data['autor'] ?? 'Desconocido';
                      final latitud = data['latitud']?.toString() ?? '-';
                      final longitud = data['longitud']?.toString() ?? '-';
                      final fotos = List<String>.from(
                        data['fotografias'] ?? [],
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descripcion,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    const TextSpan(
                                      text: 'Provincia: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: provincia),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    const TextSpan(
                                      text: 'Ciudad: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ciudad),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    const TextSpan(
                                      text: 'Coordenadas: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: '$latitud°, $longitud°'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style
                                      .copyWith(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                  children: [
                                    const TextSpan(
                                      text: 'Publicado por: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: autor),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (fotos.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: fotos.map((url) {
                                    return GestureDetector(
                                      onTap: () =>
                                          _mostrarModalImagen(url, docId),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 8),
                              if (fotos.length < 5)
                                TextButton.icon(
                                  onPressed: () =>
                                      _agregarMasImagenes(docId, fotos.length),
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Agregar imagen'),
                                ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () => _editarLugar(docId, data),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Eliminar',
                                    onPressed: () =>
                                        _confirmarEliminarLugar(docId),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.reviews),
                                    tooltip: 'Ver reseñas',
                                    onPressed: () => _verResenas(docId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
    );
  }

  void _mostrarModalImagen(String url, String lugarId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.cover),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminarImagen(lugarId, url),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _actualizarImagen(lugarId, url),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmarGuardarLugar() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('¿Estás seguro?'),
            content: const Text('¿Deseas guardar este lugar turístico?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ) ??
        false; // En caso de que el diálogo se cierre sin elegir
  }

  void _confirmarEliminarLugar(String id) async {
    final confirmado = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await FirebaseFirestore.instance.collection('turismo').doc(id).delete();
    }
  }

  void _confirmarEliminarImagen(String lugarId, String url) async {
    final confirmado = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Imagen'),
        content: const Text('¿Deseas eliminar esta imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      // Mostrar spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final doc = FirebaseFirestore.instance
            .collection('turismo')
            .doc(lugarId);
        await doc.update({
          'fotografias': FieldValue.arrayRemove([url]),
        });

        Navigator.pop(context); // Cierra el spinner
        Navigator.pop(context); // Cierra el modal de imagen
      } catch (e) {
        Navigator.pop(context); // Cierra el spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la imagen: $e')),
        );
      }
    }
  }

  Future<void> _agregarMasImagenes(String lugarId, int cantidadActual) async {
    final ImageSource? origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Seleccionar de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (origen == null) return;

    final int cantidadDisponible = 5 - cantidadActual;
    final storage = Supabase.instance.client.storage.from('turismo');
    final nuevasUrls = <String>[];

    try {
      if (origen == ImageSource.camera) {
        final pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 100,
        );

        if (pickedFile != null) {
          if (cantidadDisponible < 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ya tienes 5 imágenes.')),
            );
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          final bytes = await pickedFile.readAsBytes();
          final fileName = 'img_${uuid.v4()}.jpg';
          final path = await storage.uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

          if (path != null && path.isNotEmpty) {
            final url = storage.getPublicUrl(fileName);
            nuevasUrls.add(url);
          }

          Navigator.pop(context);
        }
      } else if (origen == ImageSource.gallery) {
        final pickedFiles = await picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFiles == null || pickedFiles.isEmpty) return;

        if (pickedFiles.length > cantidadDisponible) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Solo puedes agregar $cantidadDisponible imágenes.',
              ),
            ),
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        for (var pickedFile in pickedFiles) {
          final bytes = await pickedFile.readAsBytes();
          final fileName = 'img_${uuid.v4()}.jpg';

          final path = await storage.uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

          if (path != null && path.isNotEmpty) {
            final url = storage.getPublicUrl(fileName);
            nuevasUrls.add(url);
          }
        }

        Navigator.pop(context);
      }

      if (nuevasUrls.isNotEmpty) {
        final doc = FirebaseFirestore.instance
            .collection('turismo')
            .doc(lugarId);
        await doc.update({'fotografias': FieldValue.arrayUnion(nuevasUrls)});
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imágenes: $e')));
    }
  }

  Future<void> _actualizarImagen(String lugarId, String urlAntiguo) async {
    final origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Seleccionar de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (origen == null) return;

    final pickedFile = await picker.pickImage(source: origen);
    if (pickedFile == null) return;

    // Mostrar spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final nuevoBytes = await pickedFile.readAsBytes();
      final storage = Supabase.instance.client.storage.from('turismo');
      final nuevoNombre = 'img_${uuid.v4()}.jpg';

      final nuevoPath = await storage.uploadBinary(
        nuevoNombre,
        nuevoBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      if (nuevoPath != null && nuevoPath.isNotEmpty) {
        final nuevaUrl = storage.getPublicUrl(nuevoNombre);
        final doc = FirebaseFirestore.instance
            .collection('turismo')
            .doc(lugarId);

        await doc.update({
          'fotografias': FieldValue.arrayRemove([urlAntiguo]),
        });

        await doc.update({
          'fotografias': FieldValue.arrayUnion([nuevaUrl]),
        });
      }

      Navigator.pop(context); // Cierra el spinner
      Navigator.pop(context); // Cierra el modal de imagen
    } catch (e) {
      Navigator.pop(context); // Cierra el spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la imagen: $e')),
      );
    }
  }

  void _editarLugar(String id, Map<String, dynamic> data) {
    final nombreCtrl = TextEditingController(text: data['nombre']);
    final descripcionCtrl = TextEditingController(text: data['descripcion']);
    final latCtrl = TextEditingController(text: data['latitud'].toString());
    final lngCtrl = TextEditingController(text: data['longitud'].toString());
    final provinciaCtrl = TextEditingController(text: data['provincia']);
    final ciudadCtrl = TextEditingController(text: data['ciudad']);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Lugar'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nombreCtrl, 'Nombre del Lugar'),
                const SizedBox(height: 8),
                _buildTextField(descripcionCtrl, 'Descripción', maxLines: 2),
                const SizedBox(height: 8),
                _buildTextField(latCtrl, 'Latitud', isNumber: true),
                const SizedBox(height: 8),
                _buildTextField(lngCtrl, 'Longitud', isNumber: true),
                const SizedBox(height: 8),
                _buildTextField(provinciaCtrl, 'Provincia'),
                const SizedBox(height: 8),
                _buildTextField(ciudadCtrl, 'Ciudad'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final isValid = formKey.currentState!.validate();

              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa todos los campos.'),
                  ),
                );
                return;
              }

              final confirmado = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('¿Confirmar actualización?'),
                  content: const Text(
                    '¿Estás seguro de actualizar este lugar turístico?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sí, actualizar'),
                    ),
                  ],
                ),
              );

              if (confirmado == true) {
                // Mostrar spinner mientras se actualiza
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await FirebaseFirestore.instance
                      .collection('turismo')
                      .doc(id)
                      .update({
                        'nombre': nombreCtrl.text,
                        'descripcion': descripcionCtrl.text,
                        'latitud': double.tryParse(latCtrl.text) ?? 0,
                        'longitud': double.tryParse(lngCtrl.text) ?? 0,
                        'provincia': provinciaCtrl.text,
                        'ciudad': ciudadCtrl.text,
                      });

                  Navigator.pop(context); // Cierra spinner
                  Navigator.pop(context); // Cierra modal de edición

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lugar actualizado exitosamente.'),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Cierra spinner
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e')),
                  );
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _verResenas(String lugarId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    final String rol = data['role'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResenasPage(
          lugarId: lugarId,
          rolUsuario: rol, // 'publicador' o 'visitante'
        ),
      ),
    );
  }
}
