import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResenasPage extends StatefulWidget {
  final String lugarId;
  final String rolUsuario; // 'publicador' o 'visitante'

  const ResenasPage({
    super.key,
    required this.lugarId,
    required this.rolUsuario,
  });

  @override
  State<ResenasPage> createState() => _ResenasPageState();
}

class _ResenasPageState extends State<ResenasPage> {
  final TextEditingController resenaCtrl = TextEditingController();

  Future<String> obtenerAutor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Desconocido';
    final data = await Supabase.instance.client
        .from('users')
        .select('name, lastName')
        .eq('id', user.id)
        .single();
    return '${data['name']} ${data['lastName']}';
  }

  Future<void> publicarResena() async {
    final texto = resenaCtrl.text.trim();
    if (texto.isEmpty) return;
    final autor = await obtenerAutor();

    await FirebaseFirestore.instance
        .collection('turismo')
        .doc(widget.lugarId)
        .collection('resenas')
        .add({'contenido': texto, 'autor': autor, 'fecha': Timestamp.now()});

    resenaCtrl.clear();
  }

  Future<void> actualizarResena(String resenaId, String contenidoActual) async {
    final TextEditingController updateCtrl = TextEditingController(
      text: contenidoActual,
    );

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar reseña'),
        content: TextField(
          controller: updateCtrl,
          decoration: const InputDecoration(hintText: 'Edita tu reseña'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (confirmado != true || updateCtrl.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('turismo')
        .doc(widget.lugarId)
        .collection('resenas')
        .doc(resenaId)
        .update({'contenido': updateCtrl.text.trim()});
  }

  Future<void> eliminarResena(String resenaId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar reseña'),
        content: const Text('¿Estás seguro de eliminar esta reseña?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    await FirebaseFirestore.instance
        .collection('turismo')
        .doc(widget.lugarId)
        .collection('resenas')
        .doc(resenaId)
        .delete();
  }

  Future<void> responderResena(String resenaId) async {
    final TextEditingController respuestaCtrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Responder reseña'),
        content: TextField(
          controller: respuestaCtrl,
          decoration: const InputDecoration(hintText: 'Escribe tu respuesta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Responder'),
          ),
        ],
      ),
    );

    if (confirmado != true || respuestaCtrl.text.trim().isEmpty) return;
    final autor = await obtenerAutor();

    await FirebaseFirestore.instance
        .collection('turismo')
        .doc(widget.lugarId)
        .collection('resenas')
        .doc(resenaId)
        .collection('respuestas')
        .add({
          'contenido': respuestaCtrl.text.trim(),
          'autor': autor,
          'fecha': Timestamp.now(),
        });
  }

  Widget _buildRespuesta(DocumentSnapshot respuesta) {
    final data = respuesta.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: ListTile(
        title: Text(
          data['autor'] ?? 'Desconocido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(data['contenido'] ?? ''),
        trailing: Text(
          (data['fecha'] as Timestamp).toDate().toString().substring(0, 16),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildResena(DocumentSnapshot resena) {
    final data = resena.data() as Map<String, dynamic>;
    final resenaId = resena.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea superior: autor + fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['autor'] ?? 'Desconocido',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  (data['fecha'] as Timestamp).toDate().toString().substring(
                    0,
                    16,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contenido de la reseña
            Text(data['contenido'] ?? '', style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 12),

            // Acciones del publicador
            if (widget.rolUsuario == 'publicador')
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => responderResena(resenaId),
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Responder'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Editar',
                    onPressed: () =>
                        actualizarResena(resenaId, data['contenido'] ?? ''),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'Eliminar',
                    onPressed: () => eliminarResena(resenaId),
                  ),
                ],
              ),

            // Respuestas
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('turismo')
                  .doc(widget.lugarId)
                  .collection('resenas')
                  .doc(resenaId)
                  .collection('respuestas')
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return Column(
                  children: snapshot.data!.docs.map(_buildRespuesta).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas del lugar')),
      body: Column(
        children: [
          if (widget.rolUsuario == 'publicador')
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: resenaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Escribe una reseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: publicarResena,
                    child: const Text('Publicar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('turismo')
                  .doc(widget.lugarId)
                  .collection('resenas')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final resenas = snapshot.data!.docs;

                if (resenas.isEmpty) {
                  return const Center(child: Text('Aún no hay reseñas.'));
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: resenas.map(_buildResena).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
