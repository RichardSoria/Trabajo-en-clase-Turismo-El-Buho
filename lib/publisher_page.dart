import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'resenas_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TurismosPage extends StatefulWidget {
  const TurismosPage({super.key});

  @override
  State<TurismosPage> createState() => _TurismosPageState();
}

class _TurismosPageState extends State<TurismosPage> {
  final turismosRef = FirebaseFirestore.instance.collection('turismo');
  final picker = ImagePicker();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController fotoController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _pickImage(bool fromCamera) async {
    final XFile? image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final file = File(image.path);
      final fileSize = await file.length();

      if (fileSize > 2 * 1024 * 1024) {
        _showSnackBar('La imagen excede los 2MB');
        return;
      }

      final ref = FirebaseStorage.instance.ref().child(
        'turismo/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() {
        fotoController.text = url;
      });
    }
  }

  Future<void> _guardarTurismo() async {
    if (_formKey.currentState!.validate()) {
      try {
        final lat = double.tryParse(latController.text) ?? 0.0;
        final lng = double.tryParse(lngController.text) ?? 0.0;
        final ubicacion = GeoPoint(lat, lng);
        final user = Supabase.instance.client.auth.currentUser;

        if (user == null) {
          _showSnackBar('Usuario no autenticado');
          return;
        }

        try {
          final data = await Supabase.instance.client
              .from('users')
              .select(
                'name, lastName',
              )
              .eq('id', user.id)
              .single();

          final String name = '${data['name'] ?? ''} ${data['lastName'] ?? ''}';

          await turismosRef.add({
            'nombre': nombreController.text,
            'descripcion': descripcionController.text,
            'foto': fotoController.text,
            'ubicacion': ubicacion,
            'autor': name,
            'fecha': Timestamp.now(),
          });
        } catch (e) {
          _showSnackBar('Error al obtener el nombre del usuario: $e');
          return;
        }

        _clearForm();
        _showSnackBar('Turismo guardado correctamente');
      } catch (e) {
        _showSnackBar('Error al guardar: $e');
      }
    }
  }

  void _clearForm() {
    nombreController.clear();
    descripcionController.clear();
    fotoController.clear();
    latController.clear();
    lngController.clear();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _verResenas(String turismoId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResenasPage(lugarId: turismoId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turismo Ciudadano')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(nombreController, 'Nombre'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    descripcionController,
                    'Descripción',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          latController,
                          'Latitud',
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          lngController,
                          'Longitud',
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cámara'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.image),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _guardarTurismo,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar lugar'),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            StreamBuilder<QuerySnapshot>(
              stream: turismosRef
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fecha = (data['fecha'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(data['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.comment),
                          onPressed: () => _verResenas(doc.id),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
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
