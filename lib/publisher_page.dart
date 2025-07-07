import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFiles != null && pickedFiles.length <= 5) {
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
    if (_formKey.currentState!.validate()) {
      if (fotosBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes agregar al menos una foto.')),
        );
        return;
      }

      try {
        final lat = double.tryParse(latController.text) ?? 0.0;
        final lng = double.tryParse(lngController.text) ?? 0.0;
        final ubicacion = GeoPoint(lat, lng);

        final urls = await _subirImagenesASupabase();

        await FirebaseFirestore.instance.collection('turismo').add({
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lugar turístico guardado exitosamente.'),
          ),
        );

        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
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
      appBar: AppBar(title: const Text('Crear Lugar Turístico')),
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
                      final nombre = data['nombre'] ?? '';
                      final descripcion = data['descripcion'] ?? '';
                      final ciudad = data['ciudad'] ?? '';
                      final provincia = data['provincia'] ?? '';
                      final fotos = List<String>.from(
                        data['fotografias'] ?? [],
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Ubicación: $ciudad, $provincia'),
                              const SizedBox(height: 4),
                              Text(descripcion),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: fotos.map((url) {
                                  return Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  );
                                }).toList(),
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
}
