import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class ResenasPage extends StatelessWidget {
  final String lugarId;
  final TextEditingController comentarioController = TextEditingController();
  final String autor = 'Usuario demo'; // Puedes usar el usuario autenticado

  ResenasPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) {
    final resenasRef = FirebaseFirestore.instance
        .collection('turismo')
        .doc(lugarId)
        .collection('reseñas');

    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas del lugar')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: resenasRef.orderBy('fecha', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final resenas = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: resenas.length,
                  itemBuilder: (context, index) {
                    final resena = resenas[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(resena['comentario']),
                      subtitle: Text('${resena['autor']} - ${DateFormat('dd/MM/yyyy').format((resena['fecha'] as Timestamp).toDate())}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: comentarioController,
                    decoration: const InputDecoration(labelText: 'Escribe una reseña'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (comentarioController.text.trim().isEmpty) return;
                    await resenasRef.add({
                      'comentario': comentarioController.text.trim(),
                      'autor': autor,
                      'fecha': Timestamp.now(),
                    });
                    comentarioController.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
